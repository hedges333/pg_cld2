\set sample_tsv `pwd`/test/sql/sample_data.tsv

CREATE SCHEMA test_schema;

SET search_path TO test_schema;

CREATE EXTENSION pg_cld2 SCHEMA test_schema;

CREATE TABLE sample_text (
    id                  INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    text_to_analyze         TEXT    NOT NULL,
    is_plain_text           BOOLEAN,
    content_language_hint   TEXT,
    tld_hint                TEXT,
    cld2_language_hint      TEXT,
    best_effort             BOOLEAN,
    text_encoding           TEXT,
    tsconfig_language_hint  TEXT,
    locale_lang_hint        TEXT
);

COPY sample_text(
    text_to_analyze,
    is_plain_text,
    content_language_hint,
    tld_hint,
    cld2_language_hint,
    best_effort,
    text_encoding,
    tsconfig_language_hint,
    locale_lang_hint
)
FROM :'sample_tsv'
WITH (FORMAT csv, DELIMITER E'\t', HEADER false);


CREATE OR REPLACE FUNCTION process_sample_texts()
RETURNS TABLE (
    sample_text_id                          INTEGER,
    sample_text_text_to_analyze_substr      TEXT,
    sample_text_is_plain_text               BOOLEAN,
    sample_text_content_language_hint       TEXT,
    sample_text_tld_hint                    TEXT,
    sample_text_cld2_language_hint          TEXT,
    sample_text_best_effort                 BOOLEAN,
    sample_text_text_encoding               TEXT,
    sample_text_tsconfig_language_hint      TEXT,
    sample_text_locale_lang_hint            TEXT,
    pg_cld2_input_bytes                     INTEGER,
    pg_cld2_text_bytes                      INTEGER,
    pg_cld2_is_reliable                     BOOLEAN,
    pg_cld2_valid_prefix_bytes              INTEGER,
    pg_cld2_is_valid_utf8                   BOOLEAN,
    pg_cld2_mll_cld2_name                   TEXT,
    pg_cld2_mll_language_cname              TEXT,
    pg_cld2_mll_language_code               TEXT,
    pg_cld2_mll_script_name                 TEXT,
    pg_cld2_mll_script_code                 TEXT,
    pg_cld2_mll_ts_name                     TEXT,
    pg_cld2_language_1_cld2_name            TEXT,
    pg_cld2_language_1_language_cname       TEXT,
    pg_cld2_language_1_language_code        TEXT,
    pg_cld2_language_1_script_name          TEXT,
    pg_cld2_language_1_script_code          TEXT,
    pg_cld2_language_1_percent              INTEGER,
    pg_cld2_language_1_normalized_score     DOUBLE PRECISION,
    pg_cld2_language_1_ts_name              TEXT,
    pg_cld2_language_2_cld2_name            TEXT,
    pg_cld2_language_2_language_cname       TEXT,
    pg_cld2_language_2_language_code        TEXT,
    pg_cld2_language_2_script_name          TEXT,
    pg_cld2_language_2_script_code          TEXT,
    pg_cld2_language_2_percent              INTEGER,
    pg_cld2_language_2_normalized_score     DOUBLE PRECISION,
    pg_cld2_language_2_ts_name              TEXT,
    pg_cld2_language_3_cld2_name            TEXT,
    pg_cld2_language_3_language_cname       TEXT,
    pg_cld2_language_3_language_code        TEXT,
    pg_cld2_language_3_script_name          TEXT,
    pg_cld2_language_3_script_code          TEXT,
    pg_cld2_language_3_percent              INTEGER,
    pg_cld2_language_3_normalized_score     DOUBLE PRECISION,
    pg_cld2_language_3_ts_name              TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        sample_text_rec.id,
        SUBSTRING(sample_text_rec.text_to_analyze FOR 32),
        sample_text_rec.is_plain_text,
        sample_text_rec.content_language_hint,
        sample_text_rec.tld_hint,
        sample_text_rec.cld2_language_hint,
        sample_text_rec.best_effort,
        sample_text_rec.text_encoding,
        sample_text_rec.tsconfig_language_hint,
        sample_text_rec.locale_lang_hint,
        result.input_bytes,
        result.text_bytes,
        result.is_reliable,
        result.valid_prefix_bytes,
        result.is_valid_utf8,
        result.mll_cld2_name,
        result.mll_language_cname,
        result.mll_language_code,
        result.mll_script_name,
        result.mll_script_code,
        result.mll_ts_name,
        result.language_1_cld2_name,
        result.language_1_language_cname,
        result.language_1_language_code,
        result.language_1_script_name,
        result.language_1_script_code,
        result.language_1_percent,
        result.language_1_normalized_score,
        result.language_1_ts_name,
        result.language_2_cld2_name,
        result.language_2_language_cname,
        result.language_2_language_code,
        result.language_2_script_name,
        result.language_2_script_code,
        result.language_2_percent,
        result.language_2_normalized_score,
        result.language_2_ts_name,
        result.language_3_cld2_name,
        result.language_3_language_cname,
        result.language_3_language_code,
        result.language_3_script_name,
        result.language_3_script_code,
        result.language_3_percent,
        result.language_3_normalized_score,
        result.language_3_ts_name
    FROM sample_text sample_text_rec,
    LATERAL (
        SELECT * FROM pg_cld2_detect_language(
            sample_text_rec.text_to_analyze,
            sample_text_rec.is_plain_text,
            sample_text_rec.content_language_hint,
            sample_text_rec.tld_hint,
            sample_text_rec.cld2_language_hint,
            sample_text_rec.best_effort,
            sample_text_rec.text_encoding,
            sample_text_rec.tsconfig_language_hint,
            sample_text_rec.locale_lang_hint
        ) AS t (
            input_bytes                 INTEGER,
            text_bytes                  INTEGER,
            is_reliable                 BOOLEAN,
            valid_prefix_bytes          INTEGER,
            is_valid_utf8               BOOLEAN,
            mll_cld2_name               TEXT,
            mll_language_cname          TEXT,
            mll_language_code           TEXT,
            mll_script_name             TEXT,
            mll_script_code             TEXT,
            mll_ts_name                 TEXT,
            language_1_cld2_name        TEXT,
            language_1_language_cname   TEXT,
            language_1_language_code    TEXT,
            language_1_script_name      TEXT,
            language_1_script_code      TEXT,
            language_1_percent          INTEGER,
            language_1_normalized_score DOUBLE PRECISION,
            language_1_ts_name          TEXT,
            language_2_cld2_name        TEXT,
            language_2_language_cname   TEXT,
            language_2_language_code    TEXT,
            language_2_script_name      TEXT,
            language_2_script_code      TEXT,
            language_2_percent          INTEGER,
            language_2_normalized_score DOUBLE PRECISION,
            language_2_ts_name          TEXT,
            language_3_cld2_name        TEXT,
            language_3_language_cname   TEXT,
            language_3_language_code    TEXT,
            language_3_script_name      TEXT,
            language_3_script_code      TEXT,
            language_3_percent          INTEGER,
            language_3_normalized_score DOUBLE PRECISION,
            language_3_ts_name          TEXT
        )
    ) AS result;
END;
$$ LANGUAGE plpgsql;

SELECT * from process_sample_texts();

