use crate::{Body, Result, Session, Transport, error, validate_uuid, workspace::Selection};
use serde::Deserialize;
use serde_json::{Value, json};

// Each write requires the native client's persisted UUID. Retrying the same command
// replays exactly the same payload; the core never generates replacement IDs.
#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case", deny_unknown_fields)]
pub(crate) enum Action {
    Create {
        id: String,
        translation_session_id: Option<String>,
    },
    Show {
        id: String,
    },
    Send {
        id: String,
        message_id: String,
        content: String,
    },
}

pub(crate) fn list(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    page: u32,
) -> Result<Value> {
    let mut url = selection.project_url(session, &["toki", "conversations"])?;
    url.query_pairs_mut().append_pair("page", &page.to_string());
    network.request(&url, Body::Api(&session.access_token))
}

pub(crate) fn conversation(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    action: Action,
) -> Result<Value> {
    let (segments, body) = match &action {
        Action::Create {
            id,
            translation_session_id,
        } => {
            validate_uuid(id)?;
            let mut payload = json!({"id": id});
            if let Some(translation_session_id) = translation_session_id {
                validate_uuid(translation_session_id)?;
                payload["translation_session_id"] = json!(translation_session_id);
            }
            (
                vec!["toki", "conversations"],
                Body::ApiJson(&session.access_token, payload),
            )
        }
        Action::Show { id } => {
            validate_uuid(id)?;
            (
                vec!["toki", "conversations", id],
                Body::Api(&session.access_token),
            )
        }
        Action::Send {
            id,
            message_id,
            content,
        } => {
            validate_uuid(id)?;
            validate_uuid(message_id)?;
            if content.trim().is_empty() || content.chars().count() > 4000 {
                return Err(error(
                    "invalid_input",
                    "Messages must contain 1 to 4000 characters and cannot be blank.",
                ));
            }
            (
                vec!["toki", "conversations", id, "messages"],
                Body::ApiJson(
                    &session.access_token,
                    json!({"id": message_id, "content": content}),
                ),
            )
        }
    };
    network.request(&selection.project_url(session, &segments)?, body)
}
