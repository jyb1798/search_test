/*
 Title: 주말 풀타임 휴무 배치 (1차)

 설명: Additional OP_Fulltime

 @author: 신호연 shinhy@digiformer.io

 작성 날짜: 04/13/2022

 마지막으로 수정한 날짜: 04/19/2022

 */
global class BM_23_WeekendFT_DayOff_Schedule implements Database.Batchable<sObject>, Database.stateful{
    global Date startDate;
    global Date endDate;
    global Database.QueryLocator start(Database.BatchableContext bc){
        // collect the batches of records or objects to be passed to execute

        Set<Integer> weekNumset = new Set<Integer>{ 2, 3, 4, 5, 6 };

        String queryFields = 'Id, Name, BM_DPM_Date__c, BM_DPM_FC__c, Batch_WeekDay__c ';
        String queryObjectAPIName = 'BM_DailyProductivityManagement__c ';
        String condition = 'BM_DPM_Date__c >=:startDate AND BM_DPM_Date__c <=:endDate AND Batch_WeekDay__c IN: weekNumset ';
        String querySort = 'BM_DPM_FC__c, BM_DPM_Date__c ';
        String query = 'SELECT ' + queryFields + 'FROM ' + queryObjectAPIName + 'WHERE ' + condition + 'ORDER BY ' + querySort;

        if (Test.isRunningTest()){
            query = query + ' LIMIT 200';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<BM_DailyProductivityManagement__c> colDPM){
        // process each batch of records

        for (BM_DailyProductivityManagement__c dpm : colDPM){

            String FCId = dpm.BM_DPM_FC__c;
            Date dpmDate = dpm.BM_DPM_Date__c;
            String workType = '주말 풀타임(16)';

            /* OLD CODE 6:05 - 2022/04/25*/
            // List<BM_CrewMgmt__c> crewList = [SELECT Id, BM_FC_Name__c, BM_WorkType__c, RetiredDate__c, RetiredStatus__c
            //                                  FROM BM_CrewMgmt__c
            //                                  WHERE BM_FC_Name__c = :FCId AND BM_WorkType__c = :workType AND (RetiredDate__c > :dpmDate OR RetiredStatus__c != '퇴사')];


            // if (crewList != null && crewList.size() > 0){
            //     List<BM_CrewSchedule__c> insertCrewScheduleList = new List<BM_CrewSchedule__c>();
            //     for (BM_CrewMgmt__c crew : crewList){
            //         BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
            //         crewSchedule.BM_CS_Date__c = dpmDate;
            //         crewSchedule.BM_CS_Crew__c = crew.Id;
            //         insertCrewScheduleList.add(crewSchedule);
            //     }
            //     insert insertCrewScheduleList;
            // }

            /* Update: 6:05 - 2022/04/25*/

            Map<Id, BM_CrewSchedule__c> mapOfCrews_withSchedulesOrNotAvlble = new Map<Id, BM_CrewSchedule__c>();

            for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, Vacation__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
                                               FROM BM_CrewSchedule__c
                                               WHERE BM_CS_Crew__r.BM_FC_Name__c = :FCId AND BM_CS_Date__c = :dpmDate AND BM_CS_Crew__r.BM_WorkType__c = :workType AND (Vacation__c = TRUE OR BM_CS_Holiday__c = TRUE)]){
                if (!mapOfCrews_withSchedulesOrNotAvlble.containsKey(crewSch.BM_CS_Crew__c)){
                    mapOfCrews_withSchedulesOrNotAvlble.put(crewSch.BM_CS_Crew__c, crewSch);
                }
            }

            Map<Id, BM_CrewMgmt__c> mapOfCrews_AvlbleForScheduling = new Map<Id, BM_CrewMgmt__c>();

            for (BM_CrewMgmt__c crew : [SELECT Id, Name
                                        FROM BM_CrewMgmt__c
                                        WHERE ID NOT IN:mapOfCrews_withSchedulesOrNotAvlble.keySet() AND BM_FC_Name__c = :FCId AND (RetiredDate__c > :dpmDate OR RetiredStatus__c != '퇴사') AND BM_WorkType__c = :workType]){
                if (!mapOfCrews_AvlbleForScheduling.containsKey(crew.id)){
                    mapOfCrews_AvlbleForScheduling.put(crew.id, crew);
                }
            }

            if (mapOfCrews_AvlbleForScheduling != null && mapOfCrews_AvlbleForScheduling.size() > 0){
                List<BM_CrewSchedule__c> insertCrewScheduleList = new List<BM_CrewSchedule__c>();
                for (BM_CrewMgmt__c crew : mapOfCrews_AvlbleForScheduling.values()){
                    BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                    crewSchedule.BM_CS_Date__c = dpmDate;
                    crewSchedule.BM_CS_Crew__c = crew.Id;
                    insertCrewScheduleList.add(crewSchedule);
                }
                insert insertCrewScheduleList;
            }

        }
    }

    global void finish(Database.BatchableContext bc){
        //     execute any post-processing operations
        if (!Test.isRunningTest()){
            BM_24_FixedDayOff_Schedule batch = new BM_24_FixedDayOff_Schedule();
            batch.startDate = startDate;
            batch.endDate = endDate;
            Database.executeBatch(batch, 1);
        }
    }

}