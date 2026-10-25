use crate::{Body, Result, Session, Transport, workspace::api_url};
use serde_json::Value;

pub(crate) fn load(network: &impl Transport, session: &Session) -> Result<Value> {
    network.request(
        &api_url(session, &["api", "me"])?,
        Body::Api(&session.access_token),
    )
}
