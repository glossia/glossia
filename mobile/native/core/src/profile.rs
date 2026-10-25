use crate::{Body, Result, Session, Transport, error, workspace::api_url};
use serde::Deserialize;
use serde_json::{Value, json};

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct FluentLanguages {
    fluent_languages: Vec<String>,
}

pub(crate) fn save_languages(
    network: &impl Transport,
    session: &Session,
    input: FluentLanguages,
) -> Result<Value> {
    let mut seen = std::collections::HashSet::new();
    if input.fluent_languages.len() > 100
        || input.fluent_languages.iter().any(|tag| {
            let parts: Vec<_> = tag.split('-').collect();
            tag.len() > 255
                || parts.is_empty()
                || !parts[0].bytes().all(|c| c.is_ascii_alphabetic())
                || !(2..=8).contains(&parts[0].len()) && !matches!(parts[0], "x" | "X" | "i" | "I")
                || parts.iter().any(|part| {
                    part.is_empty()
                        || part.len() > 8
                        || !part.bytes().all(|c| c.is_ascii_alphanumeric())
                })
                || !seen.insert(tag.to_ascii_lowercase())
        })
    {
        return Err(error(
            "invalid_input",
            "Enter distinct BCP47 fluent-language tags.",
        ));
    }
    network.request(
        &api_url(session, &["api", "me", "fluent-languages"])?,
        Body::ApiPut(
            &session.access_token,
            json!({"fluent_languages": input.fluent_languages}),
        ),
    )
}

pub(crate) fn load(network: &impl Transport, session: &Session) -> Result<Value> {
    network.request(
        &api_url(session, &["api", "me"])?,
        Body::Api(&session.access_token),
    )
}
