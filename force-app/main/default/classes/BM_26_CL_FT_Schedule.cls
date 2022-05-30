/*
 Title: BM_26_CL_FT_Schedule
 설명:  권장 풀타임 오후 크루 배치
 @author: Argen
 작성 날짜: 2022-04-17
 마지막으로 수정한 날짜: 2022-04-17
 */
global without sharing class BM_26_CL_FT_Schedule implements Database.Batchable<sObject>, Database.Stateful{
    global Date startDate;
    global Date endDate;
    global Database.QueryLocator start(Database.BatchableContext dbc){

        String queryFields = 'SELECT Id, Name, BM_DPM_Date__c, BM_DPM_FC__c, BM_DPM_RecommendedFT_MH__c, ExtraFT__c, BM_DPM_PartTimeMH_Average__c, ExtraPT__c ';
        String queryObjectAPIName = 'FROM BM_DailyProductivityManagement__c ';
        String queryWhereClause = 'WHERE BM_DPM_Date__c >=: startDate AND BM_DPM_Date__c <=: endDate ';
        String queryOrderby = 'ORDER BY BM_DPM_Date__c ASC ';

        String query = queryFields + queryObjectAPIName + queryWhereClause + queryOrderby;


        if (Test.isRunningTest()){
            query += ' LIMIT 1';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext dbc, List<BM_DailyProductivityManagement__c> dailyList){


        for (BM_DailyProductivityManagement__c dpm : dailyList){
            String var_DPMId = dpm.id;
            String var_DPMFC = dpm.BM_DPM_FC__c;
            Date var_DPMDate = dpm.BM_DPM_Date__c;

            //Get All Crew IDs in CrewSchedules that are:
            // 휴무 = TRUE
            // 휴가 = TRUE
            // 출근 시간 <> isNull
            // 크루__r.FC = Loop#1_FC
            // 날짜 = Loop#1_날짜

            Map<Id, BM_CrewSchedule__c> mapOfCrews_withSchedulesOrNotAvlble = new Map<Id, BM_CrewSchedule__c>();

            for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, Vacation__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
                                               FROM BM_CrewSchedule__c
                                               WHERE BM_CS_Crew__r.BM_FC_Name__c = :var_DPMFC AND BM_CS_Date__c = :var_DPMDate AND (Vacation__c = TRUE OR BM_CS_Holiday__c = TRUE OR BM_CS_CheckIn__c != null)]){
                if (!mapOfCrews_withSchedulesOrNotAvlble.containsKey(crewSch.BM_CS_Crew__c)){
                    mapOfCrews_withSchedulesOrNotAvlble.put(crewSch.BM_CS_Crew__c, crewSch);
                }
            }

            // ================================

            Date var_DPMDate_PlusOne = var_DPMDate.addDays(1);
            Time var_Time_0600 = Time.newInstance(06, 00, 00, 00);
            Time var_Time_1500 = Time.newInstance(15, 00, 00, 00);


            // ===============================
            // ===============================
            /* startDate , endDate*/

//delete
            Map<Id, BM_CrewSchedule__c> mapOfCrews_withSchedulesOrNotAvlblePost_Final = new Map<Id, BM_CrewSchedule__c>();
            for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, Vacation__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
                                               FROM BM_CrewSchedule__c
                                               WHERE BM_CS_Crew__r.BM_FC_Name__c = :var_DPMFC AND BM_CS_Date__c >= :var_DPMDate AND BM_CS_Date__c <= :endDate AND ((BM_CS_CheckIn__c = :var_Time_1500 OR BM_CS_CheckIn__c = :var_Time_0600)) AND (BM_CS_Date__c = :var_DPMDate_PlusOne AND BM_CS_Holiday__c = FALSE)]){
                if (!mapOfCrews_withSchedulesOrNotAvlblePost_Final.containsKey(crewSch.BM_CS_Crew__c)){
                    mapOfCrews_withSchedulesOrNotAvlblePost_Final.put(crewSch.BM_CS_Crew__c, crewSch);
                }
            }
//delete
            /* QUICK TEST CHECK 25/04/2022 old code below
             Map<Id, BM_CrewSchedule__c> mapOfCrews_withSchedulesOrNotAvlblePost_Final = new Map<Id, BM_CrewSchedule__c>();
             for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, Vacation__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
             FROM BM_CrewSchedule__c
             WHERE BM_CS_Crew__c NOT IN:mapOfCrews_withSchedulesOrNotAvlble.keySet() AND BM_CS_Date__c >= :var_DPMDate AND BM_CS_Date__c <= :endDate AND (BM_CS_CheckIn__c = :var_Time_1500 OR BM_CS_CheckIn__c = :var_Time_0600)]){
             if (!mapOfCrews_withSchedulesOrNotAvlblePost_Final.containsKey(crewSch.BM_CS_Crew__c)){
             mapOfCrews_withSchedulesOrNotAvlblePost_Final.put(crewSch.BM_CS_Crew__c, crewSch);
             }
             }


             */
            //================================
            //================================


            //=================================

            Map<Id, BM_CrewMgmt__c> mapOfCrews_AvlbleForScheduling = new Map<Id, BM_CrewMgmt__c>();

            for (BM_CrewMgmt__c crew : [SELECT Id, Name
                                        FROM BM_CrewMgmt__c
                                        WHERE  ID NOT IN:mapOfCrews_withSchedulesOrNotAvlble.keySet() AND ID NOT IN:mapOfCrews_withSchedulesOrNotAvlblePost_Final.keySet() AND BM_FC_Name__c = :var_DPMFC AND (RetiredDate__c > :var_DPMDate OR RetiredStatus__c = '재직중') AND (BM_WorkType__c = '일반 풀타임(40)' OR BM_WorkType__c = '주말 풀타임(16)')]){
                if (!mapOfCrews_AvlbleForScheduling.containsKey(crew.id)){
                    mapOfCrews_AvlbleForScheduling.put(crew.id, crew);
                }
            }

            Set<Integer> colTimeSlots_1523 = new Set<Integer>{ 15, 16, 17, 18, 19, 20, 21, 22, 23 };
            List<BM_HourlyProductivityManagement__c> hpmList_1523 = [SELECT Id, BM_HO_Slot__c, CL_ScheduledFullTimeMH__c
                                                                     FROM BM_HourlyProductivityManagement__c
                                                                     WHERE BM_HO_ProductivityManagement__c = :var_DPMId AND BM_HO_Slot__c IN:colTimeSlots_1523];


            if (mapOfCrews_AvlbleForScheduling.size() > 0 && mapOfCrews_AvlbleForScheduling != null){
                List<BM_CrewMgmt__c> crewListToUpdate = new List<BM_CrewMgmt__c>();
                List<BM_CrewSchedule__c> crewScheduleToInsert = new List<BM_CrewSchedule__c>();

                List<BM_HourlyProductivityManagement__c> hpmListToReset = new List<BM_HourlyProductivityManagement__c>();
                for (BM_HourlyProductivityManagement__c hpm : hpmList_1523){
                    hpm.CL_ScheduledFullTimeMH__c = 0;
                    hpmListToReset.add(hpm);
                }

                for (BM_CrewMgmt__c crew : mapOfCrews_AvlbleForScheduling.values()){
                    BM_CrewSchedule__c newCrewSch = new BM_CrewSchedule__c();
                    newCrewSch.BM_CS_Date__c = var_DPMDate;
                    newCrewSch.BM_CS_CheckIn__c = time.newInstance(15, 00, 00, 00);
                    newCrewSch.BM_CS_Crew__c = crew.Id;

                    newCrewSch.BM_CSType_15__C = '피패킹';
                    newCrewSch.BM_CSType_16__C = '피패킹';
                    newCrewSch.BM_CSType_17__C = '피패킹';
                    newCrewSch.BM_CSType_18__C = '피패킹';
                    newCrewSch.BM_CSType_19__C = '피패킹';
                    newCrewSch.BM_CSType_20__C = '피패킹';
                    newCrewSch.BM_CSType_21__C = '피패킹';
                    newCrewSch.BM_CSType_22__C = '피패킹';
                    newCrewSch.BM_CSType_23__C = '피패킹';

                    crewScheduleToInsert.add(newCrewSch);

                    //Update 크루 관리
                    crew.LastCreatedScheduleDate__c = var_DPMDate;
                    crew.LastCreatedScheduleTime__c = time.newInstance(15, 00, 00, 00);
                    crewListToUpdate.add(crew);


                    //Add 1 to Loop#4_오전 스케줄 풀타임 MH - 오후 스케줄 풀타임 MH    CL_ScheduledFullTimeMH__c
                    List<BM_HourlyProductivityManagement__c> hpmList_1523_toUpdate = new List<BM_HourlyProductivityManagement__c>();
                    for (BM_HourlyProductivityManagement__c hpm : hpmList_1523){
                        if (hpm.CL_ScheduledFullTimeMH__c == 0 || hpm.CL_ScheduledFullTimeMH__c == null){
                            hpm.CL_ScheduledFullTimeMH__c = 1;
                        } else{
                            hpm.CL_ScheduledFullTimeMH__c = hpm.CL_ScheduledFullTimeMH__c + 1;
                        }
                        hpmList_1523_toUpdate.add(hpm);
                    }
                    update hpmList_1523_toUpdate;
                }

                update crewListToUpdate;
                insert crewScheduleToInsert;
            }

        }
    }

    global void finish(Database.BatchableContext dbc){
        if (!Test.isRunningTest()){
            BM_27_CL_PT_Schedule batch = new BM_27_CL_PT_Schedule();
            batch.startDate = startDate;
            batch.endDate = endDate;
            Database.executeBatch(batch, 1);
        }
    }

}