use crate::{Body, Result, Session, Transport, validate_uuid, workspace::Selection};
use serde_json::Value;

pub(crate) fn load(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    page: u32,
) -> Result<Value> {
    let mut url = selection.project_url(session, &["translations"])?;
    url.query_pairs_mut().append_pair("page", &page.to_string());
    network.request(&url, Body::Api(&session.access_token))
}

pub(crate) fn show(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    id: &str,
) -> Result<Value> {
    validate_uuid(id)?;
    network.request(
        &selection.project_url(session, &["translations", id])?,
        Body::Api(&session.access_token),
    )
}
