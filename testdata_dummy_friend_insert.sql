-- create procedure
DELIMITER ;;
CREATE PROCEDURE td_friend(IN friend_num INTEGER)
BEGIN
    DECLARE v_counter INTEGER DEFAULT 0;
    DECLARE v_user_max_id INTEGER DEFAULT 1;

    SET v_user_max_id = (SELECT IFNULL(MAX(id),1) FROM user);

    START TRANSACTION ;
    WHILE v_counter < friend_num DO
        INSERT IGNORE INTO friend (user_id, friend_id) VALUES (RAND() * v_user_max_id, RAND() * v_user_max_id);
        SET v_counter = v_counter + 1;
        end while;
    COMMIT;
end;;
DELIMITER ;

CALL td_friend(100000);