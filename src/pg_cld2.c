extern "C" {
#include "postgres.h"
#include "fmgr.h"
#include "utils/typcache.h"
#include "executor/spi.h"
#include "utils/builtins.h"
#include "catalog/pg_type.h"
#include "access/htup_details.h"
#include "utils/lsyscache.h"
#include "access/tupdesc.h"
#include "funcapi.h"
#include <stdbool.h>
}

#include <cld2/public/compact_lang_det.h>
#include <cld2/public/encodings.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(pg_cld2_detect_language_internal);

Datum
pg_cld2_detect_language_internal(PG_FUNCTION_ARGS)
{
    // let's make the parameters and return values full-featured

    // 0:   input_text              TEXT        The text to be examined.
    // 1:   is_plain_text           BOOLEAN     Or decode HTML (and MD?) if false.
    // 2:   content_language_hint   TEXT        "mi,en" boosts Maori and English
    // 3:   tld_hint                TEXT        "id" boosts Indonesian
    // 4:   language_hint           TEXT        "ITALIAN" boosts it
    // 5:   encoding_hint           INTEGER     SJS boosts Japanese
    // 6:   best_effort             BOOLEAN     Whether to set kCLDFlagBestEffort

    // 0:   input_text              TEXT        The text to be examined.
    if (PG_ARGISNULL(0)) {
        PG_RETURN_NULL();
    }

    // Get the text parameter as a PG Datum
    text *pg_input_text = PG_GETARG_TEXT_PP(0);

    // Get the cstring pointer to the actual string data without copying it (noice!)
    char *cld2_input_str_ptr = VARDATA_ANY(pg_input_text);

    // Get the length of the string data
    int cld2_input_str_len = VARSIZE_ANY_EXHDR(pg_input_text);

    // 1:   is_plain_text           BOOLEAN     Or decode HTML (and MD?) if false.
    bool is_plain_text = true;
    if (!PG_ARGISNULL(1)) {
        is_plain_text = PG_GETARG_BOOL(1);
    }

    // several parameters get crammed into hints struct
    CLD2::CLDHints cld2_hints;
    cld2_hints.content_language_hint = NULL;
    cld2_hints.tld_hint = NULL;
    cld2_hints.encoding_hint = CLD2::UTF8;
    cld2_hints.language_hint = CLD2::UNKNOWN_LANGUAGE;

    // 2:   content_language_hint   TEXT        "mi,en" boosts Maori and English

    text *content_language_hint = NULL;
    if (!PG_ARGISNULL(2)) {
        content_language_hint = PG_GETARG_TEXT_PP(2);
        cld2_hints.content_language_hint = text_to_cstring(content_language_hint);
    }

    // 3:   tld_hint                TEXT        "id" boosts Indonesian
    text *tld_hint = NULL;
    if (!PG_ARGISNULL(3)) {
        tld_hint = PG_GETARG_TEXT_PP(3);
        cld2_hints.tld_hint = text_to_cstring(tld_hint);
    }

    // 4:   language_hint           TEXT        "ITALIAN" boosts it
    text *language_hint = NULL;
    if (!PG_ARGISNULL(4)) {
        language_hint = PG_GETARG_TEXT_PP(4);
        const char *language_hint_cstr_const = text_to_cstring(language_hint);
        cld2_hints.language_hint = CLD2::GetLanguageFromName( language_hint_cstr_const );
    }

    // 5:   encoding_hint           INTEGER     SJS boosts Japanese
    // The PL/pgsql wrapper function will always send Unicode, but this will be passed
    // if the source text was encoded differently and was specified as such, to give
    // CLD2 a hint about what language it might be.
    if (!PG_ARGISNULL(5)) {
        cld2_hints.encoding_hint = PG_GETARG_UINT16(5);
    }

    const CLD2::CLDHints cld2_hints_const = {
        .content_language_hint  = cld2_hints.content_language_hint,
        .tld_hint               = cld2_hints.tld_hint,
        .encoding_hint          = cld2_hints.encoding_hint,
        .language_hint          = cld2_hints.language_hint
    };

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
    const char *language_code = "unknown";

    CLD2::Language language3;   // It's magically an array
    int percent3;
    double normalized_score3;
    int text_bytes = 0;
    bool is_reliable = false;
    int valid_prefix_bytes = 0;
    CLD2::ResultChunkVector ResultChunkVector;

    CLD2::Language lang = CLD2::ExtDetectLanguageSummaryCheckUTF8(
        cld2_input_str_ptr,     // const char* buffer
        cld2_input_str_len,     // int buffer_length
        is_plain_text,          // bool is_plain_text (i.e. not HTML. Unicode OK.)
        &cld2_hints_const,      // hints struct
        cld2_flags,             // might be set with best effort flag
        &language3,             // CLD2::Language* language3
        &percent3,              // int* percent3
        &normalized_score3,     // double* normalized_score3
        &ResultChunkVector,     // ??
        &text_bytes,            // int* text_bytes - amount of non-markup text parsed
        &is_reliable,           // bool is_reliable
        &valid_prefix_bytes);   // if != cld2_input_str_len, invalid UTF8 after that byte

    // use GetULScriptFromName(ulscript) to convert languages to strings
    CLD2::ULScript ul_script3;
    ul_script3 = CLD2::GetULScriptFromName( language3 );

    char *script_code3[3];
    script_code3[0] = CLD2::ULScriptCode( ul_script3[0] );
    script_code3[1] = CLD2::ULScriptCode( ul_script3[1] );
    script_code3[2] = CLD2::ULScriptCode( ul_script3[2] );


    //
    // also use LanguageCode and LanguageName for each of the three detected languages
    // (see lang_script.h)

    TupleDesc tuple_desc;
    if (get_call_result_type(fcinfo, NULL, &tuple_desc) != TYPEFUNC_COMPOSITE) {
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("called in context that cannot accept type record")));
    }

    Datum values[22];
    bool nulls[22] = {
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false, false, false, false,
        false, false };

    char *cld2_language_name[3];
    cld2_language_name[0] = CLD2::LanguageName( language3[0] );
    cld2_language_name[1] = CLD2::LanguageName( language3[1] );
    cld2_language_name[2] = CLD2::LanguageName( language3[2] );

    values[0]  = CStringGetTextDatum( cld2_language_name[0] );              // language_1_cld2_name
    values[1]  = CStringGetTextDatum( cld2_language_name[0] );              // language_1_code
    values[2]  = CStringGetTextDatum( script_code3[0] );                    // language_1_script
    values[3]  = percent3[0];                                               // language_1_percent
    values[4]  = normalized_score3[0];                                      // language_1_normalized_score
    values[5]  = NULL;                                                      // language_1_ts_name

    values[6]  = CStringGetTextDatum( cld2_language_name[1] );              // language_2_cld2_name
    values[7]  = CStringGetTextDatum( cld2_language_name[1] );              // language_2_code
    values[8]  = CStringGetTextDatum( script_code3[1] );                    // language_2_script
    values[9]  = percent3[1];                                               // language_2_percent
    values[10] = normalized_score3[1];                                      // language_2_normalized_score
    values[11] = NULL;                                                      // language_2_ts_name

    values[13] = CStringGetTextDatum( cld2_language_name[2] );              // language_3_cld2_name
    values[14] = CStringGetTextDatum( cld2_language_name[2] );              // language_3_code
    values[14] = CStringGetTextDatum( script_code3[2] );                    // language_3_script
    values[15] = percent3[1];                                               // language_3_percent
    values[16] = normalized_score3[1];                                      // language_3_normalized_score
    values[17] = NULL;                                                      // language_3_ts_name

    values[18] = cld2_input_str_len;                                        // input_bytes
    values[19] = text_bytes;                                                // text_bytes
    values[20] = BoolGetDatum(is_reliable);                                 // is_reliable
    values[21] = valid_prefix_bytes;                                        // valid_prefix_bytes

    HeapTuple tuple = heap_form_tuple(tuple_desc, values, nulls);

    PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}

