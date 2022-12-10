-- CREATE PROCEDURE
DELIMITER ;;
CREATE PROCEDURE cursor_process_2(IN sleep_time INTEGER, IN sleep_active_count INTEGER)
BEGIN
    DECLARE v_name VARCHAR(10);
    DECLARE v_email VARCHAR(100);
    DECLARE v_counter INTEGER DEFAULT 0;

    -- CURSOR 종료 조건 변수 생성
    DECLARE done BOOLEAN DEFAULT FALSE;

    -- USER 테이블을 조회할 CURSOR 정의 및 조회 완료 후 핸들러 정의
    DECLARE cursor_select_user CURSOR FOR SELECT `name`,`email` FROM user ORDER BY RAND() LIMIT 1;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- LOOP 내부에서 CURSOR OPEN
    cursor_loop : LOOP
        OPEN cursor_select_user;
        FETCH cursor_select_user INTO v_name,v_email;
        CLOSE cursor_select_user;

        -- SLEEP 함수 실행
        IF v_counter = sleep_active_count THEN
            DO sleep(sleep_time);
            LEAVE cursor_loop;
        end if;
        -- counter 변수 증가
        SET v_counter = v_counter + 1;
    end loop;
end;;
DELIMITER ;

CALL cursor_process(30,100);
CALL cursor_process_2(30,100);
