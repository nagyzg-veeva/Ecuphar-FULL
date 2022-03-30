public class VOD_WEC_CONTENT_WRAPPER {
    public String url{ get;set;}
    public Multichannel_Content_vod__c content{ get;set; }
    
    public VOD_WEC_CONTENT_WRAPPER(Multichannel_Content_vod__c content,String url)
    {
        this.content = content;
        this.url = url;
    }
}