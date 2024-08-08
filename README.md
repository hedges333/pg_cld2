pg_cld2 1.0.0
=============

NOTE
----

THIS IS A DEVELOPMENT VERSION AND HAS NOT BEEN FINISHED YET.
Despite the "1.0.0" version.  It does, however, compile and execute,
which is getting somewhere.  It just doesn't return any results yet.
(2024-08-08)

Synopsis
--------

Use cld2 language detection from Postgres.

The caller must call the function in a way that expects a record result, matching the structure of the `pg_cld2_language_detection` composite type.

1. **Call the Function**:
   You can call this function in a `SELECT` statement, and it will return a record with the fields defined in the composite type.

```sql
SELECT * FROM pg_cld2_detect_language('This is a sample text to detect the language.');
```

This will return a record with the structure:

| language_code | percent | normalized_score | is_reliable | valid_prefix_bytes | flags |
|----------------|---------|------------------|-------------|--------------------|-------|
| en             | ...     | ...              | ...         | ...                | ...   |

This is the same information provided by the CLD2::DetectLanguageSummary C function.

The CLD2 libraries must be installed on your system.

Description
-----------

2. **Using the Function in SQL**:
   You can also use the function in more complex queries, for example:

```sql
SELECT (pg_cld2_detect_language('This is a sample text to detect the language.')).*;
```

Or, if you want to extract individual fields from the composite type:

```sql
SELECT 
    (pg_cld2_detect_language('This is a sample text to detect the language.')).language_code,
    (pg_cld2_detect_language('Este es un texto de ejemplo para detectar el idioma.')).language_code;
```

This query will return just the `language_code` field from the function's output.

3. **Using the Function in PL/pgSQL**:
   If you want to use this function inside a PL/pgSQL function or procedure, you can do so by declaring a variable of the composite type and then calling the function:

```sql
DO $$
DECLARE
    detection pg_cld2_language_detection;
BEGIN
    detection := pg_cld2_detect_language('This is a sample text to detect the language.');
    RAISE NOTICE 'Language Code: %, Percent: %, Normalized Score: %, Is Reliable: %, Valid Prefix Bytes: %, Flags: %',
        detection.language_code, detection.percent, detection.normalized_score, detection.is_reliable, detection.valid_prefix_bytes, detection.flags;
END $$;
```

This example uses an anonymous block to call the `pg_cld2_detect_language` function and then raises a notice with the details of the detection. 

By following these steps, you can successfully call and utilize the `pg_cld2_detect_language` function in various contexts within PostgreSQL.

Author
------

[Mark Hedges](https://github.com/hedges333).

Copyright and License
---------------------

Copyright (c) 2024 Mark Hedges

MIT License:

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
