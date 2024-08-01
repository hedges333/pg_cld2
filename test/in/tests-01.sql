SELECT "testing 1 2 3 mic check" AS mic_check;
\c regression;
\echo creating schema
CREATE SCHEMA test_schema;
\echo setting search_path
SET search_path TO test_schema;
\echo creating extension
CREATE EXTENSION pg_cld2 SCHEMA test_schema;
