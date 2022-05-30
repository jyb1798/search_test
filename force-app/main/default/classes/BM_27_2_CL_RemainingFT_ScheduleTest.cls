@isTest(SeeAllData = false)
private class BM_27_2_CL_RemainingFT_ScheduleTest {

   @isTest
    private static void generalCheck(){
        
        Test.startTest();

        Date startDate = Date.newInstance(2023, 01, 01);
        Date endDate = Date.newInstance(2023, 01, 08);
        
        List<BM_FC_Mgmt__c> fcs = new List<BM_FC_Mgmt__c>();
        for(Integer i = 0; i < 5; i++){
            BM_FC_Mgmt__c fc = new BM_FC_Mgmt__c();
            
            fc.Name = 'Test ' + i;
            fcs.add(fc);
        }
        insert fcs;
        
        List<BM_CrewMgmt__c> crews = new List<BM_CrewMgmt__c>();
        for(BM_FC_Mgmt__c crew : fcs){
            for(Integer i = 0; i < 5; i++){
                BM_CrewMgmt__c newCrew = new BM_CrewMgmt__c();
                newCrew.BM_FC_Name__c = crew.id;
                newCrew.Name = 'Name ' + i;
                newCrew.BM_WorkType__c = '일반 풀타임(40)';
                newCrew.RetiredDate__c = startDate.addYears(1);

				crews.add(newCrew);                
            }
            
        }
        insert crews;
          
        List<BM_DailyProductivityManagement__c> dpms = new List<BM_DailyProductivityManagement__c>();
        for(BM_FC_Mgmt__c dpm : fcs){
            for(Integer i = 0; i < 5; i++){
                BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
               	newDPM.BM_DPM_FC__c = dpm.id;
                newDPM.BM_DPM_Date__c = startDate.addDays(i);
                                
                dpms.add(newDPM);                
            }
        }
        insert dpms;
        
		List<BM_HourlyProductivityManagement__c> hpms = new List<BM_HourlyProductivityManagement__c>();
        for(BM_DailyProductivityManagement__c hpm : dpms){
            for(Integer i=6; i<15; i++){
                BM_HourlyProductivityManagement__c newHPM = new BM_HourlyProductivityManagement__c();
                
                newHPM.BM_HO_Slot__c = i;
                newHPM.BM_HO_ProductivityManagement__c = hpm.id;
                newHPM.ExtraOP_FT__c = 1;
                
                hpms.add(newHPM);
            }
        }
        insert hpms;
        
        List<BM_CrewSchedule__c> crewSchs = new List<BM_CrewSchedule__c>();
        for(Integer i=0; i<3; i++){
            BM_CrewSchedule__c cs = new BM_CrewSchedule__c();
            cs.BM_CS_Crew__c = crews[i].id;
            cs.BM_CS_Date__c = startDate.addDays(i);
            cs.Vacation__c = true;

            crewSchs.add(cs);
        }
        insert crewSchs;
        
    	BM_27_2_CL_RemainingFT_Schedule newBatch = new BM_27_2_CL_RemainingFT_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);
        
        Test.stopTest();

    }
     
}