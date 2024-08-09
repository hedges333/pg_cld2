extern "C" {
#include "postgres.h"
#include "fmgr.h"
#include "utils/typcache.h"
#include "executor/spi.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "catalog/pg_type.h"
#include "access/htup_details.h"
#include "utils/lsyscache.h"
#include "access/detoast.h"
#include "access/tupdesc.h"
#include "funcapi.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif
#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(pg_cld2_detect_language_internal);
}

#include <cld2/public/compact_lang_det.h>
#include <cld2/public/encodings.h>

Datum
pg_cld2_detect_language_internal(PG_FUNCTION_ARGS)
{

    // make sure this is called in a context that accepts a record return type
    TupleDesc tuple_desc;
    if (get_call_result_type(fcinfo, NULL, &tuple_desc) != TYPEFUNC_COMPOSITE) {
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("called in context that cannot accept type record")));
    }

    // let's make the parameters and return values full-featured

    // 0:   input_text              TEXT        The text to be examined.
    // 1:   is_plain_text           BOOLEAN     Or decode HTML (and MD?) if false.
    // 2:   content_language_hint   TEXT        "mi,en" boosts Maori and English
    // 3:   tld_hint                TEXT        "id" boosts Indonesian
    // 4:   language_hint           TEXT        "ITALIAN" boosts it
    // 5:   encoding_hint           INTEGER     SJS boosts Japanese
    // 6:   best_effort             BOOLEAN     Whether to set kCLDFlagBestEffort

    // ****
    // 0:   input_text              TEXT        The text to be examined.
    if (PG_ARGISNULL(0)) {
        ereport(ERROR,
            (   errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                errmsg("input_text parameter required")
            )
        );
    }

    // Get the text parameter as a PG Datum
    text *pg_input_text = PG_GETARG_TEXT_PP(0);

    // Get the cstring pointer to the actual string data without copying it (noice!)
    // Well, *probably* noice, if PG figures out that we're not changing it,
    // but even an INOUT parameter might be copied internally, so it might be a copy anyway.
    char *cld2_input_str_ptr = VARDATA_ANY(pg_input_text);

    // Get the length of the string data
    int cld2_input_str_len = VARSIZE_ANY_EXHDR(pg_input_text);

    // ****
    // 1:   is_plain_text           BOOLEAN     Or decode HTML (and MD?) if false.
    bool is_plain_text = true;
    if (!PG_ARGISNULL(1)) {
        is_plain_text = PG_GETARG_BOOL(1);
    }

    // several parameters get crammed into hints struct
    CLD2::CLDHints cld2_hints;
    cld2_hints.content_language_hint = "";
    cld2_hints.tld_hint = "";
    cld2_hints.encoding_hint = CLD2::UTF8;
    cld2_hints.language_hint = CLD2::UNKNOWN_LANGUAGE;

    // ****
    // 2:   content_language_hint   TEXT        "mi,en" boosts Maori and English
    text *content_language_hint = NULL;
    if (!PG_ARGISNULL(2)) {
        content_language_hint = PG_GETARG_TEXT_PP(2);
        cld2_hints.content_language_hint = text_to_cstring(content_language_hint);
    }

    // ****
    // 3:   tld_hint                TEXT        "id" boosts Indonesian
    text *tld_hint = NULL;
    if (!PG_ARGISNULL(3)) {
        tld_hint = PG_GETARG_TEXT_PP(3);
        cld2_hints.tld_hint = text_to_cstring(tld_hint);
    }

    // ****
    // 4:   language_hint           TEXT        "ITALIAN" boosts it
    text *language_hint = NULL;
    if (!PG_ARGISNULL(4)) {
        language_hint = PG_GETARG_TEXT_PP(4);
        const char *language_hint_cstr_const = text_to_cstring(language_hint);
        cld2_hints.language_hint = CLD2::GetLanguageFromName( language_hint_cstr_const );
    }

    // ****
    // 5:   encoding_hint           INTEGER     SJS boosts Japanese
    // The PL/pgsql wrapper function will always send Unicode, but this will be passed
    // if the source text was encoded differently and was specified as such, to give
    // CLD2 a hint about what language it might be.
    if (!PG_ARGISNULL(5)) {
        cld2_hints.encoding_hint = PG_GETARG_INT32(5);
    }
    if (cld2_hints.encoding_hint == -1) {
        cld2_hints.encoding_hint = CLD2::UTF8;
    }

    // the function expects the hints struct parameter to be const
    const CLD2::CLDHints cld2_hints_const = {
        .content_language_hint  = cld2_hints.content_language_hint,
        .tld_hint               = cld2_hints.tld_hint,
        .encoding_hint          = cld2_hints.encoding_hint,
        .language_hint          = cld2_hints.language_hint
    };


    // ****
    // 6:   best_effort             BOOLEAN     Whether to set kCLDFlagBestEffort
    //      flags                   INTEGER
    // This is mostly for debugging.  However, we set it with kCLDFlagBestEffort if not de-requested
    // to always get a result, even for short input text, instead of sending "UNKNOWN".
    // Since it's UTF8 input, it might at least be able to detect from the character set.
    int cld2_flags = 0;
    bool best_effort = true;
    if (!PG_ARGISNULL(6)) {
        best_effort = PG_GETARG_BOOL(6);
    }
    if (best_effort) {
        cld2_flags |= CLD2::kCLDFlagBestEffort;
    }

    // Use the one that says "Use this one." in the documentation in compact_lang_det.h.
    // (ExtDetectLanguageSummaryCheckUTF8)
    // Make an attempt to return all the data in a record.
    //
    // inputs:
    // const char* buffer                       the input string
    // int buffer_length                        length of the input string
    // bool is_plain_text                       otherwise it will decode HTML (and MD?) - make parameter?
    // const CLDHints* cld2_hints               CLDHints struct with params 2-5 above
    // int flags
    // Language* language3
    // int* percent3
    // double* normalized_score3
    // ResultChunkVector* resultchunkvector
    // int* text_bytes                          amount of text found that wasn't HTML tags etc.
    // bool* is_reliable
    // int* valid_prefix_bytes                  corrupted UTF8 if not same as buffer_length
    //
    // OK, got something to go on

    // Define variables for CLD2

    CLD2::Language language3[3];   // It's magically an array
    int percent3[3];
    double normalized_score3[3];
    int text_bytes = 0;
    bool is_reliable = false;
    int valid_prefix_bytes = 0;
    CLD2::ResultChunkVector ResultChunkVector;

    // most_likely_language is "probably" the same as language3[0]
    CLD2::Language most_likely_language = CLD2::ExtDetectLanguageSummaryCheckUTF8(
        cld2_input_str_ptr,     // const char* buffer
        cld2_input_str_len,     // int buffer_length
        is_plain_text,          // bool is_plain_text (i.e. not HTML. Unicode OK.)
        &cld2_hints_const,      // hints struct
        cld2_flags,             // might be set with best effort flag
        language3,              // CLD2::Language* language3
        percent3,               // int* percent3
        normalized_score3,      // double* normalized_score3
        &ResultChunkVector,     // ??
        &text_bytes,            // int* text_bytes - amount of non-markup text parsed
        &is_reliable,           // bool is_reliable
        &valid_prefix_bytes);   // if != cld2_input_str_len, invalid UTF8 after that byte

    bool is_valid_utf8 = (cld2_input_str_len == valid_prefix_bytes);


    const char* cld2_language_name3[] = {
        CLD2::LanguageName( language3[0] ),
        CLD2::LanguageName( language3[1] ),
        CLD2::LanguageName( language3[2] )
    };
    const char* mll_cld2_name = CLD2::LanguageName( most_likely_language );

    const char* language_cname3[] = {
        CLD2::LanguageDeclaredName( language3[0] ),
        CLD2::LanguageDeclaredName( language3[1] ),
        CLD2::LanguageDeclaredName( language3[2] )
    };
    const char* mll_language_cname = CLD2::LanguageDeclaredName( most_likely_language );

    const char* language_code3[] = {
        CLD2::LanguageCode( language3[0] ),
        CLD2::LanguageCode( language3[1] ),
        CLD2::LanguageCode( language3[2] )
    };
    const char* mll_language_code = CLD2::LanguageCode( most_likely_language );

    // SCRIPTS - kind of a hassle
    // to keep from having a ton of fields, we're just going to concatenate names and codes

    // first get the ULScript struct for each Language
    char *ulscriptname3[3];
    char *ulscriptcode3[3];
    char *ulprimaryscriptname3[3];
    char *ulprimaryscriptcode3[3];
    for (int i = 0; i <= 2; i++) {   // the three most likely languages
        ulscriptname3[i] = (char*)malloc(255 * sizeof(char));
        ulscriptcode3[i] = (char*)malloc(255 * sizeof(char));
        ulprimaryscriptname3[i] = (char*)malloc(255 * sizeof(char));
        ulprimaryscriptcode3[i] = (char*)malloc(255 * sizeof(char));
        strcpy(ulscriptname3[i], "");
        strcpy(ulscriptcode3[i], "");
        strcpy(ulprimaryscriptname3[i], "");
        strcpy(ulprimaryscriptcode3[i], "");
        // Each language has up to 4 scripts
        for (int n = 0; n <= 3; n++) {
            CLD2::ULScript ulscript = LanguageRecognizedScript( language3[i], n );
            const char* ulscriptname = ULScriptName(ulscript);
            if  (   (strcmp(ulscriptname, "None") == 0)
                ||  (strcmp(ulscriptname, "Common") == 0)
                ) {
                continue;
            }
            const char* ulscriptcode  = ULScriptCode(ulscript);

            if (n != 0) {
                strcat(ulscriptname3[i], ",");
                strcat(ulscriptcode3[i], ",");
            }

            strcat(ulscriptname3[i], ulscriptname);
            strcat(ulscriptcode3[i], ulscriptcode);

            if (n == 0) {
                strcpy(ulprimaryscriptname3[i], ulscriptname);
                strcpy(ulprimaryscriptcode3[i], ulscriptcode);
            }
        }
    }
    // plus the "most likely language" which is "probably" the same as language3[0]
    char *mll_ulscriptname = (char*)malloc(255 * sizeof(char));
    char *mll_ulscriptcode = (char*)malloc(255 * sizeof(char));
    char *mll_ulprimaryscriptname = (char*)malloc(255 * sizeof(char));
    char *mll_ulprimaryscriptcode = (char*)malloc(255 * sizeof(char));
    strcpy(mll_ulscriptname, "");
    strcpy(mll_ulscriptcode, "");
    strcpy(mll_ulprimaryscriptname, "");
    strcpy(mll_ulprimaryscriptcode, "");
    for (int n = 0; n <= 3; n++) {
        CLD2::ULScript ulscript = LanguageRecognizedScript( most_likely_language, n );
        const char* ulscriptname = ULScriptName(ulscript);
        if  (   (strcmp(ulscriptname, "None") == 0)
            ||  (strcmp(ulscriptname, "Common") == 0)
            ) {
            continue;
        }
        const char* ulscriptcode  = ULScriptCode(ulscript);

        if (n != 0) {
            strcat(mll_ulscriptname, ",");
            strcat(mll_ulscriptcode, ",");
        }

        strcat(mll_ulscriptname, ulscriptname);
        strcat(mll_ulscriptcode, ulscriptcode);
        if (n == 0) {
            strcpy(mll_ulprimaryscriptname, ulscriptname);
            strcpy(mll_ulprimaryscriptcode, ulscriptcode);
        }
    }

    // set up the array of values that we'll return as the custom type record
    Datum values[43];

    // this tells whether the values below will be returned as NULL.
    // we leave a few for the wrapper function to figure out.
    bool nulls[43] = {
        false, false, false, false, false,
        false, false, false, false, false, false, false, true,
        false, false, false, false, false, false, false, false, false, true,
        false, false, false, false, false, false, false, false, false, true,
        false, false, false, false, false, false, false, false, false, true };

    values[0]  = cld2_input_str_len;                            // input_bytes
    values[1]  = text_bytes;                                    // text_bytes
    values[2]  = BoolGetDatum(is_reliable);                     // is_reliable
    values[3]  = valid_prefix_bytes;                            // valid_prefix_bytes
    values[4]  = BoolGetDatum(is_valid_utf8);                   // is_valid_utf8

    values[5]  = CStringGetTextDatum( mll_cld2_name );          // "most likely language"
    values[6]  = CStringGetTextDatum( mll_language_cname );     // MLL lang cname
    values[7]  = CStringGetTextDatum( mll_language_code );      // MLL lang code
    values[8]  = CStringGetTextDatum( mll_ulprimaryscriptname); // MLL script name (first pick)
    values[9]  = CStringGetTextDatum( mll_ulprimaryscriptcode); // MLL script code (first pick)
    values[10] = CStringGetTextDatum( mll_ulscriptname );       // MLL script name (all concatenated)
    values[11] = CStringGetTextDatum( mll_ulscriptcode );       // MLL script code (all concatenated)
    values[12] = PointerGetDatum(NULL);                         // MLL ts_name

    values[13] = CStringGetTextDatum( cld2_language_name3[0] ); // language_1_cld2_name
    values[14] = CStringGetTextDatum( language_cname3[0] );     // language_1_language_cname
    values[15] = CStringGetTextDatum( language_code3[0] );      // language_1_language_code
    values[16] = CStringGetTextDatum( ulprimaryscriptname3[0]); // language_1_script_name
    values[17] = CStringGetTextDatum( ulprimaryscriptcode3[0]); // language_1_script_code
    values[18] = CStringGetTextDatum( ulscriptname3[0] );       // language_1_script_name
    values[19] = CStringGetTextDatum( ulscriptcode3[0] );       // language_1_script_code
    values[20] = percent3[0];                                   // language_1_percent
    values[21] = normalized_score3[0];                          // language_1_normalized_score
    values[22] = PointerGetDatum(NULL);                         // language_1_ts_name

    values[23] = CStringGetTextDatum( cld2_language_name3[1] ); // language_2_cld2_name
    values[24] = CStringGetTextDatum( language_cname3[1] );     // language_2_language_cname
    values[25] = CStringGetTextDatum( language_code3[1] );      // language_2_language_code
    values[26] = CStringGetTextDatum( ulprimaryscriptname3[1]); // language_1_script_name
    values[27] = CStringGetTextDatum( ulprimaryscriptcode3[1]); // language_1_script_code
    values[28] = CStringGetTextDatum( ulscriptname3[1] );       // language_2_script_name
    values[29] = CStringGetTextDatum( ulscriptcode3[1] );       // language_2_script_code
    values[30] = percent3[1];                                   // language_2_percent
    values[31] = normalized_score3[1];                          // language_2_normalized_score
    values[32] = PointerGetDatum(NULL);                         // language_2_ts_name

    values[33] = CStringGetTextDatum( cld2_language_name3[2] ); // language_3_cld2_name
    values[34] = CStringGetTextDatum( language_cname3[2] );     // language_3_language_cname
    values[35] = CStringGetTextDatum( language_code3[2] );      // language_3_language_code
    values[36] = CStringGetTextDatum( ulprimaryscriptname3[2]); // language_1_script_name
    values[37] = CStringGetTextDatum( ulprimaryscriptcode3[2]); // language_1_script_code
    values[38] = CStringGetTextDatum( ulscriptname3[2] );       // language_3_script_name
    values[39] = CStringGetTextDatum( ulscriptcode3[2] );       // language_3_script_code
    values[40] = percent3[2];                                   // language_3_percent
    values[41] = normalized_score3[2];                          // language_3_normalized_score
    values[42] = PointerGetDatum(NULL);                         // language_3_ts_name

    HeapTuple tuple = heap_form_tuple(tuple_desc, values, nulls);

    for (int i = 0; i <= 2; i++) {
        free(ulscriptname3[i]);
        free(ulscriptcode3[i]);
        free(ulprimaryscriptname3[i]);
        free(ulprimaryscriptcode3[i]);
    }
    free(mll_ulscriptname);
    free(mll_ulscriptcode);
    free(mll_ulprimaryscriptname);
    free(mll_ulprimaryscriptcode);

    PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}

