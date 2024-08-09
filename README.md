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

|text\_bytes                     | 46 |
|is\_reliable                    | t |
|valid\_prefix\_bytes             | 45 |
|is\_valid\_utf8                  | f |
|mll\_cld2\_name                  | ENGLISH |
|mll\_language\_cname             | ENGLISH |
|mll\_language\_code              | en |
|mll\_primary\_script\_name        | Latin |
|mll\_primary\_script\_code        | Latn |
|mll\_script\_names               | Latin |
|mll\_script\_codes               | Latn |
|mll\_ts\_name                    | english |
|language\_1\_cld2\_name           | ENGLISH |
|language\_1\_language\_cname      | ENGLISH |
|language\_1\_language\_code       | en |
|language\_1\_primary\_script\_name | Latin |
|language\_1\_primary\_script\_code | Latn |
|language\_1\_script\_names        | Latin |
|language\_1\_script\_codes        | Latn |
|language\_1\_percent             | 97 |
|language\_1\_normalized\_score    | 7.98e-321 |
|language\_1\_ts\_name             | english |
|language\_2\_cld2\_name           | Unknown |
|language\_2\_language\_cname      | UNKNOWN\_LANGUAGE |
|language\_2\_language\_code       | un |
|language\_2\_primary\_script\_name | Latin |
|language\_2\_primary\_script\_code | Latn |
|language\_2\_script\_names        | Latin |
|language\_2\_script\_codes        | Latn |
|language\_2\_percent             | 0 |
|language\_2\_normalized\_score    | 0 |
|language\_2\_ts\_name             | simple |
|language\_3\_cld2\_name           | Unknown |
|language\_3\_language\_cname      | UNKNOWN\_LANGUAGE |
|language\_3\_language\_code       | un |
|language\_3\_primary\_script\_name | Latin |
|language\_3\_primary\_script\_code | Latn |
|language\_3\_script\_names        | Latin |
|language\_3\_script\_codes        | Latn |
|language\_3\_percent             | 0 |
|language\_3\_normalized\_score    | 0 |
|language\_3\_ts\_name             | simple |

This is the information provided by `CLD2::ExtDetectLanguageSummaryCheckUTF8`.

"MLL" = "Most Likely Language".  This is the return value from the function,
which is probably the same as language1.  (But not guaranteed?  I suppose
if the probabilities of 1 and 2 were the same, it wouldn't be.)  See the
header file for `public/compact_lang_det.h` in CLD2 if you want to learn more.

The `primary_script_name` and `primary_script_code` fields contain the first pick
of script names and codes.  The subsequent fields contain all the found script names
and codes in a comma-delimited string, omitting "None" and "Common"/"Zyyy".

The CLD2 libraries must be installed on your system.

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

