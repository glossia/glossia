use crate::{Body, Result, Session, Transport, error, validate_uuid, workspace::Selection};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

#[derive(Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) enum ContextScope {
    Locale,
    Project,
}

#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case", deny_unknown_fields)]
pub(crate) enum Action {
    List {
        id: String,
    },
    Answer {
        id: String,
        review_id: String,
        answer: String,
        guidance: Option<String>,
        context_scope: Option<ContextScope>,
        resolution_message_id: Option<String>,
    },
}

pub(crate) fn execute(
    network: &impl Transport,
    session: &Session,
    selection: &Selection,
    action: Action,
) -> Result<Value> {
    let (segments, body) = match &action {
        Action::List { id } => {
            validate_uuid(id)?;
            (
                vec!["translations", id, "reviews"],
                Body::Api(&session.access_token),
            )
        }
        Action::Answer {
            id,
            review_id,
            answer,
            guidance,
            context_scope,
            resolution_message_id,
        } => {
            validate_uuid(id)?;
            validate_uuid(review_id)?;
            if let Some(message_id) = resolution_message_id {
                validate_uuid(message_id)?;
            }
            if answer.trim().is_empty() || answer.chars().count() > 8000 {
                return Err(error(
                    "invalid_input",
                    "An answer must contain 1 to 8000 characters and cannot be blank.",
                ));
            }
            if guidance
                .as_ref()
                .is_some_and(|text| text.trim().is_empty() || text.chars().count() > 8000)
                || (guidance.is_none() && context_scope.is_some())
            {
                return Err(error(
                    "invalid_input",
                    "Reusable guidance must contain 1 to 8000 characters; scope requires guidance.",
                ));
            }
            let mut payload = json!({"answer": answer});
            if let Some(message_id) = resolution_message_id {
                payload["resolution_message_id"] = json!(message_id);
            }
            if let Some(guidance) = guidance {
                payload["guidance"] = json!(guidance);
                if let Some(scope) = context_scope {
                    payload["context_scope"] = json!(scope);
                }
            }
            (
                vec!["translations", id, "reviews", review_id, "answer"],
                Body::ApiJson(&session.access_token, payload),
            )
        }
    };
    network.request(&selection.project_url(session, &segments)?, body)
}
