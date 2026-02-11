use std::collections::HashMap;

pub struct Locale {
    pub code: &'static str,
    pub name: &'static str,
}

pub fn default_locales() -> Vec<Locale> {
    vec![
        Locale {
            code: "ar",
            name: "Arabic",
        },
        Locale {
            code: "bg",
            name: "Bulgarian",
        },
        Locale {
            code: "cs",
            name: "Czech",
        },
        Locale {
            code: "da",
            name: "Danish",
        },
        Locale {
            code: "de",
            name: "German",
        },
        Locale {
            code: "el",
            name: "Greek",
        },
        Locale {
            code: "en",
            name: "English",
        },
        Locale {
            code: "en-GB",
            name: "English (UK)",
        },
        Locale {
            code: "en-US",
            name: "English (US)",
        },
        Locale {
            code: "es",
            name: "Spanish",
        },
        Locale {
            code: "es-419",
            name: "Spanish (Latin America)",
        },
        Locale {
            code: "et",
            name: "Estonian",
        },
        Locale {
            code: "fi",
            name: "Finnish",
        },
        Locale {
            code: "fr",
            name: "French",
        },
        Locale {
            code: "he",
            name: "Hebrew",
        },
        Locale {
            code: "hi",
            name: "Hindi",
        },
        Locale {
            code: "hr",
            name: "Croatian",
        },
        Locale {
            code: "hu",
            name: "Hungarian",
        },
        Locale {
            code: "id",
            name: "Indonesian",
        },
        Locale {
            code: "it",
            name: "Italian",
        },
        Locale {
            code: "ja",
            name: "Japanese",
        },
        Locale {
            code: "ko",
            name: "Korean",
        },
        Locale {
            code: "lt",
            name: "Lithuanian",
        },
        Locale {
            code: "lv",
            name: "Latvian",
        },
        Locale {
            code: "ms",
            name: "Malay",
        },
        Locale {
            code: "nb",
            name: "Norwegian Bokmal",
        },
        Locale {
            code: "nl",
            name: "Dutch",
        },
        Locale {
            code: "pl",
            name: "Polish",
        },
        Locale {
            code: "pt",
            name: "Portuguese",
        },
        Locale {
            code: "pt-BR",
            name: "Portuguese (Brazil)",
        },
        Locale {
            code: "pt-PT",
            name: "Portuguese (Portugal)",
        },
        Locale {
            code: "ro",
            name: "Romanian",
        },
        Locale {
            code: "ru",
            name: "Russian",
        },
        Locale {
            code: "sk",
            name: "Slovak",
        },
        Locale {
            code: "sl",
            name: "Slovenian",
        },
        Locale {
            code: "sv",
            name: "Swedish",
        },
        Locale {
            code: "th",
            name: "Thai",
        },
        Locale {
            code: "tr",
            name: "Turkish",
        },
        Locale {
            code: "uk",
            name: "Ukrainian",
        },
        Locale {
            code: "vi",
            name: "Vietnamese",
        },
        Locale {
            code: "zh-Hans",
            name: "Chinese (Simplified)",
        },
        Locale {
            code: "zh-Hant",
            name: "Chinese (Traditional)",
        },
    ]
}

pub fn locale_label(locale: &Locale) -> String {
    if locale.name.trim().is_empty() {
        return locale.code.to_string();
    }
    format!("{} ({})", locale.name, locale.code)
}

pub fn locale_name_by_code(locales: &[Locale]) -> HashMap<String, String> {
    locales
        .iter()
        .map(|l| (l.code.to_string(), l.name.to_string()))
        .collect()
}
