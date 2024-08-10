pg\_cld2 1.0.0
=============

Synopsis
--------

Use cld2 language detection from Postgres.

The caller must call the function in a way that expects a record result,
matching the structure of the `pg_cld2_language_detection` composite type.

```sql
\x on
SELECT * FROM pg_cld2_detect_language('This is a sample text to detect the language.');
```

This will return a record with the structure:

| Field | Value |
| ------------------ | ----------------- |
| input\_bytes                    | 45 |
| text\_bytes                     | 46 |
| is\_reliable                    | t |
| valid\_prefix\_bytes             | 45 |
| is\_valid\_utf8                  | f |
| mll\_cld2\_name                  | ENGLISH |
| mll\_language\_cname             | ENGLISH |
| mll\_language\_code              | en |
| mll\_primary\_script\_name        | Latin |
| mll\_primary\_script\_code        | Latn |
| mll\_script\_names               | Latin |
| mll\_script\_codes               | Latn |
| mll\_ts\_name                    | english |
| language\_1\_cld2\_name           | ENGLISH |
| language\_1\_language\_cname      | ENGLISH |
| language\_1\_language\_code       | en |
| language\_1\_primary\_script\_name | Latin |
| language\_1\_primary\_script\_code | Latn |
| language\_1\_script\_names        | Latin |
| language\_1\_script\_codes        | Latn |
| language\_1\_percent             | 97 |
| language\_1\_normalized\_score    | 7.98e-321 |
| language\_1\_ts\_name             | english |
| language\_2\_cld2\_name           | Unknown |
| language\_2\_language\_cname      | UNKNOWN\_LANGUAGE |
| language\_2\_language\_code       | un |
| language\_2\_primary\_script\_name | Latin |
| language\_2\_primary\_script\_code | Latn |
| language\_2\_script\_names        | Latin |
| language\_2\_script\_codes        | Latn |
| language\_2\_percent             | 0 |
| language\_2\_normalized\_score    | 0 |
| language\_2\_ts\_name             | simple |
| language\_3\_cld2\_name           | Unknown |
| language\_3\_language\_cname      | UNKNOWN\_LANGUAGE |
| language\_3\_language\_code       | un |
| language\_3\_primary\_script\_name | Latin |
| language\_3\_primary\_script\_code | Latn |
| language\_3\_script\_names        | Latin |
| language\_3\_script\_codes        | Latn |
| language\_3\_percent             | 0 |
| language\_3\_normalized\_score    | 0 |
| language\_3\_ts\_name             | simple |

This is the information provided by `CLD2::ExtDetectLanguageSummaryCheckUTF8`.

"MLL" = "Most Likely Language".  This is the return value from the function,
which is probably the same as language1.  (But not guaranteed?  I suppose
if the probabilities of 1 and 2 were the same, it wouldn't be.)  See the
header file for `public/compact_lang_det.h` in CLD2 if you want to learn more.

The `primary_script_name` and `primary_script_code` fields contain the first pick
of script names and codes.  The subsequent fields contain all the found script names
and codes in a comma-delimited string, omitting "None" and "Common"/"Zyyy".

It also makes an attempt to look up a match to corresponding configured languages
in `pg_catalog.pg_ts_config` for `tsvector` search indexing. (`*_ts_name`)

Options
-------

See `SELECT pg_cld2_usage();`

```
  return_record := pg_cld2_detect_language(
     text_to_analyze,         -- required
     is_plain_text,           -- boolean, default true. Parses HTML if false
     content_language_hint,   -- text. Ex: "mi,en" boosts Maori & English
     tld_hint,                -- text. Ex: "id" boosts Indonesian
     cld2_language_hint,      -- text, default NULL. Ex: "ITALIAN" boosts it. See pg_cld2_languages table.
     best_effort,             -- boolean, default true. Gives best-effort answer for short text instead of UNKNOWN.
     text_encoding,           -- text, default UTF8, will copy string if not, also sets encoding hint
     tsconfig_language_hint,  -- text, default NULL. Looks up in pg_cld2_languages table, overrides cld2_language_hint.
     locale_hint              -- text, 1st 2 chars, overrides tld_hint.
  );
```

YMMV.

Type definition of `pg_cld2_language_detection`
-----------------------------------------------

Here is the type definition with some more informative comments:

```
CREATE TYPE pg_cld2_language_detection AS (
    input_bytes                     INTEGER,            -- length of original text (after conversion to utf8)
    text_bytes                      INTEGER,            -- non-markup bytes
    is_reliable                     BOOLEAN,            -- CLD2's guess
    valid_prefix_bytes              INTEGER,            -- if != input_bytes: invalid UTF8 after that byte
    is_valid_utf8                   BOOLEAN,            -- short answer whether there are invalid utf8 bytes

    mll_cld2_name                   TEXT,       -- first language name, e.g. "ENGLISH" or "NEPALI"
    mll_language_cname              TEXT,       -- language name, e.g. "ENGLISH" or "NEPALI" (only minor differences)
    mll_language_code               TEXT,       -- language code, e.g. "en" or "ne"
    mll_primary_script_name         TEXT,       -- first pick of script names, e.g. "Latin" or "Devanagari"
    mll_primary_script_code         TEXT,       -- first pick of script codes, e.g. "Latn" or "Deva"
    mll_script_names                TEXT,       -- all possible script names, e.g. "Latin,Devanagari" or "Devanagari,Latin" (skips "Common")
    mll_script_codes                TEXT,       -- all possible script codes, e.g. "Latn,Deva" or "Deva,Latn" (skips "Zyyy")
    mll_ts_name                     TEXT,       -- guess from pg_catalog.pg_ts_config, e.g. "english" or "nepali"

    language_1_cld2_name            TEXT,       -- first language name, e.g. "ENGLISH" or "NEPALI"
    language_1_language_cname       TEXT,       -- language name, e.g. "ENGLISH" or "NEPALI" (only minor differences)
    language_1_language_code        TEXT,       -- language code, e.g. "en" or "ne"
    language_1_primary_script_name  TEXT,       -- script name, e.g. "Latin" or "Devanagari"
    language_1_primary_script_code  TEXT,       -- script code, e.g. "Latn" or "Deva"
    language_1_script_names         TEXT,       -- script names, e.g. "Latin,Devanagari" or "Devanagari,Latin"
    language_1_script_codes         TEXT,       -- script code, e.g. "Latn,Deva" or "Deva,Latn"
    language_1_percent              INTEGER,            -- how likely this language is
    language_1_normalized_score     DOUBLE PRECISION,   -- mumble mumble
    language_1_ts_name              TEXT,       -- guess from pg_catalog.pg_ts_config, e.g. "english" or "nepali"

    language_2_cld2_name            TEXT,       -- second likely language name
    language_2_language_cname       TEXT,       -- etc.
    language_2_language_code        TEXT,
    language_2_primary_script_name  TEXT,       -- script name, e.g. "Latin" or "Devanagari"
    language_2_primary_script_code  TEXT,       -- script code, e.g. "Latn" or "Deva"
    language_2_script_names         TEXT,
    language_2_script_codes         TEXT,
    language_2_percent              INTEGER,
    language_2_normalized_score     DOUBLE PRECISION,
    language_2_ts_name              TEXT,

    language_3_cld2_name            TEXT,       -- third likely language name
    language_3_language_cname       TEXT,       -- etc.
    language_3_language_code        TEXT,
    language_3_primary_script_name  TEXT,       -- script name, e.g. "Latin" or "Devanagari"
    language_3_primary_script_code  TEXT,       -- script code, e.g. "Latn" or "Deva"
    language_3_script_names         TEXT,
    language_3_script_codes         TEXT,
    language_3_percent              INTEGER,
    language_3_normalized_score     DOUBLE PRECISION,
    language_3_ts_name              TEXT

);
```

Requirements
------------

The CLD2 libraries must be installed on your system.

Contributing
------------

I tested it to the point that I determined it returned the results from the
call to the CLD2 function.  I figure that library tests itself well enough.
If you'd like to add some more tests, please do a pull request.

Author
------

[Mark Hedges](https://github.com/hedges333).

Copyright and License
---------------------

Unofficially, this is "Jobware."  If it's useful to you, please help me
find a job.

Officially:

MIT License

Copyright (c) 2024 Mark Hedges

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

