# 서버에 존재하는 모든 스레드
SELECT NAME, THREAD_ID, PROCESSLIST_ID, THREAD_OS_ID
FROM performance_schema.threads;

# 인스트루먼트 활성화
SELECT * FROM performance_schema.setup_instruments
WHERE NAME='statement/sql/select';

# 1
UPDATE performance_schema.setup_instruments
SET ENABLED='YES' WHERE NAME='statement/sql/select';

# 2
CALL sys.ps_setup_enable_instrument('statement/sql/select');

# 3
# 위의 두 방법은 서버를 재시작하면 저장되지 않으므로, 설정 파라미터의 performance-schema-instrument 파라미터를 사용하자
# performance-schema-instrument='statement/sql/select=ON'


# 특정 객체에 대한 모니터링 튜닝
# 트리거에 대해 performance_schema 비활성화
# 객체에 대한 설정 파일 옵션은 없기 때문에 init_file옵션을 사용해서 시작 시 SQL 파일을 로드해야한다
INSERT INTO performance_schema.setup_objects
(OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME, ENABLED)
VALUES ('TRIGGER','testdata','%','NO');

UPDATE performance_schema.setup_objects SET ENABLED='YES' WHERE OBJECT_SCHEMA='testdata' AND OBJECT_TYPE='TRIGGER' AND OBJECT_NAME='%';


# 스레드 모니터링 튜닝
# 특정 스레드에 대한 인스트루먼트 활성화 여부 지정
UPDATE performance_schema.setup_threads SET HISTORY='YES'
WHERE NAME='thread/sql/event_scheduler';

select * from performance_schema.setup_threads;

# SQL 문 점검
explain
select user.id
from user left join chat c on user.id = c.user_id
group by user.id;
select * from performance_schema.events_statements_history;

# 좋은 인덱스를 사용하지 않는 모드 쿼리 찾기
SELECT THREAD_ID, SQL_TEXT, ROWS_SENT, ROWS_EXAMINED, CREATED_TMP_TABLES, NO_INDEX_USED, NO_GOOD_INDEX_USED
FROM performance_schema.events_statements_history_long
WHERE NO_INDEX_USED > 0 OR NO_GOOD_INDEX_USED > 0;

SELECT THREAD_ID, SQL_TEXT, ROWS_SENT, ROWS_EXAMINED, CREATED_TMP_TABLES, NO_INDEX_USED, NO_GOOD_INDEX_USED
FROM performance_schema.events_statements_history_long
WHERE CREATED_TMP_TABLES > 0 OR CREATED_TMP_DISK_TABLES > 0;

# sys 스키마 이용
SELECT query, total_latency, no_index_used_count, rows_sent, rows_examined
FROM sys.statements_with_full_table_scans
WHERE db='testdata' AND query NOT LIKE '%performance_schema%';

SELECT * FROM sys.statement_analysis;

# prepared statement
SELECT * FROM performance_schema.setup_instruments
WHERE NAME IN ('statement/sql/prepare_sql', 'statement/sql/execute_sql', 'statement/com/Prepare', 'statement/com/Execute');

PREPARE stmt FROM
'SELECT COUNT(*) FROM user where id > ?';

SET @i=800000;

EXECUTE stmt USING @i;

SELECT statement_name, sql_text, owner_thread_id, count_reprepare, count_execute, sum_timer_execute
FROM performance_schema.prepared_statements_instances;
drop prepare stmt;

# STORED ROUTINE
-- stored routine instrument 활성화 확인
SELECT * FROM performance_schema.setup_instruments
WHERE NAME LIKE 'statement/sp%';

CREATE TABLE t1 (
    s1 varchar(20) not null
);
DELIMITER ;;
CREATE DEFINER='root'@'localhost' PROCEDURE sp_test (val int)
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1364, 1048, 1366
            BEGIN
                INSERT IGNORE INTO t1 VALUES('SOME STRING');
                GET STACKED DIAGNOSTICS CONDITION 1 @stacked_state = RETURNED_SQLSTATE ;
                GET STACKED DIAGNOSTICS CONDITION 1 @stacked_msg = MESSAGE_TEXT ;
            end;
        INSERT INTO t1 VALUES (val);
    end;;
DELIMITER ;
CALL sp_test(1);
CALL sp_test(NULL);

-- 루틴 내에서 호출되는 구문 및 프로시저, 루프, 기타제어명령의 이벤트 추적
SELECT THREAD_ID, EVENT_NAME, SQL_TEXT
FROM performance_schema.EVENTS_STATEMENTS_HISTORY
WHERE EVENT_NAME LIKE 'statement/sp%';


# 구문 프로파일링
-- 1초 이상 걸린 단계 검색
SELECT eshl.event_name,
       sql_text,
       eshl.timer_wait/10000000000 w_s
FROM performance_schema.events_stages_history_long eshl
JOIN performance_schema.events_statements_history_long esthl
ON (eshl.NESTING_EVENT_ID = esthl.event_id)
WHERE eshl.timer_wait > 1*10000000000;

# 읽기 대 쓰기 성능 점검
-- 호출된 횟수
SELECT EVENT_NAME, COUNT(EVENT_NAME)
FROM performance_schema.events_statements_history_long
GROUP BY EVENT_NAME;
-- 구문별 대기시간
SELECT EVENT_NAME, COUNT(EVENT_NAME), SUM(LOCK_TIME/1000000) AS latency_ms
FROM performance_schema.events_statements_history_long
GROUP BY EVENT_NAME ORDER BY latency_ms DESC;
-- 구문별 읽고 쓴 행의 바이트
WITH rows_read AS (SELECT SUM(VARIABLE_VALUE) AS rows_read
                   FROM performance_schema.global_status
                   WHERE VARIABLE_NAME IN ('Handler_read_first', 'Handler_read_key',
                                          'Handler_read_next', 'Handler_read_last', 'Handler_read_prev',
                                          'Handler_read_rnd','Handler_read_rnd_next')),
    rows_written AS (SELECT SUM(VARIABLE_VALUE) AS rows_written
                     FROM performance_schema.global_status
                     WHERE VARIABLE_NAME IN ('Handler_write'))
SELECT * FROM rows_read, rows_written;

# 메타데이터 잠금 점검
# metadata_locks 테이블은 현재 서로 다른 스레드에서 설정한 잠금에 대한 정보와
# 잠금을 기다리고 있는 잠금 요청에 대한 정보를 가지고 있다

SELECT THREAD_ID,PROCESSLIST_ID,object_type, lock_type, lock_status, source
FROM performance_schema.metadata_locks JOIN performance_schema.threads ON (OWNER_THREAD_ID=THREAD_ID)
WHERE object_schema='testdata' AND OBJECT_NAME='user';

show processlist ;

# 메모리 사용량 점검
-- innodb 메모리 사용량 점검
SELECT EVENT_NAME,
       CURRENT_NUMBER_OF_BYTES_USED/1024/1024 AS CURRENT_MB,
       HIGH_NUMBER_OF_BYTES_USED/1024/1024 AS HIGH_MB
FROM performance_schema.memory_summary_global_by_event_name
WHERE EVENT_NAME LIKE 'memory/innodb/%'
ORDER BY CURRENT_NUMBER_OF_BYTES_USED DESC LIMIT 10;

-- SYS 스키마 사용
SELECT * FROM sys.memory_global_total;
-- 메모리를 사용하는 스레드
SELECT thread_id tid, user, current_allocated ca, total_allocated
FROM sys.memory_by_thread_by_current_bytes LIMIT 9;
-- 메모리를 가장 많이 사용하는 사용자 스레드 찾기
SELECT * FROM sys.memory_by_thread_by_current_bytes
ORDER BY current_allocated desc;

# 변수 점검
-- 서로 다른 스레드에서 같은 변수명을 사용하고 있음을 확인 가능
SELECT * FROM performance_schema.variables_by_thread
where VARIABLE_VALUE like 'REPEATABLE-READ';

-- 현재 활성화된 세션과 다른 세션 변수 값을 가지는 모든 스레드
SELECT vt2.THREAD_ID AS TID, vt2.VARIABLE_NAME,
       vt1.VARIABLE_VALUE AS MY_VALUE ,
       vt2.VARIABLE_VALUE AS OTHER_VALUE
FROM performance_schema.variables_by_thread vt1
JOIN performance_schema.threads t USING (THREAD_ID)
JOIN performance_schema.variables_by_thread vt2 USING (VARIABLE_NAME)
WHERE vt1.VARIABLE_VALUE != vt2.VARIABLE_VALUE
AND t.PROCESSLIST_ID=@@pseudo_thread_id;

-- 스레드별 상태변수값 조회
SELECT * FROM performance_schema.status_by_thread
WHERE VARIABLE_NAME='Handler_write';

-- 사용자 정의 변수(@변수명)
SELECT * FROM performance_schema.user_variables_by_thread;

-- 서버가 시작된 후 동적으로 변경된 모든 변수 조회
SELECT * FROM performance_schema.variables_info
WHERE VARIABLE_SOURCE='DYNAMIC';

# 자주 발생하는 오류 점검
SHOW CREATE TABLE performance_schema.events_errors_summary_global_by_error;

-- 오류를 10번 이상 발생시킨 구문을 실행한 모든 계정을 조회
SELECT * FROM performance_schema.events_errors_summary_by_account_by_error
WHERE SUM_ERROR_RAISED > 10 AND USER IS NOT NULL
ORDER BY SUM_ERROR_RAISED DESC;

# 성능 스키마 자체 점검
SELECT SUBSTRING_INDEX(EVENT_NAME, '/', -1) AS EVENT,
       CURRENT_NUMBER_OF_BYTES_USED/1024/1024 AS CURRENT_MB,
       HIGH_NUMBER_OF_BYTES_USED/1024/1024 AS HIGH_MB
FROM performance_schema.memory_summary_global_by_event_name
WHERE EVENT_NAME LIKE 'memory/performance_schema/%'
ORDER BY CURRENT_NUMBER_OF_BYTES_USED DESC LIMIT 10;