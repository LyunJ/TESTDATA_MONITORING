-- create procedure
# DELIMITER ;;
# CREATE PROCEDURE td_user (IN insert_num INTEGER)
# BEGIN
#     DECLARE i INTEGER DEFAULT 1;
#     DECLARE cnt INTEGER DEFAULT 0;
#     SET i = (SELECT MAX(id) FROM user);
#     SET cnt = insert_num + i;
#     START TRANSACTION;
#     WHILE i < cnt DO
#         -- user table insert
#         INSERT IGNORE INTO user
#             (id, status, name, email, password)
#                 values
#                     (i,'ACTIVATE',CONCAT('N',i),CONCAT('email',i,'@email.com'),MD5(CONCAT('PASSWORD',i)));
#         -- user_profile table insert
#         INSERT IGNORE INTO user_profile (id, user_id, nick, phone_num, gender, image_url, background_url)
#         values (i, i, CONCAT('NICK', i), CONCAT('010-', LPAD((i/10000) % 10000,4,'0'),'-', LPAD((i % 10000),4,'0')), IF((i % 2) = 0, 'M', 'F'), CONCAT('IMAGE_URL_', i), CONCAT('BACKGROUND_URL_', i));
#         SET i = i + 1;
#         end while ;
#     COMMIT;
# end ;;
# DELIMITER ;

-- user table auto_increment reset
# ALTER TABLE user AUTO_INCREMENT=1;
-- user_profile table auto_increment reset
# ALTER TABLE user_profile AUTO_INCREMENT=1;
-- td_user procedure drop
# DROP PROCEDURE td_user;

-- foreign key check OFF
# SET foreign_key_checks = OFF;
# SET foreign_key_checks = ON;
-- user table truncate
# TRUNCATE TABLE `user`;
-- user_profile table truncate
# TRUNCATE TABLE user_profile;

-- procedure call
call td_user(1000000);