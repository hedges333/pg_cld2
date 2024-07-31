CREATE TYPE pg_cld2_language_detection AS (
    language_1_cld2_name            VARCHAR(255),
    language_1_code                 VARCHAR(255),
    language_1_pg_name              VARCHAR(255),
    language_1_percent              SMALLINT,
    language_1_normalized_score     DOUBLE 


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
('ISO_8859_5', NULL, 4, 'ISO-8859-5'),
('ISO_8859_6', NULL, 5, 'Arabic'),
('ISO_8859_7', NULL, 6, 'Greek'),
('ISO_8859_8', NULL, 7, 'Hebrew'),
('JAPANESE_EUC_JP', 'EUC_JP', 10, 'EUC_JP'),
('JAPANESE_SHIFT_JIS', 'SJIS', 11, 'SJS'),
('JAPANESE_JIS', NULL, 12, 'JIS'),
('CHINESE_BIG5', 'BIG5', 13, 'BIG5'),
('CHINESE_GB', 'GB18030', 14, 'GB'),
('CHINESE_EUC_CN', 'EUC_TW', 15, 'Misnamed. Should be EUC_TW. Was Basis Tech CNS11643EUC, before that EUC-CN(!)'),
('KOREAN_EUC_KR', 'EUC_KR', 16, 'KSC'),
('UNICODE_UNUSED', 'UTF8', 17, 'Unicode'),
('CHINESE_EUC_DEC', 'EUC_TW', 18, 'Misnamed. Should be EUC_TW. Was CNS11643EUC, before that EUC.'),
('CHINESE_CNS', 'EUC_TW', 19, 'Misnamed. Should be EUC_TW. Was CNS11643EUC, before that CNS.'),
('CHINESE_BIG5_CP950', 'BIG5', 20, 'BIG5_CP950'),
('JAPANESE_CP932', NULL, 21, 'CP932'),
('UTF8', 'UTF8', 22, NULL),
('UNKNOWN_ENCODING', 'SQL_ASCII', 23, NULL),
('ASCII_7BIT', 'LATIN1', 24, 'ISO_8859_1 with all characters <= 127.'),
('RUSSIAN_KOI8_R', NULL, 25, 'KOI8R'),
('RUSSIAN_CP1251', 'WIN1251', 26, 'CP1251'),
('MSFT_CP1252', 'WIN1252', 27, '27: CP1252 aka MSFT euro ascii'),
('RUSSIAN_KOI8_RU', NULL, 28, 'CP21866 aka KOI8-U, used for Ukrainian. Misnamed, this is _not_ KOI8-RU but KOI8-U. KOI8-U is used much more often than KOI8-RU.'),
('MSFT_CP1250', 'WIN1250', 29, 'CP1250 aka MSFT eastern european'),
('ISO_8859_15', 'LATIN9', 30, 'aka ISO_8859_0 aka ISO_8859_1 euroized'),
('MSFT_CP1254', 'WIN1254', 31, 'used for Turkish'),
('MSFT_CP1257', 'WIN1257', 32, 'used in Baltic countries'),
('ISO_8859_11', NULL, 33, 'aka TIS-620, used for Thai'),
('MSFT_CP874', NULL, 34, 'used for Thai'),
('MSFT_CP1256', 'WIN1256', 35, 'used for Arabic'),
('MSFT_CP1255', 'WIN1255', 36, 'Logical Hebrew Microsoft'),
('ISO_8859_8_I', NULL, 37, 'Iso Hebrew Logical'),
('HEBREW_VISUAL', NULL, 38, 'Iso Hebrew Visual'),
('CZECH_CP852', NULL, 39, NULL),
('CZECH_CSN_369103', NULL, 40, 'aka ISO_IR_139 aka KOI8_CS'),
('MSFT_CP1253', 'WIN1253', 41, 'used for Greek'),
('RUSSIAN_CP866', NULL, 42, NULL),
('ISO_8859_13', 'LATIN7', 43, 'Handled by iconv in glibc'),
('ISO_2022_KR', NULL, 44, NULL),
('GBK', 'GB18030', 45, NULL),
('GB18030', 'GB18030', 46, NULL),
('BIG5_HKSCS', NULL, 47, NULL),
('ISO_2022_CN', NULL, 48, NULL),
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
