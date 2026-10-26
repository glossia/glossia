use crate::{PendingLogin, Registration, Session, Transport, error, navigation, toki, workspace};
use serde::Deserialize;
use serde_json::{Value, json};
use std::ffi::{CStr, CString, c_char};

#[derive(Deserialize)]
#[serde(tag = "operation", rename_all = "snake_case")]
enum Command {
    Begin {
        server: String,
        registration: Option<Registration>,
    },
    ValidateCallback {
        pending: PendingLogin,
        callback: String,
    },
    Complete {
        pending: PendingLogin,
        callback: String,
    },
    Restore {
        session: Session,
    },
    Workspace {
        session: Session,
        #[serde(default)]
        selection: workspace::Selection,
    },
    Resource {
        session: Session,
        #[serde(default)]
        selection: workspace::Selection,
        resource: workspace::Resource,
        #[serde(default = "workspace::default_page")]
        page: u32,
        #[serde(default = "crate::analytics::default_days")]
        days: u32,
    },
    FluentLanguages {
        session: Session,
        #[serde(flatten)]
        input: crate::profile::FluentLanguages,
    },
    Conversation {
        session: Session,
        selection: workspace::Selection,
        #[serde(flatten)]
        action: toki::Action,
    },
    Translation {
        session: Session,
        selection: workspace::Selection,
        id: String,
    },
    TranslationReviews {
        session: Session,
        selection: workspace::Selection,
        #[serde(flatten)]
        action: crate::reviews::Action,
    },
    TranslationLive {
        #[serde(flatten)]
        action: crate::translation_live::Action,
    },
    Navigation {
        #[serde(flatten)]
        action: navigation::Action,
    },
    Themes {
        server: String,
    },
    ValidateThemes {
        catalog: Value,
    },
    Push {
        session: Session,
        #[serde(flatten)]
        action: crate::push::Action,
    },
    Destinations,
}

pub fn execute(input: &str) -> String {
    execute_using(&crate::Network, input)
}

pub(crate) fn execute_using(network: &impl Transport, input: &str) -> String {
    let result =
        std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| -> crate::Result<Value> {
            if input.len() > 1024 * 1024 {
                return Err(crate::invalid());
            }
            let command: Command = serde_json::from_str(input).map_err(|_| {
                if serde_json::from_str::<Value>(input)
                    .ok()
                    .is_some_and(|value| value["operation"] == "navigation")
                {
                    navigation::invalid_link()
                } else {
                    crate::invalid()
                }
            })?;
            match command {
                Command::Begin {
                    server,
                    registration,
                } => serde_json::to_value(crate::begin_using(network, &server, registration)?),
                Command::ValidateCallback { pending, callback } => {
                    crate::callback_code(&pending, &callback)?;
                    return Ok(json!({}));
                }
                Command::Complete { pending, callback } => {
                    serde_json::to_value(crate::complete_using(network, pending, &callback)?)
                }
                Command::Restore { session } => {
                    serde_json::to_value(crate::restore_using(network, session)?)
                }
                Command::Workspace { session, selection } => {
                    return workspace::load(network, session, selection);
                }
                Command::Resource {
                    session,
                    selection,
                    resource,
                    page,
                    days,
                } => return workspace::resource(network, session, selection, resource, page, days),
                Command::Conversation {
                    session,
                    selection,
                    action,
                } => {
                    return toki::conversation(network, &session, &selection, action);
                }
                Command::FluentLanguages { session, input } => {
                    return crate::profile::save_languages(network, &session, input);
                }
                Command::Translation {
                    session,
                    selection,
                    id,
                } => return crate::translations::show(network, &session, &selection, &id),
                Command::TranslationReviews {
                    session,
                    selection,
                    action,
                } => {
                    return crate::reviews::execute(network, &session, &selection, action);
                }
                Command::TranslationLive { action } => {
                    return crate::translation_live::execute(action);
                }
                Command::Navigation { action } => return navigation::execute(action),
                Command::Themes { server } => return crate::themes::fetch(network, &server),
                Command::ValidateThemes { catalog } => return crate::themes::validate(catalog),
                Command::Push { session, action } => {
                    return crate::push::execute(network, session, action);
                }
                Command::Destinations => {
                    return Ok(json!({"destinations": crate::navigation::DESTINATIONS}));
                }
            }
            .map_err(|_| crate::invalid())
        }))
        .unwrap_or_else(|_| Err(error("internal", "Could not complete the request.")));
    match result {
        Ok(value) => json!({"ok": value}).to_string(),
        Err(error) => json!({"error": error}).to_string(),
    }
}

/// # Safety
/// Input must be a live NUL-terminated UTF-8 string for the duration of this call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn glossia_core_execute(input: *const c_char) -> *mut c_char {
    let output = if input.is_null() {
        json!({"error": crate::invalid()}).to_string()
    } else {
        // SAFETY: the caller lends a live C string for this call.
        match unsafe { CStr::from_ptr(input) }.to_str() {
            Ok(input) => execute(input),
            Err(_) => json!({"error": crate::invalid()}).to_string(),
        }
    };
    CString::new(output).expect("JSON escapes NUL").into_raw()
}

/// # Safety
/// Pass a result allocated by glossia_core_execute exactly once, or null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn glossia_core_free(output: *mut c_char) {
    if !output.is_null() {
        // SAFETY: output came from CString::into_raw above.
        drop(unsafe { CString::from_raw(output) });
    }
}

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
pub extern "system" fn Java_ai_glossia_mobile_GlossiaCore_execute(
    mut env: jni::JNIEnv,
    _instance: jni::objects::JObject,
    input: jni::objects::JString,
) -> jni::sys::jstring {
    let output = match env.get_string(&input) {
        Ok(input) => execute(&String::from(input)),
        Err(_) => return std::ptr::null_mut(),
    };
    env.new_string(output)
        .map_or(std::ptr::null_mut(), |value| value.into_raw())
}
