CREATE TYPE pg_cld2_language_detection AS (
    input_bytes                     INTEGER,            -- length of original text (after conversion to utf8)
    text_bytes                      INTEGER,            -- non-markup bytes
    is_reliable                     BOOLEAN,            -- CLD2's guess
    valid_prefix_bytes              INTEGER,            -- if != input_bytes: invalid UTF8 after that byte

    mll_cld2_name                   VARCHAR(255),       -- first language name, e.g. "ENGLISH" or "NEPALI"
    mll_language_cname              VARCHAR(255),       -- language name, e.g. "ENGLISH" or "NEPALI" (only minor differences)
    mll_language_code               VARCHAR(255),       -- language code, e.g. "en" or "ne"
    mll_script_name                 VARCHAR(255),       -- script name, e.g. "Latin" or "Devanagari"
    mll_script_code                 VARCHAR(255),       -- script code, e.g. "Latn" or "Deva"
    mll_ts_name                     VARCHAR(255),       -- guess from pg_catalog.pg_ts_config, e.g. "english" or "nepali"

    language_1_cld2_name            VARCHAR(255),       -- first language name, e.g. "ENGLISH" or "NEPALI"
    language_1_language_cname       VARCHAR(255),       -- language name, e.g. "ENGLISH" or "NEPALI" (only minor differences)
    language_1_language_code        VARCHAR(255),       -- language code, e.g. "en" or "ne"
    language_1_script_name          VARCHAR(255),       -- script name, e.g. "Latin" or "Devanagari"
    language_1_script_code          VARCHAR(255),       -- script code, e.g. "Latn" or "Deva"
    language_1_percent              SMALLINT,           -- how likely this language is
    language_1_normalized_score     DOUBLE PRECISION,   -- mumble mumble
    language_1_ts_name              VARCHAR(255),       -- guess from pg_catalog.pg_ts_config, e.g. "english" or "nepali"

    language_2_cld2_name            VARCHAR(255),       -- second likely language name
    language_2_language_cname       VARCHAR(255),       -- etc.
    language_2_language_code        VARCHAR(255),
    language_2_script_name          VARCHAR(255),
    language_2_script_code          VARCHAR(255),
    language_2_percent              SMALLINT,
    language_2_normalized_score     DOUBLE PRECISION,
    language_2_ts_name              VARCHAR(255),

    language_3_cld2_name            VARCHAR(255),       -- third likely language name
    language_3_language_cname       VARCHAR(255),       -- etc.
    language_3_language_code        VARCHAR(255),
    language_3_script_name          VARCHAR(255),
    language_3_script_code          VARCHAR(255),
    language_3_percent              SMALLINT,
    language_3_normalized_score     DOUBLE PRECISION,
    language_3_ts_name              VARCHAR(255)

);

CREATE FUNCTION pg_cld2_detect_language_internal(
    INOUT text
) RETURNS pg_cld2_language_detection
AS 'MODULE_PATHNAME', 'pg_cld2_detect_language_internal'
LANGUAGE C STRICT;


CREATE FUNCTION pg_cld2_usage()
    IMMUTABLE STRICT
    PARALLEL SAFE
    LANGUAGE plpgsql
    RETURNS TEXT
AS $$
BEGIN;
    RETURN E'usage:\n'
    || E'DECLARE\n'
    || E'  return_record pg_cld2_language_detection;\n'
    || E'BEGIN\n'
    || E'  PERFORM pg_cld2_detect_language(\n'
    || E'    return_record,           -- instance of pg_cld2_language_detection composite type\n'
    || E'    text_to_analyze,         -- required\n'
    || E'    is_plain_text,           -- boolean, default true. Parses HTML if false\n'
    || E'    content_language_hint,   -- text. Ex: "mi,en" boosts Maori & English\n'
    || E'    tld_hint,                -- text. Ex: "id" boosts Indonesian\n'
    || E'    cld2_language_hint,      -- text, default NULL. Ex: "ITALIAN" boosts it. See pg_cld2_languages table.\n'
    || E'    best_effort,             -- boolean, default true. Gives best-effort answer for short text instead of UNKNOWN.\n'
    || E'    text_encoding,           -- text, default UTF8, will copy string if not, also sets encoding hint\n'
    || E'    tsconfig_language_hint,  -- text, default NULL. Looks up in pg_cld2_languages table, overrides cld2_language_hint.\n'
    || E'    locale_hint              -- text, 1st 2 chars, overrides tld_hint.\n'
    || E'  );\n'
    || E'  RAISE NOTICE ''language is %%'', return_record.language_1_pg_name;\n'
    || E'  -- See "\d pg_cld2_language_detection" for the return_record field names.'
    ;
END;
$$;

-- NOTE see SELECT pg_encoding_to_char(encoding) AS encoding_name FROM pg_catalog.pg_encoding; for list of PG encodings

-- To avoid copying a giant string of text to analyze, it is passed as an INOUT param.
-- That means it cannot have a return value.
-- So the caller needs to create an instance of pg_cld2_language_detection ENUM type first,
-- and pass that as a parameter.
CREATE FUNCTION pg_cld2_detect_language(
    INOUT   return_record           pg_cld2_language_detection,     -- For the result values
    INOUT   text_to_analyze         TEXT,                           -- Pass as pointer
    IN      is_plain_text           BOOLEAN DEFAULT TRUE,           -- NULL or TRUE = TRUE; FALSE = FALSE
    IN      content_language_hint   TEXT DEFAULT NULL,
    IN      tld_hint                TEXT DEFAULT NULL,
    IN      cld2_language_hint      TEXT DEFAULT NULL,
    IN      best_effort             BOOLEAN DEFAULT TRUE,           -- NULL or TRUE = TRUE; FALSE = FALSE
    IN      text_encoding           VARCHAR(32) DEFAULT 'UTF8',     -- the Postgres encoding name
    IN      tsconfig_language_hint  TEXT DEFAULT NULL,
    IN      locale_lang_hint        TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS
$$
DECLARE
    encoding_hint           INTEGER DEFAULT NULL;
    lang_from_locale        VARCHAR(4) DEFAULT NULL;
BEGIN

    -- check parameters
    IF text_to_analyze  IS NULL
    OR return_record    IS NULL
    THEN
        RAISE EXCEPTION pg_cld2_usage();
    END IF;

    IF (tsconfig_language_hint IS NOT NULL) THEN
        cld2_language_hint := UPPER(tsconfig_language_hint);
        IF (cld2_language_hint = 'SIMPLE') THEN
            cld2_language_hint := NULL;  -- could be UNKNOWN_LANGUAGE but same diff
        END IF;
    END IF;

    IF (locale_lang_hint IS NOT NULL) THEN
        -- select the first letters substring and put into content_language_hint
        lang_from_locale := SUBSTRING(locale_lang_hint) FROM '([^_]+)';

        IF content_language_hint IS NULL THEN
            content_language_hint = lang_from_locale;
        ELSE
            content_language_hint = content_language_hint || ',' || lang_from_locale;
        END IF;
    END IF;

    -- ensure conversion to utf8
    IF text_encoding != 'UTF8' THEN
        text_to_analyze := convert(text_to_analyze, 'UTF8', text_encoding);

        -- We still send the original encoding as a hint,
        -- transliterated into the constant value that CLD2 uses
        -- (probably-ish)
        SELECT cld2_const_value
            INTO    encoding_hint
            FROM    pg_cld2_encodings
            WHERE   pg_encoding_name = text_encoding;
        -- or leave it NULL if not found
    END IF;

    -- return the result of the C call
    SELECT pg_cld2_detect_language_internal(
        text_to_analyze,        -- text
        is_plain_text,          -- boolean
        content_language_hint,  -- text
        tld_hint,               -- text
        cld2_language_hint,     -- text
        encoding_hint,          -- int
        best_effort             -- boolean
    ) INTO return_record;
        -- return_record.language_1_cld2_name,
        -- return_record.language_1_code,
        -- return_record.language_1_script,
        -- return_record.language_1_percent,
        -- return_record.language_1_normalized_score,
        -- return_record.language_2_cld2_name,
        -- return_record.language_2_code,
        -- return_record.language_2_script,
        -- return_record.language_2_percent,
        -- return_record.language_2_normalized_score,
        -- return_record.language_3_cld2_name,
        -- return_record.language_3_code,
        -- return_record.language_3_script,
        -- return_record.language_3_percent,
        -- return_record.language_3_normalized_score,
        -- return_record.text_bytes,
        -- return_record.is_reliable,
        -- return_record.valid_prefix_bytes;

    -- now figure out the language pg_name's from the cld2 name or code
    SELECT cfgname
        INTO return_record.mll_ts_name
        FROM    pg_catalog.pg_ts_config
        WHERE   cfgname = LOWER( return_record.mll_cld2_name );
    IF NOT FOUND THEN
        return_record.mll_ts_name = 'simple';
    END IF;

    SELECT cfgname
        INTO    return_record.language_1_ts_name
        FROM    pg_catalog.pg_ts_config
        WHERE   cfgname = LOWER( return_record.language_1_cld2_name );
    IF NOT FOUND THEN
        return_record.language_1_ts_name = 'simple';
    END IF;

    SELECT cfgname
        INTO    return_record.language_2_ts_name
        FROM    pg_catalog.pg_ts_config
        WHERE   cfgname = LOWER( return_record.language_2_cld2_name );
    IF NOT FOUND THEN
        return_record.language_2_ts_name = 'simple';
    END IF;

    SELECT cfgname
        INTO    return_record.language_3_ts_name
        FROM    pg_catalog.pg_ts_config
        WHERE   cfgname = LOWER( return_record.language_3_cld2_name );
    IF NOT FOUND THEN
        return_record.language_3_ts_name = 'simple';
    END IF;

    RETURN;
END;
$$;


CREATE TABLE IF NOT EXISTS pg_cld2_encodings (
    cld2_encoding_name  VARCHAR(32)         NOT NULL,
    pg_encoding_name    VARCHAR(32),
    cld2_const_value    SMALLINT            NOT NULL,
    notes               VARCHAR(255),

    PRIMARY KEY (cld2_encoding_name),
    UNIQUE (cld2_const_value)
);

INSERT INTO pg_cld2_encodings VALUES
('ISO_8859_1', 'LATIN1', 0, 'ASCII'),
('ISO_8859_2', 'LATIN2', 1, 'Latin2'),
('ISO_8859_4', 'LATIN4', 3, 'Latin4'),
('ISO_8859_5', 'ISO_8859_5', 4, 'ISO-8859-5'),
('ISO_8859_6', 'ISO_8859_6', 5, 'Arabic'),
('ISO_8859_7', 'ISO_8859_7', 6, 'Greek'),
('ISO_8859_8', 'ISO_8859_8', 7, 'Hebrew'),
('JAPANESE_EUC_JP', 'EUC_JP', 10, 'EUC_JP'),
('JAPANESE_SHIFT_JIS', 'SJIS', 11, 'SJS'),
('JAPANESE_JIS', 'EUC_JIS_2004', 12, 'JIS, probably'),
('CHINESE_BIG5', 'BIG5', 13, 'BIG5'),
('CHINESE_GB', 'GB18030', 14, 'GB'),
('CHINESE_EUC_CN', 'EUC_TW', 15, 'Misnamed. Should be EUC_TW. Was Basis Tech CNS11643EUC, before that EUC-CN(!)'),
('KOREAN_EUC_KR', 'EUC_KR', 16, 'KSC'),
('UNICODE_UNUSED', 'UTF8', 17, 'Unicode'),
('CHINESE_EUC_DEC', 'EUC_TW', 18, 'Misnamed. Should be EUC_TW. Was CNS11643EUC, before that EUC.'),
('CHINESE_CNS', 'EUC_TW', 19, 'Misnamed. Should be EUC_TW. Was CNS11643EUC, before that CNS.'),
('CHINESE_BIG5_CP950', 'BIG5', 20, 'BIG5_CP950'),
('JAPANESE_CP932', 'SJIS', 21, 'CP932'),
('UTF8', 'UTF8', 22, NULL),
('UNKNOWN_ENCODING', 'SQL_ASCII', 23, NULL),
('ASCII_7BIT', 'LATIN1', 24, 'ISO_8859_1 with all characters <= 127.'),
('RUSSIAN_KOI8_R', 'KOI8R', 25, 'KOI8R'),
('RUSSIAN_CP1251', 'WIN1251', 26, 'CP1251'),
('MSFT_CP1252', 'WIN1252', 27, '27: CP1252 aka MSFT euro ascii'),
('RUSSIAN_KOI8_RU', 'KOI8U', 28, 'CP21866 aka KOI8-U, used for Ukrainian. Misnamed, this is _not_ KOI8-RU but KOI8-U. KOI8-U is used much more often than KOI8-RU.'),
('MSFT_CP1250', 'WIN1250', 29, 'CP1250 aka MSFT eastern european'),
('ISO_8859_15', 'LATIN9', 30, 'aka ISO_8859_0 aka ISO_8859_1 euroized'),
('MSFT_CP1254', 'WIN1254', 31, 'used for Turkish'),
('MSFT_CP1257', 'WIN1257', 32, 'used in Baltic countries'),
('ISO_8859_11', NULL, 33, 'aka TIS-620, used for Thai - "not supported yet"'),
('MSFT_CP874', 'WIN874', 34, 'used for Thai'),
('MSFT_CP1256', 'WIN1256', 35, 'used for Arabic'),
('MSFT_CP1255', 'WIN1255', 36, 'Logical Hebrew Microsoft'),
('ISO_8859_8_I', 'ISO_8859_8', 37, 'Iso Hebrew Logical - guess'),
('HEBREW_VISUAL', NULL, 38, 'Iso Hebrew Visual - no idea'),
('CZECH_CP852', NULL, 39, 'no idea'),
('CZECH_CSN_369103', NULL, 40, 'aka ISO_IR_139 aka KOI8_CS - no idea'),
('MSFT_CP1253', 'WIN1253', 41, 'used for Greek'),
('RUSSIAN_CP866', 'WIN866', 42, NULL),
('ISO_8859_13', 'LATIN7', 43, 'Handled by iconv in glibc'),
('ISO_2022_KR', NULL, 44, 'no idea'),
('GBK', 'GBK', 45, NULL),
('GB18030', 'GB18030', 46, NULL),
('BIG5_HKSCS', NULL, 47, 'no match, presumably Hong Kong variant?'),
('ISO_2022_CN', NULL, 48, 'no match'),
('TSCII', NULL, 49, 'Following 4 encodings are deprecated (font encodings)'),
('TAMIL_MONO', NULL, 50, NULL),
('TAMIL_BI', NULL, 51, NULL),
('JAGRAN', NULL, 52, NULL),
('MACINTOSH_ROMAN', NULL, 53, NULL),
('UTF7', NULL, 54, NULL),
('BHASKAR', NULL, 55, 'Indic encoding - Devanagari'),
('HTCHANAKYA', NULL, 56, '56 Indic encoding - Devanagari'),
('UTF16BE', NULL, 57, 'big-endian UTF-16'),
('UTF16LE', NULL, 58, 'little-endian UTF-16'),
('UTF32BE', NULL, 59, 'big-endian UTF-32'),
('UTF32LE', NULL, 60, 'little-endian UTF-32'),
('BINARYENC', NULL, 61, 'Following 2 encodings are deprecated (font encodings) An encoding that means "This is not text, but it may have some simple ASCII text embedded". Intended input conversion is to keep strings of >=4 seven-bit ASCII characters'),
('HZ_GB_2312', NULL, 62, 'Some Web pages allow a mixture of HZ-GB and GB-2312 by using ~{ ... ~} for 2-byte pairs, and the browsers support this.'),
('UTF8UTF8', 'UTF8', 63, 'Some external vendors make the common input error of converting MSFT_CP1252 to UTF8 *twice*.'),
('TAM_ELANGO', NULL, 64, 'Elango - Tamil'),
('TAM_LTTMBARANI', NULL, 65, 'Barani - Tamil'),
('TAM_SHREE', NULL, 66, 'Shree - Tamil'),
('TAM_TBOOMIS', NULL, 67, 'TBoomis - Tamil'),
('TAM_TMNEWS', NULL, 68, 'TMNews - Tamil'),
('TAM_WEBTAMIL', NULL, 69, 'Webtamil - Tamil'),
('KDDI_SHIFT_JIS', 'SJIS', 70, 'Following 6 encodings are deprecated (font encodings) Shift_JIS variants used by Japanese cell phone carriers.'),
('DOCOMO_SHIFT_JIS', 'SJIS', 71, NULL),
('SOFTBANK_SHIFT_JIS', 'SJIS', 72, NULL),
('KDDI_ISO_2022_JP', NULL, 73, 'ISO-2022-JP variants used by KDDI and SoftBank.'),
('SOFTBANK_ISO_2022_JP', NULL, 74, ' valid Encoding enum, it is only used to indicate the total number of Encodings.');

-- allow dumping and changing the encodings table
SELECT pg_catalog.pg_extension_config_dump('pg_cld2_encodings', '');
