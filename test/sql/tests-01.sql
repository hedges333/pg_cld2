SELECT 'testing 1 2 3 mic check' AS mic_check;

CREATE SCHEMA test_schema;

SET search_path TO test_schema;

CREATE EXTENSION pg_cld2 SCHEMA test_schema;

SELECT 'again testing 1 2 3 mic check' AS mic_check;
