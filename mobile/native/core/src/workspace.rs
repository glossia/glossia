use crate::{Body, Result, Session, Transport, error, invalid, validate_registration};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use url::Url;

#[derive(Default, Deserialize, Serialize)]
pub(crate) struct Selection {
    organization: Option<String>,
    project: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
pub(crate) enum Resource {
    Voice,
    Glossary,
}

fn api_url(session: &Session, segments: &[&str]) -> Result<Url> {
    let mut url = validate_registration(&session.registration)?;
    url.path_segments_mut()
        .map_err(|_| invalid())?
        .extend(segments);
    Ok(url)
}

pub(crate) fn load(
    network: &impl Transport,
    session: Session,
    selection: Selection,
) -> Result<Value> {
    let response: Value = network.request(
        &api_url(&session, &["api", "organizations"])?,
        Body::Api(&session.access_token),
    )?;
    let organizations = response["organizations"].as_array().ok_or_else(invalid)?;
    let organization = organizations
        .iter()
        .find(|org| org["handle"].as_str() == selection.organization.as_deref())
        .or_else(|| organizations.first())
        .and_then(|org| org["handle"].as_str());
    let mut projects = Vec::new();
    if let Some(organization) = organization {
        let mut page = 1_u64;
        loop {
            let mut url = api_url(&session, &["api", organization, "projects"])?;
            url.query_pairs_mut().append_pair("page", &page.to_string());
            let response: Value = network.request(&url, Body::Api(&session.access_token))?;
            projects.extend(
                response["projects"]
                    .as_array()
                    .ok_or_else(invalid)?
                    .iter()
                    .cloned(),
            );
            if response["meta"]["has_next_page?"].as_bool() != Some(true) {
                break;
            }
            // A malformed server must not keep a background executor busy forever.
            if page >= 1000 {
                return Err(invalid());
            }
            page += 1;
        }
    }
    let project = projects
        .iter()
        .find(|project| {
            organization == selection.organization.as_deref()
                && project["handle"].as_str() == selection.project.as_deref()
        })
        .or_else(|| projects.first())
        .and_then(|project| project["handle"].as_str());
    Ok(json!({"organizations": organizations, "projects": projects,
        "selection": {"organization": organization, "project": project}}))
}

pub(crate) fn resource(
    network: &impl Transport,
    session: Session,
    selection: Selection,
    resource: Resource,
) -> Result<Value> {
    let organization = selection
        .organization
        .as_deref()
        .filter(|value| !value.is_empty())
        .ok_or_else(|| error("selection_required", "Choose an organization first."))?;
    // Voice and glossary belong to the organization, not the selected project.
    let name = match resource {
        Resource::Voice => "voice",
        Resource::Glossary => "glossary",
    };
    let result: Result<Value> = network.request(
        &api_url(&session, &["api", organization, name])?,
        Body::Api(&session.access_token),
    );
    let value = match result {
        Ok(value) => value,
        Err(failure) if failure.kind == "not_found" => Value::Null,
        Err(failure) => return Err(failure),
    };
    Ok(json!({name: value}))
}
