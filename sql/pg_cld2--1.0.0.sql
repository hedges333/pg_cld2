CREATE TYPE pg_cld2_language_detection AS (
    language_code       TEXT,
    percent             INTEGER,
    normalized_score    DOUBLE PRECISION,
    is_reliable         BOOLEAN
    valid_prefix_bytes  INTEGER,
    flags               INTEGER
);

CREATE FUNCTION pg_cld2_detect_language(text) RETURNS text
AS 'MODULE_PATHNAME', 'pg_cld2_detect_language'
LANGUAGE C STRICT;
