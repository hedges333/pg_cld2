CREATE DATABASE pg_cld2_test_db;
\c pg_cld2_test_db;
CREATE SCHEMA test_schema;
CREATE EXTENSION pg_cld2 SCHEMA test_schema;
SET search_path TO test_schema;
SELECT "testing 1 2 3 mic check" AS mic_check;
DROP DATABASE pg_cld2_test_db;
