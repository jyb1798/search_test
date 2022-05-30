@isTest
private class BM_23_WeekendFT_DayOff_Schedule_Test{
    @isTest
    private static void basicScenarioCheck(){

        System.Test.startTest();
        //Create Test Data 일자별 생산성관리 - BM_StockProductivity_Staging__c
        //입고 생산성 (Staging) 1st
        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrews(1, 5);

        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();
        for (BM_FC_Mgmt__c fc : fcs){
            BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
            newDPM.BM_DPM_FC__c = fc.Id;
            newDPM.BM_DPM_Date__c = Date.newInstance(2023, 01, 02);
            dpmListToInsert.add(newDPM);
        }
        insert dpmListToInsert;

        List<BM_HourlyProductivityManagement__c> hpmListToInsert = new List<BM_HourlyProductivityManagement__c>();
        for (BM_DailyProductivityManagement__c dpm : dpmListToInsert){

            BM_HourlyProductivityManagement__c hpm = new BM_HourlyProductivityManagement__c();
            hpm.BM_HO_ProductivityManagement__c = dpm.id;
            hpm.BM_HPM_StockIn__c = 100; //예상 입고량
            hpm.BM_HO_Slot__c= 15; //시간대
            hpm.BM_HO_Quantity__c = 100; //예상 주문수
            hpm.BM_HPM_RecommendedFTCalc__c = 5; //권장 풀타임 MH (산출용)           
            hpm.BM_HPM_RecommendedPT_Calc__c = 1.1; //권장 파트타임 MH (산출용)
            hpm.BM_HPM_StockPeopleNeeded__c = 2.2; //입고 필요 MH
            hpm.BM_HPM_PPAckingPeopleNeeded__c	= 2.2;//피패킹 필요 MH
            hpm.BreakTimeMH__c = 1.1; //오전 휴게 MH (1차)
            hpm.SupportMH__c = 1.1; //지원 MH (1차)
            
            hpmListToInsert.add(hpm);

        }
        insert hpmListToInsert;

        List<BM_CrewMgmt__c> crewListToInsert = new List<BM_CrewMgmt__c>();

        String worktype = '주말 풀타임(16)';
        
        for (BM_DailyProductivityManagement__c dpm : dpmListToInsert){
          
            BM_CrewMgmt__c crew = new BM_CrewMgmt__c();
            // 소속 FC
            crew.BM_FC_Name__c = dpm.BM_DPM_FC__c;
            // 크루 이름
            crew.Name = '신호연';
            // 근무 타입
            crew.BM_WorkType__c = worktype;
            // 사번
            crew.BM_EmpNo__c = '12332341';
            
        }

        insert crewListToInsert;

        //test the class with the available data

        Date startDate = Date.newInstance(2023, 01, 02);
        Date endDate = Date.newInstance(2023, 01, 02);

        BM_23_WeekendFT_DayOff_Schedule newBatch = new BM_23_WeekendFT_DayOff_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);
        System.Test.stopTest();
    }

}