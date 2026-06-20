use crate::format::Format;

pub struct SystemPromptInput<'a> {
    pub format: Format,
    pub source_language: &'a str,
    pub locale: &'a str,
    pub language: &'a str,
    pub context_body: &'a str,
    pub locale_override_body: &'a str,
    pub frontmatter_preserved: bool,
    pub custom_prompt: Option<&'a str>,
}

pub fn build_system_prompt(input: SystemPromptInput<'_>) -> String {
    if input.format == Format::PO {
        return po_prompt(
            input.source_language,
            input.locale,
            input.language,
            input.context_body,
            input.locale_override_body,
        );
    }

    let mut lines = vec![
        "You are a professional localization engine.".to_string(),
        format!(
            "Translate the content from {} to {} ({}).",
            input.source_language, input.language, input.locale
        ),
        "Preserve code blocks, inline code, URLs, placeholders, lists, and headings.".to_string(),
        "Return only the translated content. Do not add commentary or markdown fences.".to_string(),
    ];

    if input.format.is_structured() {
        lines.push(format!(
            "Return valid {} only. Do not wrap the output in markdown fences.",
            input.format
        ));
    }

    if input.frontmatter_preserved {
        lines.push("Frontmatter is preserved separately. Do not add new frontmatter.".into());
    }

    if let Some(custom_prompt) = input.custom_prompt.filter(|value| !value.trim().is_empty()) {
        lines.push(custom_prompt.trim().to_string());
    }

    if !input.context_body.trim().is_empty() {
        lines.push(String::new());
        lines.push("Project context:".into());
        lines.push(input.context_body.trim().to_string());
    }

    if !input.locale_override_body.trim().is_empty() {
        lines.push(String::new());
        lines.push(format!(
            "Locale-specific instructions for {}:",
            input.language
        ));
        lines.push(input.locale_override_body.trim().to_string());
    }

    lines.join("\n")
}

pub fn build_user_prompt(
    source_language: &str,
    locale: &str,
    language: &str,
    source_content: &str,
    last_error: Option<&str>,
) -> String {
    let mut parts = vec![
        format!(
            "Translate the following content from {} to {} ({}).",
            source_language, language, locale
        ),
        String::new(),
        source_content.to_string(),
    ];

    if let Some(last_error) = last_error.filter(|value| !value.trim().is_empty()) {
        parts.push(String::new());
        parts.push(format!(
            "Previous output failed validation: {last_error}\nReturn a corrected full translation."
        ));
    }

    parts.join("\n")
}

fn po_prompt(
    source_language: &str,
    locale: &str,
    language: &str,
    context_body: &str,
    locale_override_body: &str,
) -> String {
    let plural_forms = plural_forms(locale);
    let mut lines = vec![
        "You are a professional translator specializing in software localization.".to_string(),
        format!(
            "You translate Gettext PO template files from {} to {} ({}).",
            source_language, language, locale
        ),
        "Output ONLY a valid Gettext .po file. No markdown fences, no explanation, no preamble."
            .to_string(),
        String::new(),
        "Rules:".to_string(),
        "1. The first entry must be the PO header.".to_string(),
        format!("2. The header must include Language: {}.", locale),
        "3. The header must include MIME-Version: 1.0, Content-Type: text/plain; charset=UTF-8, and Content-Transfer-Encoding: 8bit.".to_string(),
        format!("4. The header must include Plural-Forms: {}.", plural_forms),
        "5. Preserve all msgid values exactly as they appear in the source.".to_string(),
        format!("6. Translate each msgid into the corresponding msgstr for {}.", language),
        "7. Preserve all interpolation variables, HTML tags, and comments exactly as-is."
            .to_string(),
        format!(
            "8. For plural forms, provide the correct number of msgstr[N] entries for {}.",
            language
        ),
        "9. Do not add the fuzzy flag to any translations.".to_string(),
        "10. Keep each msgstr on a single line unless the source already uses multi-line PO strings."
            .to_string(),
    ];

    if !context_body.trim().is_empty() {
        lines.push(String::new());
        lines.push("Project context:".into());
        lines.push(context_body.trim().to_string());
    }

    if !locale_override_body.trim().is_empty() {
        lines.push(String::new());
        lines.push(format!("Locale-specific instructions for {}:", language));
        lines.push(locale_override_body.trim().to_string());
    }

    lines.join("\n")
}

fn plural_forms(locale: &str) -> &'static str {
    match locale {
        "es" => "nplurals=2; plural=n != 1;",
        "ja" | "ko" | "yue_Hant" | "zh_Hans" | "zh_Hant" => "nplurals=1; plural=0;",
        "ru" => "nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;",
        _ => "nplurals=2; plural=n != 1;",
    }
}
