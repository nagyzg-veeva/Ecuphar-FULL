public class VeevaJourneyUserExtension {
    public VeevaJourneyUserExtension() { }

    public VeevaJourneyUserExtension(ApexPages.StandardController stdController) { }

    public String getUserLanguage() {
        return UserInfo.getLanguage();
    }

    public String getUserLocale() {
        return UserInfo.getLocale();
    }

    public String getUserTimezone() {
        TimeZone tz = UserInfo.getTimeZone();
        if (tz != null) {
            return tz.getID();
        }
        return null;
    }
}