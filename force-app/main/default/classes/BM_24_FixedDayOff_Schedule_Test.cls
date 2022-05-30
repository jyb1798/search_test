@isTest(SeeAllData = false)
private class BM_24_FixedDayOff_Schedule_Test{
    @isTest
    private static void TestBM_AddOPFT_ForNegative(){
        System.Test.startTest();

        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrews(1, 9);

        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();

        for (BM_FC_Mgmt__c fc : fcs){
            for (Integer i = 0; i <= 8; i++){
                BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
                newDPM.BM_DPM_FC__c = fc.Id;
                newDPM.BM_DPM_Date__c = (Date.newInstance(2023, 01, 01)).addDays(i);
                dpmListToInsert.add(newDPM);
            }

        }
        insert dpmListToInsert;


        //test the class with the available data

        Date startDate = Date.newInstance(2023, 01, 01);
        Date endDate = Date.newInstance(2023, 01, 08);

        BM_24_FixedDayOff_Schedule newBatch = new BM_24_FixedDayOff_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);

        System.Test.stopTest();
    }

    @isTest
    private static void TestBM_AddOPFT_WithoutCrews(){
        System.Test.startTest();
        Date startDate = Date.newInstance(2023, 01, 01);
		
        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrews3(1, 10);
		BM_CrewMgmt__c[] crews = [SELECT Id, Name FROM BM_CrewMgmt__c ];
        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();
        List<BM_HourlyProductivityManagement__c> hpmListToInsert = new List<BM_HourlyProductivityManagement__c>();

        for (BM_FC_Mgmt__c fc : fcs){
            Integer i = 0;
            for (BM_CrewMgmt__c crew : crews){
                i++;
                BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
                newDPM.BM_DPM_FC__c = fc.Id;
                newDPM.BM_DPM_Date__c = (Date.newInstance(2023, 01, 01)).addDays(i);
                dpmListToInsert.add(newDPM);
              
            }             
                
        }        
        insert dpmListToInsert;
        
        for(BM_DailyProductivityManagement__c dpm : dpmListToInsert){
            for(integer x = 0; x<11; x++){
                
                BM_HourlyProductivityManagement__c hpm = new BM_HourlyProductivityManagement__c();
                hpm.BM_HO_ProductivityManagement__c = dpm.id;
                
                hpmListToInsert.add(hpm);
            }	
            
        }
        insert hpmListToInsert;
        
        List<BM_CrewSchedule__c> CsToInsert = new List<BM_CrewSchedule__c>();
        
        for(BM_DailyProductivityManagement__c dpm2 : dpmListToInsert){
        	Integer i = 8;
            for(BM_CrewMgmt__c crew : crews){                      
                i--;
                
                BM_CrewSchedule__c cs = new BM_CrewSchedule__c();                    
                
                cs.BM_CS_Date__c = (Date.newInstance(2023, 01, 01)).addDays(-i);
                cs.BM_CS_Crew__c = crew.Id;
                
                CsToInsert.add(cs);                    
            }    
        }
        insert CsToInsert; 
        
        Date endDate = Date.newInstance(2023, 01, 08);

        BM_24_FixedDayOff_Schedule newBatch = new BM_24_FixedDayOff_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);

        System.Test.stopTest();
    }
    
}