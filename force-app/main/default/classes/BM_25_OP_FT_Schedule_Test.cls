@isTest(SeeAllData = false)
private class BM_25_OP_FT_Schedule_Test{
    @isTest
    private static void TestBM_AddOPFT_ForNegative(){
        Test.startTest();


        Date startDate = Date.newInstance(2023, 01, 01);
        Date endDate = Date.newInstance(2023, 01, 08);

        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrews(1, 9);

        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();
        List<BM_CrewMgmt__c> newCrewListNotAvailable = new List<BM_CrewMgmt__c>();
        for (BM_FC_Mgmt__c fc : fcs){
            for (Integer i = 0; i <= 8; i++){
                BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
                newDPM.BM_DPM_FC__c = fc.Id;
                newDPM.BM_DPM_Date__c = (Date.newInstance(2023, 01, 01)).addDays(i);
                dpmListToInsert.add(newDPM);

                BM_CrewMgmt__c newCrew = new BM_CrewMgmt__c();
                newCrew.BM_FC_Name__c = fc.id;
                newCrew.Name = 'Test Argen';
                newCrew.BM_WorkType__c = '주말 풀타임(16)';
                newCrew.RetiredDate__c = (Date.newInstance(2023, 01, 01)).addYears(1);
                newCrewListNotAvailable.add(newCrew);
            }

        }
        insert dpmListToInsert;
        insert newCrewListNotAvailable;

        List<BM_HourlyProductivityManagement__c> hpmListToInsert = new List<BM_HourlyProductivityManagement__c>();
        for (BM_DailyProductivityManagement__c dpm : dpmListToInsert){
            for (Integer slot = 6; slot <= 14; slot++){
                BM_HourlyProductivityManagement__c newHPM = new BM_HourlyProductivityManagement__c();
                newHPM.BM_HO_Slot__c = slot;
                newHPM.BM_HO_ProductivityManagement__c = dpm.id;
                hpmListToInsert.add(newHPM);
            }
        }
        insert hpmListToInsert;

        List<BM_CrewSchedule__c> newCSList = new List<BM_CrewSchedule__c>();
        for (BM_CrewMgmt__c crew : newCrewListNotAvailable){
            for (Integer i = 0; i < 3; i++){
                BM_CrewSchedule__c crewSch = new BM_CrewSchedule__c();
                crewSch.BM_CS_Crew__c = crew.id;
                crewSch.BM_CS_CheckIn__c = Time.newInstance(06, 00, 00, 00);
                crewSch.BM_CS_Date__c = startDate.addDays(i);
                newCSList.add(crewSch);
            }
        }

        insert newCSList;
        //test the class with the available data


        BM_25_OP_FT_Schedule newBatch = new BM_25_OP_FT_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);

        Test.stopTest();
    }

    @isTest
    private static void TestBM_AddOPFT_WithoutCrews(){
        Test.startTest();
        Date startDate = Date.newInstance(2023, 01, 01);

        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrewsPTandFT(1, 10, startDate);

        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();


        //test the class with the available data

        Date endDate = Date.newInstance(2023, 01, 08);

        BM_25_OP_FT_Schedule newBatch = new BM_25_OP_FT_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);
        Test.stopTest();
    }

    @isTest
    private static void TestBM_AddOPFT_OP_ScheduledFullTimeMH(){
        Test.startTest();


        Date startDate = Date.newInstance(2023, 01, 01);
        Date endDate = Date.newInstance(2023, 01, 08);

        BM_FC_Mgmt__c[] fcs = BM_StageToLive_TestDataFactory.createFCWithCrews(1, 9);

        List<BM_DailyProductivityManagement__c> dpmListToInsert = new List<BM_DailyProductivityManagement__c>();
        List<BM_CrewMgmt__c> newCrewListNotAvailable = new List<BM_CrewMgmt__c>();
        for (BM_FC_Mgmt__c fc : fcs){
            for (Integer i = 0; i <= 8; i++){
                BM_DailyProductivityManagement__c newDPM = new BM_DailyProductivityManagement__c();
                newDPM.BM_DPM_FC__c = fc.Id;
                newDPM.BM_DPM_Date__c = (Date.newInstance(2023, 01, 01)).addDays(i);
                dpmListToInsert.add(newDPM);

                BM_CrewMgmt__c newCrew = new BM_CrewMgmt__c();
                newCrew.BM_FC_Name__c = fc.id;
                newCrew.Name = 'Test Argen';
                newCrew.BM_WorkType__c = '주말 풀타임(16)';
                newCrew.RetiredDate__c = (Date.newInstance(2023, 01, 01)).addYears(1);
                newCrewListNotAvailable.add(newCrew);
            }

        }
        insert dpmListToInsert;
        insert newCrewListNotAvailable;

        List<BM_HourlyProductivityManagement__c> hpmListToInsert = new List<BM_HourlyProductivityManagement__c>();
        for (BM_DailyProductivityManagement__c dpm : dpmListToInsert){
            for (Integer slot = 6; slot <= 14; slot++){
                BM_HourlyProductivityManagement__c newHPM = new BM_HourlyProductivityManagement__c();
                newHPM.BM_HO_Slot__c = slot;
                newHPM.BM_HO_ProductivityManagement__c = dpm.id;
                newHPM.OP_ScheduledFullTimeMH__c = 2;
                hpmListToInsert.add(newHPM);
            }
        }
        insert hpmListToInsert;

        List<BM_CrewSchedule__c> newCSList = new List<BM_CrewSchedule__c>();
        for (BM_CrewMgmt__c crew : newCrewListNotAvailable){
            for (Integer i = 0; i < 3; i++){
                BM_CrewSchedule__c crewSch = new BM_CrewSchedule__c();
                crewSch.BM_CS_Crew__c = crew.id;
                crewSch.BM_CS_CheckIn__c = Time.newInstance(06, 00, 00, 00);
                crewSch.BM_CS_Date__c = startDate.addDays(i);
                newCSList.add(crewSch);
            }
        }

        insert newCSList;
        //test the class with the available data


        BM_25_OP_FT_Schedule newBatch = new BM_25_OP_FT_Schedule();
        newBatch.startDate = startDate;
        newBatch.endDate = endDate;
        Database.executeBatch(newBatch, 1);

        Test.stopTest();
    }

}