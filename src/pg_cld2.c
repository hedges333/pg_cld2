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
}

#include <cld2/public/compact_lang_det.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(pg_cld2_detect_language);

Datum
pg_cld2_detect_language(PG_FUNCTION_ARGS)
{
    text *input_text = PG_GETARG_TEXT_PP(0);
    char *input_str = text_to_cstring(input_text);

    // let's make the parameters and return values full-featured

    // 0:   input_text              TEXT        The text to be examined.
    // 1:   is_plain_text           BOOLEAN     Or decode HTML (and MD?) if false.
    // 2:   content_language_hint   TEXT        "mi,en" boosts Maori and English
    // 3:   tld_hint                TEXT        "id" boosts Indonesian
    // 4:   language_hint           TEXT        "ITALIAN" boosts it
    // 5:   lang_code_hint          TEXT        "it" (one or the other hint, not both)
    // 6:   best_effort             BOOLEAN     Whether to set kCLDFlagBestEffort (default true)

    // N/A  encoding_hint           INTEGER
    // Postgres always sends Unicode, so this is not a param.
    // Instead we always set this to UTF8 constant (22) from CLD2's public/encodings.h
    //
    // N/A  flags                   INTEGER
    // This is mostly for debugging.  However, we set it with kCLDFlagBestEffort
    // to always get a result, even for short input text, instead of sending "UNKNOWN".
    // Since it's UTF8 input, it might at least be able to detect from the character set.
    //
    //

    // Use the one that says "Use this one." in the documentation in compact_lang_det.h.
    // (ExtDetectLanguageSummaryCheckUTF8)
    // Make an attempt to return all the data in a record.
    //
    // inputs:
    // const char* buffer                       the input string
    // int buffer_length                        length of the input string
    // bool is_plain_text                       otherwise it will decode HTML (and MD?) - make parameter?
    // const CLDHints* cld_hints                CLDHints struct with params 2-5 above
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

    int num_chunks;
    bool is_reliable = false;

    int text_bytes;
    CLD2::Language lang = CLD2::DetectLanguageSummary(
        input_str,          // const char* buffer
        strlen(input),      // int buffer_length
        true,               // bool is_plain_text (i.e. not HTML. Unicode OK.)
        nullptr,            // CLD2::Language* language3
        &num_chunks,        // int* percent3
        &text_bytes,        // int* text_bytes
        &is_reliable);      // bool is_reliable

    CLD2::ULScript ulscript = CLD2::GetULScriptFromLanguage(lang); // TODO get for all three languages

    // TODO then use ULScriptCode(ulscript) to convert it to string
    //
    // TODO also use LanguageCode and LanguageName for each of the three detected languages
    // (see lang_script.h)

    TupleDesc tuple_desc;
    if (get_call_result_type(fcinfo, NULL, &tuple_desc) != TYPEFUNC_COMPOSITE) {
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("function returning record called in context that cannot accept type record")));
    }

    Datum values[2];
    bool nulls[2] = {false, false};

    values[0] = CStringGetTextDatum(CLD2::LanguageName(lang));
    values[1] = BoolGetDatum(is_reliable);

    HeapTuple tuple = heap_form_tuple(tuple_desc, values, nulls);

    PG_RETURN_DATUM(HeapTupleGetDatum(tuple));
}

