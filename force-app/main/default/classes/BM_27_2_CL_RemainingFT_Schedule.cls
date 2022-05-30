/*
 Title: BM_27_2_CL_RemainingFT_Schedule

 설명: #12 - 잔여 권장 풀타임 오전 크루 배치

 @author: 아르겐 argen@digiformer.io

 작성 날짜: 04/22/2022

 마지막으로 수정한 날짜: 04/22/2022

 */
global without sharing class BM_27_2_CL_RemainingFT_Schedule implements Database.Batchable<sObject>, Database.Stateful{
    global Date startDate;
    global Date endDate;
    global Database.QueryLocator start(Database.BatchableContext dbc){

        /* Get Records of All 일자 별 생산성 관리 Records under these conditions
         1. Start to End Date (Screen Input)
         */

        String queryFields = 'SELECT Id, BM_DPM_Date__c, BM_DPM_OP_RcmndedNumbOfPpl__c, OP_ExtraFT__c, BM_DPM_FC__c ';
        String queryObjectAPIName = 'FROM BM_DailyProductivityManagement__c ';
        String queryWhereClause = 'WHERE BM_DPM_Date__c >=: startDate AND BM_DPM_Date__c <=: endDate ';
        String queryOrderBy = 'ORDER BY BM_DPM_Date__c ASC ';

        String query = queryFields + queryObjectAPIName + queryWhereClause + queryOrderBy;

        if (Test.isRunningTest()){
            query += ' LIMIT 1';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext dbc, List<BM_DailyProductivityManagement__c> colDPM){


        for (BM_DailyProductivityManagement__c dpm : colDPM){

            //Save needed info in specific variables


            String var_FCId_DPM = dpm.BM_DPM_FC__c;
            Date var_Date_DPM = dpm.BM_DPM_Date__c;

            Integer var_DPM_Extra = 0;

            if (dpm.OP_ExtraFT__c == null){
                var_DPM_Extra = 0;

            } else{
                var_DPM_Extra = Integer.valueOf(Math.floor(dpm.OP_ExtraFT__c));

            }


            Integer var_DPM_OP_Rmnd_FT = var_DPM_Extra + Integer.valueOf(Math.floor(dpm.BM_DPM_OP_RcmndedNumbOfPpl__c));

            String var_ID_DPM = dpm.Id;
            Date var_Date_DPM_Minus1 = var_Date_DPM.addDays(-1);
            Time var_Time_Less15 = time.newInstance(15, 00, 00, 00);

            /* 1st STEP: ELIMINATE THE CREWS THAT HAVE CREW SCHEDULES*/
            // 1.1 Get ALl the Crew Schedules with Crew Ids and Save them inside MAP
            //(BM_CS_Crew__r.BM_WorkType__c = '일반 풀타임(40)' OR BM_CS_Crew__r.BM_WorkType__c = '주말 풀타임(16)')

            Map<Id, BM_CrewSchedule__c> crewSchMap_WithCrews = new Map<Id, BM_CrewSchedule__c>();
            for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c
                                               FROM BM_CrewSchedule__c
                                               WHERE BM_CS_Date__c = :var_Date_DPM AND BM_CS_Crew__r.BM_FC_Name__c = :var_FCId_DPM AND (Vacation__c = true OR BM_CS_Holiday__c = true OR BM_CS_CheckIn__c != null) AND (BM_CS_Crew__r.BM_WorkType__c = '일반 풀타임(40)' OR BM_CS_Crew__r.BM_WorkType__c = '주말 풀타임(16)')]){

                if (!crewSchMap_WithCrews.containsKey(crewSch.BM_CS_Crew__c)){

                    crewSchMap_WithCrews.put(crewSch.BM_CS_Crew__c, crewSch);
                }
            }


            /* 1.2 Get All the Crew Records that are not inside the crewSchMap_WithCrews map + var_FCId_DPM
             In other words, create Create Schedules only for those who don't have Crew Schedules.
             */


            Map<Id, BM_CrewMgmt__c> crewMgtMap_HasNoSchedules = new Map<Id, BM_CrewMgmt__c>();

            //AND LastCreatedScheduleDate__c != :var_Date_DPM_Minus1 AND LastCreatedScheduleTime__c < :var_Time_Less15

            /*
             LastCreatedScheduleDate__c !=:var_Date_DPM_Minus1 OR
             (LastCreatedScheduleDate__c = :var_Date_DPM_Minus1 AND
             LastCreatedScheduleTime__c < :var_Time_Less15)


             */

            for (BM_CrewMgmt__c crew : [SELECT Id, Name
                                        FROM BM_CrewMgmt__c
                                        WHERE ID NOT IN:crewSchMap_WithCrews.keySet() AND BM_FC_Name__c = :var_FCId_DPM AND (RetiredDate__c > :var_Date_DPM OR RetiredDate__c = null) AND (BM_WorkType__c = '일반 풀타임(40)' OR BM_WorkType__c = '주말 풀타임(16)') AND (LastCreatedScheduleDate__c != :var_Date_DPM_Minus1 OR (LastCreatedScheduleDate__c = :var_Date_DPM_Minus1 AND LastCreatedScheduleTime__c < :var_Time_Less15))]){

                if (!crewMgtMap_HasNoSchedules.containsKey(crew.Id)){

                    crewMgtMap_HasNoSchedules.put(crew.Id, crew);
                }
            }


            /* STEP 2: CREATE # (count) of Crew Schedules
             - Only if crewMgtMap_HasNoSchedules.size() > 0
             - Sorted by Name ASC Nulls Last
             */


            // STEP 2.2 Create Crew Schedules for each crew


            if (crewMgtMap_HasNoSchedules.size() > 0 && crewMgtMap_HasNoSchedules != null){

                Integer count = var_DPM_OP_Rmnd_FT;
                Integer countCrew = crewMgtMap_HasNoSchedules.size();
                Integer incrementCount_HPM = 0;


                //make a list for the update operation
                List<BM_CrewSchedule__c> crewSchedulesList_ToInsert = new List<BM_CrewSchedule__c>();
                List<BM_HourlyProductivityManagement__c> listHPM_toUpdate = new List<BM_HourlyProductivityManagement__c>();

                if (count > 0 || countCrew > 0){

                    List<BM_CrewMgmt__c> crewList_toUpdate = new List<BM_CrewMgmt__c>();

                    for (BM_CrewMgmt__c crew : crewMgtMap_HasNoSchedules.values()){

                        BM_CrewSchedule__c newCrewSch = new BM_CrewSchedule__c();

                        newCrewSch.BM_CS_Crew__c = crew.id;

                        newCrewSch.BM_CS_Date__c = var_Date_DPM;

                        newCrewSch.BM_CS_CheckIn__c = Time.newInstance(06, 00, 00, 00);

                        newCrewSch.BM_CSType_6__C = '입고';
                        newCrewSch.BM_CSType_7__C = '입고';
                        newCrewSch.BM_CSType_8__C = '입고';
                        newCrewSch.BM_CSType_9__C = '피패킹';
                        newCrewSch.BM_CSType_10__C = '피패킹';
                        newCrewSch.BM_CSType_11__C = '피패킹';
                        newCrewSch.BM_CSType_12__C = '피패킹';
                        newCrewSch.BM_CSType_13__C = '피패킹';
                        newCrewSch.BM_CSType_14__C = '피패킹';

                        //crewSchedulesList_ToInsert.add(newCrewSch);
                        insert newCrewSch;

                        //Update the crew
                        crew.LastCreatedScheduleDate__c = var_Date_DPM;

                        crew.LastCreatedScheduleTime__c = Time.newInstance(06, 00, 00, 00);

                        crewList_toUpdate.add(crew);


                        //Decrement the counter
                        countCrew--;
                        count--;

                        if (incrementCount_HPM == 0 || incrementCount_HPM == null){

                            incrementCount_HPM = 1;

                        } else{

                            incrementCount_HPM = incrementCount_HPM + 1;

                        }


                        if (countCrew == 0 || count == 0){

                            break;

                            //    }


                        }

                        // insert crewSchedulesList_ToInsert;
                    }
                    update crewList_toUpdate;

                }
                // STEP 2.4 Retrieve 시간대별 생산성 관리 and save it in the list before the start of the loop

                Set<Integer> colTimeSlots = new Set<Integer>{ 6, 7, 8, 9, 10, 11, 12, 13, 14 };

                List<BM_HourlyProductivityManagement__c> hpmList = [SELECT Id, BM_HO_Slot__c, OP_ScheduledFullTimeMH__c
                                                                    FROM BM_HourlyProductivityManagement__c
                                                                    WHERE BM_HO_ProductivityManagement__c = :var_ID_DPM AND BM_HO_Slot__c IN:colTimeSlots
                                                                    ORDER BY BM_HO_Slot__c ASC];


                List<BM_HourlyProductivityManagement__c> hpmListToUpdate = new List<BM_HourlyProductivityManagement__c>();

                if (hpmList.size() > 0 && hpmList != null && incrementCount_HPM > 0){

                    // List<BM_HourlyProductivityManagement__c> hpmListToReset = new List<BM_HourlyProductivityManagement__c>();

                    // for (BM_HourlyProductivityManagement__c hpm : hpmList){
                    //     hpm.OP_ScheduledFullTimeMH__c = 0;
                    //     hpmListToReset.add(hpm);
                    // }

                    // update hpmListToReset;

                    for (BM_HourlyProductivityManagement__c hpm : hpmList){

                        if (hpm.OP_ScheduledFullTimeMH__c == 0 || hpm.OP_ScheduledFullTimeMH__c == null){

                            hpm.OP_ScheduledFullTimeMH__c = incrementCount_HPM;

                        } else{

                            hpm.OP_ScheduledFullTimeMH__c = hpm.OP_ScheduledFullTimeMH__c + incrementCount_HPM;

                        }

                        hpmListToUpdate.add(hpm);

                    }

                    update hpmListToUpdate;
                }

            }
        }
    }

    global void finish(Database.BatchableContext dbc){
        
        if(!Test.isRunningTest()){
            AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name
                          FROM AsyncApexJob
                          WHERE Id = :dbc.getJobId()];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAdresses = new String[]{ a.CreatedBy.Email };
            mail.setToAddresses(toAdresses);
            mail.setSubject('지표반영이 완료되었습니다.' + a.Status);
            mail.setPlainTextBody('안녕하세요, ' + a.CreatedBy.Name + '님. 지표반영이 완료되었습니다.' + '\n' + '시작 일자: ' + startDate + '\n' + '종료 일자: ' + endDate + '\n' + '- Salesforce 지원 팀 -');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        }
        
    }

}