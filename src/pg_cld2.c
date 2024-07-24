#include "postgres.h"
#include "fmgr.h"
#include <cld2/public/compact_lang_det.h>
#include <vector>
#include <string.h>
#include "utils/builtins.h"
#include "utils/array.h"
#include "utils/lsyscache.h"
#include "utils/typcache.h"
#include "utils/tuplestore.h"
#include "access/htup_details.h"  // for heap_form_tuple

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(pg_cld2_detect_language);

Datum
pg_cld2_detect_language(PG_FUNCTION_ARGS)
{
    text *input_text = PG_GETARG_TEXT_PP(0);
    char *input_str = text_to_cstring(input_text);

    // Define variables for CLD2
    const char *language_code = "unknown";
    bool is_reliable = false;
    CLD2::Language language3[3];
    int percent3[3];
    int text_bytes = 0;

    CLD2::Language detected_language = CLD2::DetectLanguageSummary(
        input_str, strlen(input_str), true,
        language3, percent3, &text_bytes, &is_reliable);

    // Map CLD2 languages to language codes
    switch (detected_language) {
        case CLD2::ENGLISH: language_code = "en"; break;
        case CLD2::FRENCH: language_code = "fr"; break;
        case CLD2::SPANISH: language_code = "es"; break;
        case CLD2::GERMAN: language_code = "de"; break;
        case CLD2::ITALIAN: language_code = "it"; break;
        case CLD2::DUTCH: language_code = "nl"; break;
        case CLD2::RUSSIAN: language_code = "ru"; break;
        case CLD2::PORTUGUESE: language_code = "pt"; break;
        case CLD2::CHINESE: language_code = "zh"; break;
        case CLD2::JAPANESE: language_code = "ja"; break;
        case CLD2::KOREAN: language_code = "ko"; break;
        case CLD2::ARABIC: language_code = "ar"; break;
        case CLD2::HEBREW: language_code = "he"; break;
        case CLD2::TURKISH: language_code = "tr"; break;
        case CLD2::POLISH: language_code = "pl"; break;
        case CLD2::SWEDISH: language_code = "sv"; break;
        case CLD2::DANISH: language_code = "da"; break;
        case CLD2::NORWEGIAN: language_code = "no"; break;
        case CLD2::FINNISH: language_code = "fi"; break;
        case CLD2::CZECH: language_code = "cs"; break;
        case CLD2::HUNGARIAN: language_code = "hu"; break;
        case CLD2::SLOVAK: language_code = "sk"; break;
        case CLD2::UKRAINIAN: language_code = "uk"; break;
        case CLD2::ROMANIAN: language_code = "ro"; break;
        case CLD2::SERBIAN: language_code = "sr"; break;
        case CLD2::BULGARIAN: language_code = "bg"; break;
        case CLD2::HINDI: language_code = "hi"; break;
        case CLD2::MALAY: language_code = "ms"; break;
        case CLD2::INDONESIAN: language_code = "id"; break;
        case CLD2::VIETNAMESE: language_code = "vi"; break;
        case CLD2::TAMIL: language_code = "ta"; break;
        case CLD2::BENGALI: language_code = "bn"; break;
        case CLD2::MARATHI: language_code = "mr"; break;
        case CLD2::NEPALI: language_code = "ne"; break;
        case CLD2::GREEK: language_code = "el"; break;
        case CLD2::LATVIAN: language_code = "lv"; break;
        case CLD2::LITHUANIAN: language_code = "lt"; break;
        case CLD2::ESTONIAN: language_code = "et"; break;
        case CLD2::CATALAN: language_code = "ca"; break;
        case CLD2::BASQUE: language_code = "eu"; break;
        case CLD2::ALBANIAN: language_code = "sq"; break;
        case CLD2::MACEDONIAN: language_code = "mk"; break;
        case CLD2::MALTESE: language_code = "mt"; break;
        case CLD2::LUXEMBOURGISH: language_code = "lb"; break;
        case CLD2::WELSH: language_code = "cy"; break;
        case CLD2::IRISH: language_code = "ga"; break;
        case CLD2::SCOTS_GAELIC: language_code = "gd"; break;
        case CLD2::YIDDISH: language_code = "yi"; break;
        case CLD2::MONGOLIAN: language_code = "mn"; break;
        case CLD2::TAJIK: language_code = "tg"; break;
        case CLD2::KURDISH: language_code = "ku"; break;
        case CLD2::CROATIAN: language_code = "hr"; break;
        case CLD2::BOSNIAN: language_code = "bs"; break;
        case CLD2::SLOVENIAN: language_code = "sl"; break;
        case CLD2::MALAYALAM: language_code = "ml"; break;
        case CLD2::SWAHILI: language_code = "sw"; break;
        default: language_code = "unknown"; break;
    }

    // Prepare the tuple to return
    TupleDesc tuple_desc;
    Datum values[6];
    bool nulls[6] = {false, false, false, false, false, false};
    HeapTuple tuple;

    // Get the composite type information
    if (get_call_result_type(fcinfo, NULL, &tuple_desc) != TYPTYPE_COMPOSITE) {
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("return type must be a row type")));
    }

    // Fill in the values for the record
    values[0] = CStringGetTextDatum(language_code);
    values[1] = Int32GetDatum(percent3[0]);
    values[2] = Float8GetDatum((double)percent3[0]);
    values[3] = BoolGetDatum(is_reliable);
    values[4] = Int32GetDatum(text_bytes);
    values[5] = Int32GetDatum(0);

    // Build the tuple
    tuple = heap_form_tuple(tuple_desc, values, nulls);

    // Free allocated memory
    pfree(input_str);

    // Return the tuple
    PG_RETURN_DATUM(DatumGetHeapTuple(tuple));
}
