
(function() {

    const setupVeevaCom = function() {
        var com = window.com = window.com || {};
        com.vod309 = com.vod309 || {};
        com.vod309.crm = com.vod309.crm || {};
        return com;
    }
    const addConfigToCom = function(config) {
        var com = setupVeevaCom()
        if(com.vod309.crm.config) {
            for(var k in config) {
                com.vod309.crm.config[k] = config[k];
            }
        }
        else {
            com.vod309.crm.config = config;
        }
    }

    var bootstrapVeevaApp = function() {
        
        var config = com.vod309.crm.config;
        
        var createElement = function(tagName, attributes) {
            var tag = document.createElement(tagName);
            var pathAttributes = ['src', 'href'];
            for(let attribute in attributes) {
                if(!!~pathAttributes.indexOf(attribute)) {
                    attributes[attribute] = config.url + attributes[attribute];
                }
                tag.setAttribute(attribute, attributes[attribute]);
            }
            return tag;
        }
        
        var createFrag = function(children, tagName) {
            var frag = document.createDocumentFragment();
            var child;
            while(child = children.pop()) {
                frag.appendChild(createElement(tagName, child));
            }
            return frag;
        }
        
        var head = document.querySelectorAll('head')[0];
        head.appendChild(createFrag(config.links, 'link'));
        head.appendChild(createFrag(config.scripts, 'script'));
    }
    
    var com = setupVeevaCom();
    com.vod309.crm.addConfigToCom = addConfigToCom;
    com.vod309.crm.bootstrapVeevaApp = bootstrapVeevaApp;
})();