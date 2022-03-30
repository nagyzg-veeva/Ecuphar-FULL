@RestResource(urlMapping='/veeva/product-views/*')
global with sharing class VeevaProductViewRestController {

    private class InvalidArgumentException extends Exception {}

    private class ProductView {
        private String id;
        private String name;
        private String filterCriteria;

        private ProductView(Product_View_vod__c productView) {
            this.id = productView.Id;
            this.name = productView.Name;
            this.filterCriteria = productView.Filter_Criteria_vod__c;
        }
    }

    private class ProductViews {
        private final List<ProductView> productViews;

        private ProductViews(List<Product_View_vod__c> productViews) {
            this.productViews = new List<ProductView>();
            for (Product_View_vod__c productViewSObject : productViews) {
                this.productViews.add(new ProductView(productViewSObject));
            }
        }
    }

    private class Products {
        private final List<String> productIds;

        private Products(List<String> productIds) {
            this.productIds = productIds;
        }
    }

    private class ProductViewProductsBody {
        private List<String> productIds;
        private String accountId;
        private ProductViewProductsBody() {
            this.productIds = new List<String>();
            this.accountId = null;
        }

        private List<String> getProductIds() {
            return productIds;
        }

        private String getAccountId() {
            return accountId;
        }
    }

    // since Salesforce does not support Generics we need to make child class with data set as ProductViews
    global class ProductViewsResponse extends VeevaBaseResponse {
        private final ProductViews data;

        private ProductViewsResponse(List<Product_View_vod__c> productViews) {
            this.data = new ProductViews(productViews);
        }
    }

    // since Salesforce does not support Generics we need to make child class with data set as Products
    global class ProductsResponse extends VeevaBaseResponse {
        private final Products data;

        private ProductsResponse(List<String> productIds) {
            this.data = new Products(productIds);
        }
    }

    @HttpGet
    global static VeevaBaseResponse productViewsAccessibleToUser() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        VeevaBaseResponse productViewsResponse;
        Integer statusCode;
        List<String> uriParts = request.requestURI.split('/');
        if (uriParts.size() > 3) {
            // Expected GET request to only be /veeva/product-views
            // This means the url the request is looking for does not exist
            productViewsResponse = new VeevaBaseResponse('FAILURE', request.requestURI + ' not found');
            response.statusCode = 404;
        } else {
            List<Product_View_vod__c> productViews = getValidProductViewsForUser();
            productViewsResponse = new ProductViewsResponse(productViews);
            response.statusCode = 200;
        }

        return productViewsResponse;
    }

    /**
     * We have this as a POST request endpoint since the customer may have access to more than 100 products,
     * so we cannot make product ids a query string parameter.
     *
     * The reason the customer may send us the product ids is so that we don't search against every product
     * since the user may only need to see a subset for the View they are on.
     * For instance, it is possible that the Order Management View restricts the user to a subset of the
     * total products they have access to.
     */
    @HttpPost
    global static VeevaBaseResponse productViewProducts() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        VeevaBaseResponse productsResponse;
        try {
            Product_View_vod__c productView = getProductView(request);
            if (requestsProducts(request)) {
                List<String> productViewProducts = productViewProductsUsingRequest(productView, request);
                productsResponse = new ProductsResponse(productViewProducts);
            } else {
                productsResponse = new VeevaBaseResponse('FAILURE', request.requestURI + ' not found');
                response.statusCode = 404;
            }
        } catch (InvalidArgumentException ex) {
            productsResponse = new VeevaBaseResponse('FAILURE', ex.getMessage());
            response.statusCode = 400;
        } catch (VeevaProductViewFilterCriteria.InvalidSyntaxException ex) {
            productsResponse = new VeevaBaseResponse('FAILURE', ex.getMessage());
            response.statusCode = 500;
        }
        return productsResponse;
    }

    private static boolean requestsProducts(RestRequest request) {
        List<String> urlParts = request.requestURI.split('/');
        boolean uriRequestsProducts;
        if (urlParts.size() == 5) {
            // The requestURI must be /veeva/product-views/someProductViewId/products
            String finalPartOfUri = urlParts.get(4);
            uriRequestsProducts = 'products'.equalsIgnoreCase(finalPartOfUri);
        } else {
            uriRequestsProducts = false;
        }
        return uriRequestsProducts;
    }

    private static Product_View_vod__c getProductView(RestRequest request) {
        List<String> urlParts = request.requestURI.split('/');
        String productViewId = urlParts.get(3);
        try {
            Product_View_vod__c productView = [SELECT ID, Filter_Criteria_vod__c FROM Product_View_vod__c WHERE ID =: productViewId];
            return productView;
        } catch (QueryException ex) {
            throw new InvalidArgumentException('Product View Id provided is invalid');
        }
    }

    private static ProductViewProductsBody getProductIdsToFilterFrom(RestRequest request) {
        return (ProductViewProductsBody)Json.deserialize(request.requestBody.toString(), ProductViewProductsBody.class);
    }

    private static VeevaProductViewFilterCriteria createProductViewFilterCriteria(Product_View_vod__c productView) {
        VeevaSyntaxTokenizer tokenizer = new VeevaSyntaxTokenizer();
        VeevaCompositeConditionSyntaxParser compositeConditionSyntaxParser = VeevaSyntaxValidatorFactory.generateProductViewCompositeSyntaxParser();
        VeevaConditionTokenQueryBuilder queryBuilder = new VeevaConditionTokenQueryBuilder(
            Product_vod__c.getSObjectType(),
            new Map<Schema.SObjectType, Schema.SObjectField>{
                Product_Information_vod__c.getSObjectType() => Product_Information_vod__c.Product_vod__c
            },
            new Map<Schema.SObjectType, Schema.SObjectField>{
                Product_Information_vod__c.getSObjectType() => Product_Information_vod__c.Account_vod__c
            } 
        );
        return new VeevaProductViewFilterCriteria(productView, tokenizer, compositeConditionSyntaxParser, queryBuilder);
    }

    private static List<String> productViewProductsUsingRequest(Product_View_vod__c productView, RestRequest request) {
        ProductViewProductsBody productViewProductsBody = getProductIdsToFilterFrom(request);
        List<String> productIdsToFilterFrom = productViewProductsBody.getProductIds();
        String accountId = productViewProductsBody.getAccountId();
        /*
          Even though VeevaProductViewFilterCriteria and specifically VeevaConditionTokenQueryBuilder
          are capable of quering for every product that meets the Product View's Filter Criteria,
          we consider an empty list of product ids as an invalid bad request as a simple GET request
          can accomplish this.
         */
        if (productIdsToFilterFrom == null) {
            throw new InvalidArgumentException('Expected body to have productIds');
        } else if (productIdsToFilterFrom.size() == 0) {
            throw new InvalidArgumentException('productIds in body must not be empty');
        }

        VeevaProductViewFilterCriteria filterCriteria = createProductViewFilterCriteria(productView);
        List<String> filteredProductIds = filterCriteria.filterProductIds(productIdsToFilterFrom, accountId);
        return filteredProductIds;
    }

    private static List<Product_View_vod__c> getValidProductViewsForUser() {
        // This syntax validator is used when saving product views, so if the syntax is invalid that means that
        // the user cannot access something in the Filter Criteria.
        VeevaSyntaxValidator syntaxValidator = VeevaSyntaxValidatorFactory.generateProductViewSyntaxValidator();
        List<Product_View_vod__c> productViews = [SELECT Id, Name, Filter_Criteria_vod__c FROM Product_View_vod__c WHERE Active_vod__c = true];
        List<Product_View_vod__c> validProductViewsForUser = new List<Product_View_vod__c>();
        for (Product_View_vod__c productView : productViews) {
            // Checks to see if the filter criteria is valid for user since this Apex Rest Controller is "with sharing" and
            // the syntaxValidator is "inherited sharing". This means that if the filter criteria is invalid that means one
            // of the fields is not available to the user since the Product View should not have been inserted into
            // the database if the syntax was originally invalid.
            boolean isSyntaxValidForUser = syntaxValidator.isValid(productView.Filter_Criteria_vod__c);
            if (isSyntaxValidForUser) {
                validProductViewsForUser.add(productView);
            }
        }
        return validProductViewsForUser;
    }
}