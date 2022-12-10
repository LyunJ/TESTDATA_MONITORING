-- create chatroom dummy insert procedure
# DELIMITER ;;
# CREATE PROCEDURE td_chatroom(IN chatroom_num INTEGER)
# BEGIN
#     DECLARE i INTEGER DEFAULT 1;
#     DECLARE j INTEGER DEFAULT 0;
#     DECLARE cnt INTEGER DEFAULT 0;
#     DECLARE user_max_id INTEGER DEFAULT 0;
#     DECLARE chatroom_user_count INTEGER DEFAULT 0;
#     DECLARE random_user_id INTEGER DEFAULT 1;
#
#     DECLARE random_user_id_duplicate CONDITION FOR SQLSTATE '23000';
#     DECLARE CONTINUE HANDLER FOR random_user_id_duplicate
#         BEGIN
#             SET random_user_id = (FLOOR(RAND()*user_max_id));
#         end ;
#
#     SET i = (SELECT IFNULL(MAX(id)+1,1) FROM chatroom);
#     SET cnt = i + chatroom_num;
#     SET user_max_id = (SELECT IFNULL(MAX(id),1) FROM user);
#
#     START TRANSACTION;
#     WHILE i < cnt DO
#         SET chatroom_user_count = (FLOOR(RAND()*200));
#         INSERT INTO chatroom (id, user_count) VALUES (i,chatroom_user_count);
#
#         WHILE j < chatroom_user_count DO
#             SET random_user_id = (FLOOR(RAND()*user_max_id));
#             INSERT INTO chatroom_member (chatroom_id, user_id) values (i,random_user_id);
#             SET j = j + 1;
#             end while;
#         SET j = 0;
#
#         SET i = i + 1;
#         end while;
#     COMMIT;
# end;;
# DELIMITER ;

CALL td_chatroom(1000);