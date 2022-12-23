BEGIN;
SELECT * FROM user where id > 500000 for update;
COMMIT ;