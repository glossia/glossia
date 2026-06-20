#[derive(Debug, Clone, Default)]
pub struct OutputValues<'a> {
    pub lang: &'a str,
    pub locale: &'a str,
    pub relpath: &'a str,
    pub basename: &'a str,
    pub ext: &'a str,
}

pub fn expand_output(template: &str, values: &OutputValues<'_>) -> String {
    let out = template
        .replace("{lang}", values.lang)
        .replace("{locale}", values.locale)
        .replace("{relpath}", &values.relpath.replace('\\', "/"))
        .replace("{basename}", values.basename)
        .replace("{ext}", values.ext);
    normalize_slashes_collapsed(&out)
}

pub fn normalize_slashes_collapsed(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut last_was_slash = false;
    for ch in input.chars() {
        if ch == '/' || ch == '\\' {
            if !last_was_slash {
                out.push('/');
            }
            last_was_slash = true;
            continue;
        }
        out.push(ch);
        last_was_slash = false;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::{expand_output, OutputValues};

    #[test]
    fn expands_placeholders() {
        let got = expand_output(
            "i18n/{lang}/{relpath}",
            &OutputValues {
                lang: "es",
                locale: "es",
                relpath: "docs/guide.md",
                basename: "guide",
                ext: "md",
            },
        );
        assert_eq!(got, "i18n/es/docs/guide.md");
    }

    #[test]
    fn normalizes_slashes() {
        let got = expand_output(
            "out\\{lang}\\{basename}.{ext}",
            &OutputValues {
                lang: "de",
                locale: "de",
                relpath: "docs\\guide.md",
                basename: "guide",
                ext: "md",
            },
        );
        assert_eq!(got, "out/de/guide.md");
    }
}
