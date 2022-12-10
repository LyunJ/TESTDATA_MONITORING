-- create function
CREATE FUNCTION fn_random_chatroom_select ()
BEGIN
    RETURN (select chatroom_id,user_id FROM chatroom_member ORDER BY RAND() LIMIT 1);
end;