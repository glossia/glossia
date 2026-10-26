use crate::{Body, Result, Session, Transport, error, workspace::Selection};
use serde_json::Value;

pub(crate) fn default_days() -> u32 {
    30
}

pub(crate) fn validate_days(days: u32) -> Result<()> {
    if matches!(days, 7 | 30 | 90) {
        Ok(())
    } else {
        Err(error("invalid_input", "Days must be 7, 30, or 90."))
    }
}

pub(crate) fn load(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    days: u32,
) -> Result<Value> {
    let mut url = selection.project_url(session, &["analytics"])?;
    url.query_pairs_mut().append_pair("days", &days.to_string());
    network.request(&url, Body::Api(&session.access_token))
}
