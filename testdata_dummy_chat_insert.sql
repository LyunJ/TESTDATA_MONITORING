-- create procedure
CREATE PROCEDURE td_chat(IN chat_num INTEGER)
BEGIN
    DECLARE v_i INTEGER DEFAULT 0;
    DECLARE v_chatroom_id INTEGER DEFAULT 1;
    DECLARE v_user_id INTEGER DEFAULT 1;

    DECLARE v_rand_chatroom_member CURSOR FOR
    SELECT chatroom_id,user_id FROM chatroom_member ORDER BY RAND() LIMIT 1;

    START TRANSACTION;
    WHILE v_i < chat_num DO
        OPEN v_rand_chatroom_member;
        FETCH v_rand_chatroom_member INTO v_chatroom_id, v_user_id;
        CLOSE v_rand_chatroom_member;

        INSERT INTO chat (chatroom_id, user_id, content)
        VALUES (v_chatroom_id, v_user_id, CONCAT('CONTENT',v_i));

        SET v_i = v_i + 1;
        END WHILE;
    COMMIT;
end;

-- CALL PROCEDURE
CALL td_chat(10000);