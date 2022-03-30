public class TerritoryManagementFactory {
	private static TerritoryManagement tm;
	
    public static boolean isTM2() {
        Type territory2 = Type.forName('Territory2');
        if (territory2 != null) {
            SObject row = Database.query('Select Id from Territory2Model where State=\'Active\'');
            return row != null;
        }
        return false;
    }
    
    public static TerritoryManagement getInstance() {
    	if (tm == null) {
	        if(isTM2()) {
	        	tm = new TerritoryManagement2();
	        } else {
	        	tm = new TerritoryManagement1();
	        }
    	}
    	return tm;
    }
}