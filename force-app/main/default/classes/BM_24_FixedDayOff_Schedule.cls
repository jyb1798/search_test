/*
 Update version v5 - by Argen
 */
global without sharing class BM_24_FixedDayOff_Schedule implements Database.Batchable<AggregateResult>, Database.Stateful{
    global Date startDate;
    global Date endDate;
    global Date currentDate;
    global Iterable<AggregateResult> start(Database.BatchableContext dbc){
        /**
         * 기간내 BM_DPM_FC__c 리스트 반환(중복 제거)
         */

        Datetime dt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
        System.debug(dt);
        String queryStartDt = dt.format('YYYY-MM-dd');
        dt = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day());
        String queryEndDt = dt.format('YYYY-MM-dd');

        String queryFiled = 'BM_DPM_FC__c';
        String queryObjectApiName = 'BM_DailyProductivityManagement__c';
        String condition = 'BM_DPM_Date__c>=' + queryStartDt + 'AND BM_DPM_Date__c <=' + queryEndDt;
        String querySort = 'BM_DPM_FC__c';
        String requestQuery = 'SELECT ' + queryFiled + ' FROM ' + queryObjectApiName + ' WHERE ' + condition + ' GROUP BY BM_DPM_FC__c ORDER BY ' + querySort;

        if (Test.isRunningTest()){
            requestQuery += ' LIMIT 200';
        }
        return new AggregateResultIterable(requestQuery);
    }

    global void execute(Database.BatchableContext dbc, List<SObject> colDPM){
        /**
         * 일자별 생산성 관리에서 총 권장인원, 요일, FC 정보 데이터를 조회
         * 요일별 총권장인원 평균을 구한 후 총 권장인원이 적은 순으로 Sort
         * - 휴무코드
         *   주말은 연달아 휴무가 발생하면 안되며 하루 걸러 하루 휴무가 발생해도 안됨
         * - 해당 FC 전체 크루 조회
         *   조회조건은 퇴사일이 근무일 보다 크며, 해당 날짜의 출근일이 null일 크루들을 ㄱ,ㄴ,ㄷ순으로 조회
         * - 앞에서 정한 휴무 코드를 순차적으로 크루들에게 매핑 시킨 후 DB INSERT
         */

        List<BM_DailyProductivityManagement__c> tempList = new List<BM_DailyProductivityManagement__c>();
        for (SObject sObj : colDPM){
            AggregateResult ar = (AggregateResult)sObj;
            BM_DailyProductivityManagement__c dpm = new BM_DailyProductivityManagement__c();
            dpm.BM_DPM_FC__c = String.valueOf(ar.get('BM_DPM_FC__c'));
            tempList.add(dpm);
        }


        for (BM_DailyProductivityManagement__c dpm : tempList){
            // BM_DPM_FC__c 로 일자별 생산성 관리에서 기간별 해당 지점 정보 재조회
            // 평균값 정렬 조회
            String dpmFcId = dpm.BM_DPM_FC__c;
            Date dpmDate = dpm.BM_DPM_Date__c;
            List<Integer> rmndList = new List<Integer>();
            for (AggregateResult ar : [SELECT AVG(TotalRmndWorkers__c)TotalRmndWorkers__c, DAY_IN_WEEK(BM_DPM_Date__c)Batch_WeekDay__c
                                       FROM BM_DailyProductivityManagement__c
                                       WHERE BM_DPM_FC__c = :dpmFcId AND BM_DPM_Date__c >= :startDate AND BM_DPM_Date__c <= :endDate
                                       GROUP BY DAY_IN_WEEK(BM_DPM_Date__c)
                                       ORDER BY AVG(TotalRmndWorkers__c), DAY_IN_WEEK(BM_DPM_Date__c)
                                       LIMIT 2000]){
                // BM_DailyProductivityManagement__c tempData = new BM_DailyProductivityManagement__c();
                // tempData.TotalRmndWorkers__c = String.valueOf(ar.get('TotalRmndWorkers__c'));
                // tempData.Batch_WeekDay__c = String.valueOf(ar.get('Batch_WeekDay__c'));

                rmndList.add(Integer.valueOf(ar.get('Batch_WeekDay__c')));
            }

            if (rmndList != null && rmndList.size() > 0){
                // 휴무 코드 생성

                // 고정요일 코드 (월 - 일)
                List<Integer> days = new List<Integer>{ 2, 3, 4, 5, 6, 7, 1 };
                List<Integer> ordList = new List<Integer>();
                ordList.addAll(rmndList);
                Integer cnt = 0;
                List<Map<String, Object>> breakList = new List<Map<String, Object>>();
                for (Integer dayNum : days){
                    if (ordList.size() > 0){
                        Map<String, Object> breakMap = new Map<String, Object>();
                        breakMap.put('firstDay', dayNum);
                        for (Integer j = 0; j < ordList.size(); j++){
                            Integer ordWeekNum = Integer.valueOf(ordList.get(j));
                            Integer secondDay = 0;
                            if (dayNum == 2 && ordWeekNum != 2 && ordWeekNum != 4 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 3 && ordWeekNum != 1 && ordWeekNum != 3 && ordWeekNum != 5){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 4 && ordWeekNum != 2 && ordWeekNum != 4 && ordWeekNum != 6){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 5 && ordWeekNum != 3 && ordWeekNum != 5 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 6 && ordWeekNum != 1 && ordWeekNum != 4 && ordWeekNum != 6){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 7 && ordWeekNum != 1 && ordWeekNum != 2 && ordWeekNum != 5 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 1 && ordWeekNum != 1 && ordWeekNum != 3 && ordWeekNum != 6 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            }
                            if (secondDay > 0){
                                breakMap.put('secondDay', secondDay);
                                breakList.add(breakMap);
                                ordList.remove(j);
                                cnt += 1;
                                break;
                            }
                        }
                    }
                }
                if (cnt < 7){
                    ordList = new List<Integer>();
                    ordList.addAll(rmndList);
                    for (Integer i = cnt; i < days.size(); i++){
                        Integer dayNum = days.get(i);
                        Map<String, Object> breakMap = new Map<String, Object>();
                        breakMap.put('firstDay', dayNum);
                        for (Integer j = 0; j < ordList.size(); j++){
                            Integer ordWeekNum = Integer.valueOf(ordList.get(j));
                            Integer secondDay = 0;
                            if (dayNum == 2 && ordWeekNum != 2 && ordWeekNum != 4 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 3 && ordWeekNum != 1 && ordWeekNum != 3 && ordWeekNum != 5){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 4 && ordWeekNum != 2 && ordWeekNum != 4 && ordWeekNum != 6){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 5 && ordWeekNum != 3 && ordWeekNum != 5 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 6 && ordWeekNum != 1 && ordWeekNum != 4 && ordWeekNum != 6){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 7 && ordWeekNum != 1 && ordWeekNum != 2 && ordWeekNum != 5 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            } else if (dayNum == 1 && ordWeekNum != 1 && ordWeekNum != 3 && ordWeekNum != 6 && ordWeekNum != 7){
                                secondDay = ordWeekNum;
                            }
                            if (secondDay > 0){
                                breakMap.put('secondDay', secondDay);
                                breakList.add(breakMap);
                                ordList.remove(j);
                                cnt += 1;
                                break;
                            }
                        }

                    }

                }

                // 요일 코드로 날짜 매칭
                List<List<BM_DailyProductivityManagement__c>> dateList = new List<List<BM_DailyProductivityManagement__c>>();
                for (Integer i = 0; i < breakList.size(); i++){
                    Map<String, Object> breakDat = breakList.get(i);
                    Integer firstDayNum = Integer.valueOf(breakDat.get('firstDay'));
                    Integer secondDayNum = Integer.valueOf(breakDat.get('secondDay'));
                    Set<Integer> weekDaySlot = new Set<Integer>{ firstDayNum, secondDayNum };
                    List<BM_DailyProductivityManagement__c> selectDaysList = [SELECT Id, Name, BM_DPM_FC__c, BM_DPM_Date__c, Batch_WeekDay__c
                                                                              FROM BM_DailyProductivityManagement__c
                                                                              WHERE BM_DPM_FC__c = :dpmFcId AND BM_DPM_Date__c >= :startDate AND BM_DPM_Date__c <= :endDate AND Batch_WeekDay__c IN:weekDaySlot
                                                                              ORDER BY BM_DPM_Date__c];
                    if (selectDaysList != null && selectDaysList.size() > 0){
                        dateList.add(selectDaysList);
                    }

                }


                // 크루 조회
                List<BM_CrewMgmt__c> crewList = [SELECT Id, BM_EmpNo__c, BM_Working__c, Name, RetiredDate__c, RetiredStatus__c
                                                 FROM BM_CrewMgmt__c
                                                 WHERE BM_FC_Name__c = :dpmFcId AND BM_WorkType__c NOT IN ('주말 풀타임(16)', '파트타임(20)') AND (RetiredDate__c > :startDate OR RetiredDate__c = NULL)
                                                 ORDER BY Name];

                if (crewList != null && crewList.size() > 0){
                    List<List<BM_DailyProductivityManagement__c>> mergeList = new List<List<BM_DailyProductivityManagement__c>>();
                    Integer crewCount = crewList.size();
                    if (crewCount > 7){
                        Integer divCrew = crewCount / 7;

                        for (Integer i = 0; i < divCrew; i++){
                            mergeList.addAll(dateList);
                        }

                        Integer remainCnt = crewCount - (divCrew * 7);
                        for (Integer i = 0; i < remainCnt; i++){
                            if (dateList.size() > i){
                                mergeList.add(dateList.get(i));
                            }
                        }
                    } else{
                        for (Integer j = 0; j < crewList.size(); j++){
                            if (dateList.size() > j){
                                mergeList.add(dateList.get(j));
                            }
                        }
                    }

                    // 크루 순차적으로 휴무코드 매핑
                    //   Integer dtIndex = 0;
                    //   for(BM_CrewMgmt__c crew: crewList) {
                    //     String crewId = crew.Id;
                    //     List<BM_CrewSchedule__c> crewSchedulesList = new List<BM_CrewSchedule__c>();
                    //     List<BM_DailyProductivityManagement__c> breakDtList = mergeList.get(dtIndex);
                    //     for(BM_DailyProductivityManagement__c breakDt: breakDtList) {
                    //         BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                    //         crewSchedule.BM_CS_Date__c = breakDt.BM_DPM_Date__c;
                    //         crewSchedule.BM_CS_CheckIn__c = null;
                    //         crewSchedule.BM_CS_Crew__c = crewId;
                    //         crewSchedulesList.add(crewSchedule);
                    //     }
                    //     insert crewSchedulesList;
                    //     dtIndex += 1;
                    //   }

                                   
            

                    Map<Id, BM_CrewSchedule__c> mapOfCrews_withSchedulesOrNotAvlble = new Map<Id, BM_CrewSchedule__c>();
                    for (BM_CrewSchedule__c crewSch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, Vacation__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
                                                       FROM BM_CrewSchedule__c
                                                       WHERE BM_CS_Date__c >= :startDate AND BM_CS_Date__c <= :endDate AND (Vacation__c = TRUE OR BM_CS_Holiday__c = TRUE)]){
                        if (!mapOfCrews_withSchedulesOrNotAvlble.containsKey(crewSch.BM_CS_Crew__c)){
                            mapOfCrews_withSchedulesOrNotAvlble.put(crewSch.BM_CS_Crew__c, crewSch);
                        }
                    }

                    
                    /* 5/16/ 2022 - Non-Wknd DayOff Scheduling first for Wknd Scheduling */
                    
                    List<BM_CrewSchedule__c> dayOffCrewSchList =  new List<BM_CrewSchedule__c>();
                    for(BM_CrewSchedule__c sch : [SELECT Id, BM_CS_Crew__c, BM_CS_Date__c, BM_CS_Holiday__c, BM_CS_CheckIn__c
                                                  FROM BM_CrewSchedule__c
                                                  WHERE BM_CS_Date__c >= :startDate.addDays(-8) 
                                                  AND BM_CS_Date__c <= :endDate 
                                                  AND BM_CS_Holiday__c = TRUE
                                                  AND BM_CS_Crew__r.BM_WorkType__c NOT IN ('주말 풀타임(16)', '파트타임(20)')
                                                  AND DAY_IN_WEEK(BM_CS_Date__c) IN (1, 7)
                                                  AND BM_CS_Crew__r.BM_FC_Name__c = :dpmFcId]){
                       if(!dayOffCrewSchList.contains(sch)){
                       dayOffCrewSchList.add(sch);                               
                       }
                     }

                   	List<BM_CrewMgmt__c> crewListInclusive = crewList;
                   	List<BM_CrewMgmt__c> crewListPriorWknd = new List<BM_CrewMgmt__c>();
                    List<List<BM_DailyProductivityManagement__c>> mergeList2 = mergeList; 
                    List<List<BM_DailyProductivityManagement__c>> mergeListNonWknd = new List<List<BM_DailyProductivityManagement__c>>();

                    
                    for(Integer i = (mergeList.size()-1); i>=0; i--){                        
                        /* Get the Crews who are meant for Non-wknd Crew Scheduling (e.g who has prior schedules during weekend) */                       
                        BM_CrewMgmt__c crewData = crewList.get(i);
                        String crewId = crewData.Id;
                        if(!dayOffCrewSchList.isEmpty() && dayOffCrewSchList != null){
							for(BM_CrewSchedule__c sch : dayOffCrewSchList){
                                if(sch.BM_CS_Crew__c == crewId){
                                    system.debug('Crew that has a crew schedule prior: '+ crewData.Name + ' on : '+ sch.BM_CS_Date__c);
                                    crewListPriorWknd.add(crewData);
                                    crewListInclusive.remove(i);
                                    break;
                                }
                        	}
                        }
                        
                        
                        
                    }
                    
                    //Crew Scheduling for non-wknd days 
                    if(!crewListPriorWknd.isEmpty() && crewListPriorWknd != null){
                        List<BM_CrewSchedule__c> crewSchedulesList = new List<BM_CrewSchedule__c>();
                        for(BM_CrewMgmt__c crewNW : crewListPriorWknd){
                            for(Integer i = (mergeList.size()-1); i>=0; i--){
                        		List<BM_DailyProductivityManagement__c> breakDtList = mergeList.get(i);
                                
                                if(breakDtList[0].Batch_WeekDay__c != 7 && breakDtList[0].Batch_WeekDay__c != 1){
                                    if(breakDtList[1].Batch_WeekDay__c != 7 && breakDtList[1].Batch_WeekDay__c != 1){
                                        
                        				for (BM_DailyProductivityManagement__c breakDt : breakDtList){
                                            if (mapOfCrews_withSchedulesOrNotAvlble.size() > 0 && mapOfCrews_withSchedulesOrNotAvlble != null){
                                                if (mapOfCrews_withSchedulesOrNotAvlble.containsKey(crewNW.id) && mapOfCrews_withSchedulesOrNotAvlble.get(crewNW.id).BM_CS_Date__c == breakDt.BM_DPM_Date__c){
                                                    system.debug('No schedules on: '+ breakDt.BM_DPM_Date__c + '. Because there is already one.');
                                                } else{
                                                BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                                                crewSchedule.BM_CS_Date__c = breakDt.BM_DPM_Date__c;
                                                crewSchedule.BM_CS_CheckIn__c = NULL;
                                                crewSchedule.BM_CS_Crew__c = crewNW.id;
                                                crewSchedulesList.add(crewSchedule);
                                                System.debug('There is no duplicate. We will create the schedule on this date: ' + breakDt.BM_DPM_Date__c); 
                                                }
                                            }else{
                                                BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                                                crewSchedule.BM_CS_Date__c = breakDt.BM_DPM_Date__c;
                                                crewSchedule.BM_CS_CheckIn__c = NULL;
                                                crewSchedule.BM_CS_Crew__c = crewNW.id;
                                                crewSchedulesList.add(crewSchedule);
                                                System.debug('There is no duplicate. We will create the schedule on this date: ' + breakDt.BM_DPM_Date__c); 
                                            }                                                                               
                                        }
                                        mergeList2.remove(i);
                                        break;
                                    } 
                                }
                            }
                        }
                        
                        if(crewSchedulesList.size()>0 && crewSchedulesList!= null){
                            insert crewSchedulesList;
                        }
                    }
                    
                    /* End of 5/16/ 2022 - Non-Wknd DayOff Scheduling first for Wknd Scheduling  */
                    for (Integer i = (mergeList2.size()-1); i >=0 ; i--){
                        List<BM_CrewSchedule__c> crewSchedulesList = new List<BM_CrewSchedule__c>();
                        BM_CrewMgmt__c crewData = crewListInclusive.get(i);
                        String crewId = crewData.Id;


                        List<BM_DailyProductivityManagement__c> breakDtList = mergeList2.get(i);
                        for (BM_DailyProductivityManagement__c breakDt : breakDtList){
                            if (mapOfCrews_withSchedulesOrNotAvlble.size() > 0 && mapOfCrews_withSchedulesOrNotAvlble != null){
                                 if (mapOfCrews_withSchedulesOrNotAvlble.containsKey(crewId) && mapOfCrews_withSchedulesOrNotAvlble.get(crewId).BM_CS_Date__c == breakDt.BM_DPM_Date__c){
                                       system.debug('No schedules on: '+ breakDt.BM_DPM_Date__c + '. Because there is already one.');
                                  	} else{
                                       BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                                       crewSchedule.BM_CS_Date__c = breakDt.BM_DPM_Date__c;
                                       crewSchedule.BM_CS_CheckIn__c = NULL;
                                       crewSchedule.BM_CS_Crew__c = crewId;
                                       crewSchedulesList.add(crewSchedule);
                                       System.debug('There is no duplicate. We will create the schedule on this date: ' + breakDt.BM_DPM_Date__c); 
                                       }
                                  }else{
                                       BM_CrewSchedule__c crewSchedule = new BM_CrewSchedule__c();
                                       crewSchedule.BM_CS_Date__c = breakDt.BM_DPM_Date__c;
                                       crewSchedule.BM_CS_CheckIn__c = NULL;
                                       crewSchedule.BM_CS_Crew__c = crewId;
                                       crewSchedulesList.add(crewSchedule);
                                       System.debug('There is no duplicate. We will create the schedule on this date: ' + breakDt.BM_DPM_Date__c); 
                                       }                   
                        }
                        // crewSchedule.
                        insert crewSchedulesList;
                    }

                }

            }
        }
    }

    global void finish(Database.BatchableContext dbc){
        

          BM_25_OP_FT_Schedule batch = new BM_25_OP_FT_Schedule();
         batch.startDate = startDate;
          batch.endDate = endDate;
        if (!Test.isRunningTest()){
         	Database.executeBatch(batch, 1);
        }
    }

}