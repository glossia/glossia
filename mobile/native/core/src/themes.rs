use crate::transport::{Body, Transport};
use crate::{AuthError, Result, error, server_url};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeSet;

#[derive(Deserialize, Serialize)]
struct Catalog {
    schema_version: u32,
    revision: String,
    default_theme_id: String,
    themes: Vec<Theme>,
}

#[derive(Deserialize, Serialize)]
struct Theme {
    id: String,
    name: String,
    description: String,
    typography: String,
    button_radius: f64,
    card_radius: f64,
    light: Palette,
    dark: Palette,
}

#[derive(Deserialize, Serialize)]
struct Palette {
    background: String,
    surface: String,
    subtle: String,
    text: String,
    secondary_text: String,
    border: String,
    accent: String,
    on_accent: String,
    tint: String,
}

pub(crate) fn fetch(network: &impl Transport, server: &str) -> Result<Value> {
    let url = server_url(server)?.join("api/native/themes").unwrap();
    validate(network.request(&url, Body::Public { failure })?)
}

fn failure(status: u16, _: &[u8]) -> AuthError {
    if matches!(status, 404 | 501) {
        error(
            "theme_unsupported",
            "This Glossia server does not publish themes.",
        )
    } else {
        error(
            "theme_unavailable",
            "Glossia themes are temporarily unavailable.",
        )
    }
}

fn invalid() -> AuthError {
    error(
        "invalid_theme",
        "This Glossia theme catalog is not supported.",
    )
}

pub(crate) fn validate(value: Value) -> Result<Value> {
    let catalog: Catalog = serde_json::from_value(value).map_err(|_| invalid())?;
    let mut ids = BTreeSet::new();
    if catalog.schema_version != 1
        || !text(&catalog.revision, 128)
        || catalog.themes.is_empty()
        || catalog.themes.len() > 16
        || !catalog.themes.iter().all(|theme| {
            text(&theme.id, 64)
                && theme.id != "server-default"
                && theme.id.split('-').all(|part| {
                    !part.is_empty()
                        && part
                            .bytes()
                            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit())
                })
                && ids.insert(&theme.id)
                && text(&theme.name, 80)
                && text(&theme.description, 160)
                && matches!(theme.typography.as_str(), "standard" | "strong" | "rounded")
                && (0.0..=24.0).contains(&theme.button_radius)
                && (0.0..=32.0).contains(&theme.card_radius)
                && palette(&theme.light, "#FFFFFF")
                && palette(&theme.dark, "#1C1C1E")
        })
        || !ids.contains(&catalog.default_theme_id)
    {
        return Err(invalid());
    }
    serde_json::to_value(catalog).map_err(|_| invalid())
}

fn text(value: &str, max: usize) -> bool {
    !value.trim().is_empty() && value.len() <= max
}

fn palette(palette: &Palette, native_surface: &str) -> bool {
    let colors = [
        &palette.background,
        &palette.surface,
        &palette.subtle,
        &palette.text,
        &palette.secondary_text,
        &palette.border,
        &palette.accent,
        &palette.on_accent,
        &palette.tint,
    ];
    colors.iter().all(|color| {
        color.len() == 7
            && color.starts_with('#')
            && color.as_bytes()[1..].iter().all(u8::is_ascii_hexdigit)
    }) && [&palette.background, &palette.surface, &palette.subtle]
        .iter()
        .all(|surface| {
            [&palette.text, &palette.secondary_text, &palette.tint]
                .iter()
                .all(|color| contrast(color, surface) >= 4.5)
        })
        && contrast(&palette.accent, &palette.on_accent) >= 4.5
        && contrast(&palette.tint, native_surface) >= 4.5
}

fn contrast(left: &str, right: &str) -> f64 {
    let luminance = |color: &str| {
        [0.2126, 0.7152, 0.0722]
            .iter()
            .enumerate()
            .map(|(index, weight)| {
                let channel = u8::from_str_radix(&color[1 + index * 2..3 + index * 2], 16).unwrap()
                    as f64
                    / 255.0;
                let linear = if channel <= 0.04045 {
                    channel / 12.92
                } else {
                    ((channel + 0.055) / 1.055).powf(2.4)
                };
                linear * weight
            })
            .sum::<f64>()
    };
    let a = luminance(left);
    let b = luminance(right);
    (a.max(b) + 0.05) / (a.min(b) + 0.05)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{bridge, transport::Network};
    use serde_json::json;

    fn catalog() -> Value {
        json!({
            "schema_version":1, "revision":"test-1", "default_theme_id":"glossia",
            "themes":[{
                "id":"glossia", "name":"Glossia", "description":"Glossia tokens.",
                "typography":"standard", "button_radius":8, "card_radius":12,
                "light":{
                    "background":"#FAF8F5", "surface":"#FFFFFF", "subtle":"#F2EFE9", "text":"#1C1917",
                    "secondary_text":"#5C564E", "border":"#E4E0D9", "accent":"#6D3CC4",
                    "on_accent":"#FFFFFF", "tint":"#6D3CC4"
                },
                "dark":{
                    "background":"#1C1917", "surface":"#2A2621", "subtle":"#2A2621", "text":"#FAF8F5",
                    "secondary_text":"#D1CDC5", "border":"#3D3833", "accent":"#D0BCFF",
                    "on_accent":"#381E72", "tint":"#D0BCFF"
                }
            }]
        })
    }

    #[test]
    fn bridge_validates_server_catalogs_and_discards_unknown_fields() {
        let mut catalog = catalog();
        catalog["future"] = json!(true);
        catalog["themes"][0]["card_radius"] = json!(7.5);
        let value: Value = serde_json::from_str(&bridge::execute(
            &json!({
                "operation":"validate_themes", "catalog":catalog
            })
            .to_string(),
        ))
        .unwrap();
        assert_eq!(value["ok"]["themes"][0]["card_radius"], 7.5);
        assert!(value["ok"].get("future").is_none());
    }

    #[test]
    fn rejects_unsupported_unbounded_or_unreadable_themes() {
        for (path, value) in [
            ("/schema_version", json!(2)),
            ("/default_theme_id", json!("missing")),
            ("/themes/0/id", json!("../external")),
            ("/themes/0/card_radius", json!(33)),
            ("/themes/0/button_radius", json!(-1)),
            ("/themes/0/light/border", json!("#abcdéf")),
            ("/themes/0/light/text", json!("#FFFFFF")),
            ("/themes/0/light/tint", json!("#FFFFFF")),
            ("/themes/0/dark/on_accent", json!("#D0BCFF")),
        ] {
            let mut input = catalog();
            *input.pointer_mut(path).unwrap() = value;
            let output: Value = serde_json::from_str(&bridge::execute(
                &json!({
                    "operation":"validate_themes", "catalog":input
                })
                .to_string(),
            ))
            .unwrap();
            assert_eq!(output["error"]["kind"], "invalid_theme", "{path}");
        }
        let mut duplicate = catalog();
        duplicate["themes"]
            .as_array_mut()
            .unwrap()
            .push(catalog()["themes"][0].clone());
        assert!(validate(duplicate).is_err());
        assert!(validate(catalog()).is_ok());
        for server in [
            "http://example.com",
            "https://example.com/path",
            "https://user@example.com",
        ] {
            assert!(fetch(&Network, server).is_err());
        }
    }

    struct PublicServer(u16);
    impl Transport for PublicServer {
        fn request<T: serde::de::DeserializeOwned>(
            &self,
            url: &url::Url,
            body: Body<'_>,
        ) -> Result<T> {
            assert_eq!(url.as_str(), "https://glossia.example/api/native/themes");
            let Body::Public { failure } = body else {
                panic!("Themes must never send credentials")
            };
            if self.0 == 200 {
                Ok(serde_json::from_value(catalog()).unwrap())
            } else {
                Err(failure(self.0, br#"{"error":"invalid_grant"}"#))
            }
        }
    }

    #[test]
    fn public_fetch_never_treats_theme_failures_as_invalid_credentials() {
        for status in [200, 401, 403, 404, 500, 501, 302] {
            let output: Value = serde_json::from_str(&bridge::execute_using(
                &PublicServer(status),
                &json!({
                    "operation":"themes", "server":"https://glossia.example/"
                })
                .to_string(),
            ))
            .unwrap();
            if status == 200 {
                assert_eq!(output["ok"], validate(catalog()).unwrap());
            } else {
                assert_eq!(
                    output["error"]["kind"],
                    if matches!(status, 404 | 501) {
                        "theme_unsupported"
                    } else {
                        "theme_unavailable"
                    }
                );
            }
        }
    }
}
