create table chatroom
(
    id         int auto_increment
        primary key,
    user_count int       default 0                 not null,
    create_dt  timestamp default CURRENT_TIMESTAMP not null
);

create table t1
(
    s1 varchar(20) not null
);

create table user
(
    id        int auto_increment
        primary key,
    status    enum ('ACTIVATE', 'DEACTIVATE')     not null,
    name      varchar(10)                         not null,
    email     varchar(30)                         not null comment 'ID 역할',
    password  char(32)                            not null,
    create_dt timestamp default CURRENT_TIMESTAMP not null,
    update_dt timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
    delete_dt timestamp                           null comment '유저 삭제 시 삭제 일시 기록'
);

create table chatroom_member
(
    chatroom_id int                                 not null,
    user_id     int                                 not null,
    create_dt   timestamp default CURRENT_TIMESTAMP not null,
    primary key (chatroom_id, user_id),
    constraint chatroom_member_ibfk_1
        foreign key (chatroom_id) references chatroom (id),
    constraint chatroom_member_ibfk_2
        foreign key (user_id) references user (id)
);

create table chat
(
    id          int auto_increment
        primary key,
    chatroom_id int                                     not null,
    user_id     int                                     not null,
    content     varchar(1000) default ''                not null,
    create_dt   timestamp     default CURRENT_TIMESTAMP not null,
    constraint chat_ibfk_1
        foreign key (chatroom_id, user_id) references chatroom_member (chatroom_id, user_id)
);

create index chatroom_id
    on chat (chatroom_id, user_id);

create index user_id
    on chatroom_member (user_id);

create table friend
(
    id        int auto_increment
        primary key,
    user_id   int                                 not null,
    friend_id int                                 not null,
    create_dt timestamp default CURRENT_TIMESTAMP not null,
    constraint friend_ibfk_1
        foreign key (user_id) references user (id),
    constraint friend_ibfk_2
        foreign key (friend_id) references user (id)
);

create index friend_id
    on friend (friend_id);

create index user_id
    on friend (user_id);

create index user_email_index
    on user (email);

create index user_name_email_index
    on user (name, email);

create index user_name_index
    on user (name);

create table user_profile
(
    id             int auto_increment
        primary key,
    user_id        int              not null,
    nick           char(12)         not null,
    phone_num      varchar(15)      not null,
    gender         char default 'M' not null,
    image_url      varchar(500)     null,
    background_url varchar(500)     null,
    constraint user_profile_ibfk_1
        foreign key (user_id) references user (id)
);

create index user_id
    on user_profile (user_id);

create
    definer = root@localhost procedure cursor_process(IN sleep_time int, IN sleep_active_count int)
BEGIN
    DECLARE v_name VARCHAR(10);
    DECLARE v_email VARCHAR(100);
    DECLARE v_counter INTEGER DEFAULT 0;

    -- CURSOR 종료 조건 변수 생성
    DECLARE done BOOLEAN DEFAULT FALSE;

    -- USER 테이블을 조회할 CURSOR 정의 및 조회 완료 후 핸들러 정의
    DECLARE cursor_select_user CURSOR FOR SELECT `name`,`email` FROM user LIMIT 1000;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cursor_select_user;
    cursor_loop : LOOP
        FETCH cursor_select_user INTO v_name,v_email;

        -- SLEEP 함수 실행
        IF v_counter = sleep_active_count THEN
            DO sleep(sleep_time);
        end if;

        -- counter 변수 증가
        SET v_counter = v_counter + 1;
        -- LOOP 종료 조건
        if done = TRUE THEN
            LEAVE cursor_loop;
        end if;
    end loop;
    CLOSE cursor_select_user;
end;

create
    definer = root@localhost procedure cursor_process_2(IN sleep_time int, IN sleep_active_count int)
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
        end if;
        -- LOOP 종료 조건
        if v_counter=sleep_active_count THEN
            LEAVE cursor_loop;
        end if;
        -- counter 변수 증가
        SET v_counter = v_counter + 1;
    end loop;
end;

create
    definer = root@localhost procedure sp_test(IN val int)
BEGIN
        DECLARE CONTINUE HANDLER FOR 1364, 1048, 1366
            BEGIN
                INSERT IGNORE INTO t1 VALUES('SOME STRING');
                GET STACKED DIAGNOSTICS CONDITION 1 @stacked_state = RETURNED_SQLSTATE ;
                GET STACKED DIAGNOSTICS CONDITION 1 @stacked_msg = MESSAGE_TEXT ;
            end;
        INSERT INTO t1 VALUES (val);
    end;

create
    definer = root@localhost procedure td_chat(IN chat_num int)
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

create
    definer = root@localhost procedure td_chatroom(IN chatroom_num int)
BEGIN
    DECLARE i INTEGER DEFAULT 1;
    DECLARE j INTEGER DEFAULT 0;
    DECLARE cnt INTEGER DEFAULT 0;
    DECLARE user_max_id INTEGER DEFAULT 0;
    DECLARE chatroom_user_count INTEGER DEFAULT 0;
    DECLARE random_user_id INTEGER DEFAULT 1;

    DECLARE random_user_id_duplicate CONDITION FOR SQLSTATE '23000';
    DECLARE CONTINUE HANDLER FOR random_user_id_duplicate
        BEGIN
            SET random_user_id = (FLOOR(RAND()*user_max_id));
        end ;

    SET i = (SELECT IFNULL(MAX(id)+1,1) FROM chatroom);
    SET cnt = i + chatroom_num;
    SET user_max_id = (SELECT IFNULL(MAX(id),1) FROM user);

    START TRANSACTION;
    WHILE i < cnt DO
        SET chatroom_user_count = (FLOOR(RAND()*200));
        INSERT INTO chatroom (id, user_count) VALUES (i,chatroom_user_count);

        WHILE j < chatroom_user_count DO
            SET random_user_id = (FLOOR(RAND()*user_max_id));
            INSERT INTO chatroom_member (chatroom_id, user_id) values (i,random_user_id);
            SET j = j + 1;
            end while;
        SET j = 0;

        SET i = i + 1;
        end while;
    COMMIT;
end;

create
    definer = root@localhost procedure td_friend(IN friend_num int)
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
end;

create
    definer = root@localhost procedure td_user(IN insert_num int)
BEGIN
    DECLARE i INTEGER DEFAULT 1;
    DECLARE cnt INTEGER DEFAULT 0;
    SET i = (SELECT MAX(id) FROM user);
    SET cnt = insert_num + i;
    START TRANSACTION;
    WHILE i < cnt DO
        -- user table insert
        INSERT IGNORE INTO user
            (id, status, name, email, password)
                values
                    (i,'ACTIVATE',CONCAT('N',i),CONCAT('email',i,'@email.com'),MD5(CONCAT('PASSWORD',i)));
        -- user_profile table insert
        INSERT IGNORE INTO user_profile (id, user_id, nick, phone_num, gender, image_url, background_url)
        values (i, i, CONCAT('NICK', i), CONCAT('010-', LPAD((i/10000) % 10000,4,'0'),'-', LPAD((i % 10000),4,'0')), IF((i % 2) = 0, 'M', 'F'), CONCAT('IMAGE_URL_', i), CONCAT('BACKGROUND_URL_', i));
        SET i = i + 1;
        end while ;
    COMMIT;
end;
