use crate::{Result, error, validate_uuid};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use url::Url;

#[derive(Serialize)]
pub(crate) struct Destination {
    id: &'static str,
    title: &'static str,
    symbol: &'static str,
}

pub(crate) const DESTINATIONS: [Destination; 4] = [
    Destination {
        id: "toki",
        title: "Toki",
        symbol: "bubble.left.and.bubble.right",
    },
    Destination {
        id: "translations",
        title: "Translations",
        symbol: "character.bubble",
    },
    Destination {
        id: "analytics",
        title: "Analytics",
        symbol: "chart.bar",
    },
    Destination {
        id: "profile",
        title: "Profile",
        symbol: "person.crop.circle",
    },
];

#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case", deny_unknown_fields)]
pub(crate) enum Action {
    Parse { url: String },
    Link { destination: NavigationDestination },
}

#[derive(Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
enum Screen {
    Toki,
    Conversation,
    NewConversation,
    Translations,
    Translation,
    Analytics,
    Profile,
}

/// A navigation intent only: native clients must still match the signed-in origin,
/// protect drafts, resolve the exact workspace, and let the API enforce access.
#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct NavigationDestination {
    screen: Screen,
    server: String,
    organization: Option<String>,
    project: Option<String>,
    id: Option<String>,
    translation_id: Option<String>,
}

pub(crate) fn invalid_link() -> crate::AuthError {
    error(
        "invalid_link",
        "This Glossia link is invalid or unsupported. Open a supported navigation link with an HTTPS server and the exact workspace.",
    )
}

pub(crate) fn execute(action: Action) -> Result<Value> {
    let mut destination = match action {
        Action::Parse { url } => parse(&url)?,
        Action::Link { destination } => destination,
    };
    destination.server = origin(&destination.server)?.to_string();
    match destination.screen {
        Screen::Profile => {
            if destination.organization.is_some() || destination.project.is_some() {
                return Err(invalid_link());
            }
        }
        _ => {
            handle(destination.organization.as_deref(), false)?;
            handle(destination.project.as_deref(), true)?;
        }
    }
    if matches!(
        destination.screen,
        Screen::Conversation | Screen::Translation
    ) {
        destination.id = Some(uuid(destination.id.as_deref().ok_or_else(invalid_link)?)?);
    } else if destination.id.is_some() {
        return Err(invalid_link());
    }
    if let Some(id) = &destination.translation_id {
        if !matches!(destination.screen, Screen::NewConversation) {
            return Err(invalid_link());
        }
        destination.translation_id = Some(uuid(id)?);
    }
    let mut url = Url::parse("glossia://navigate").map_err(|_| invalid_link())?;
    {
        let mut path = url.path_segments_mut().map_err(|_| invalid_link())?;
        if matches!(destination.screen, Screen::Profile) {
            path.push("profile");
        } else {
            path.push(
                destination
                    .organization
                    .as_deref()
                    .ok_or_else(invalid_link)?,
            )
            .push(destination.project.as_deref().ok_or_else(invalid_link)?);
            match destination.screen {
                Screen::Toki | Screen::Conversation | Screen::NewConversation => {
                    path.push("toki");
                }
                Screen::Translations | Screen::Translation => {
                    path.push("translations");
                }
                Screen::Analytics => {
                    path.push("analytics");
                }
                Screen::Profile => unreachable!(),
            }
            if matches!(destination.screen, Screen::NewConversation) {
                path.push("new");
            } else if let Some(id) = &destination.id {
                path.push(id);
            }
        }
    }
    url.query_pairs_mut()
        .append_pair("server", &destination.server);
    if let Some(id) = &destination.translation_id {
        url.query_pairs_mut().append_pair("translation_id", id);
    }
    if url.as_str().len() > 2048 {
        return Err(invalid_link());
    }
    Ok(json!({"destination": destination, "url": url.as_str()}))
}

fn handle(value: Option<&str>, digit_first: bool) -> Result<()> {
    let value = value.ok_or_else(invalid_link)?;
    let valid_first = value
        .bytes()
        .next()
        .is_some_and(|byte| byte.is_ascii_lowercase() || (digit_first && byte.is_ascii_digit()));
    if !valid_first
        || value.len() > 100
        || value.ends_with('-')
        || !value
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-')
    {
        return Err(invalid_link());
    }
    Ok(())
}

fn uuid(value: &str) -> Result<String> {
    validate_uuid(value).map_err(|_| invalid_link())?;
    Ok(value.to_ascii_lowercase())
}

fn origin(value: &str) -> Result<Url> {
    if !value.bytes().all(|byte| byte.is_ascii_graphic()) || value.contains(['\\', '%']) {
        return Err(invalid_link());
    }
    // Inspect the original authority/path before URL parsing can normalize dot
    // segments, missing slashes, or escaped host characters into another origin.
    let (scheme, rest) = value.split_once("://").ok_or_else(invalid_link)?;
    let (authority, path) = rest.split_once('/').unwrap_or((rest, ""));
    if !scheme.eq_ignore_ascii_case("https")
        || authority.is_empty()
        || authority.ends_with(':')
        || !path.is_empty()
        || !authority
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || b"-_.:[]".contains(&byte))
    {
        return Err(invalid_link());
    }
    let mut url = Url::parse(value).map_err(|_| invalid_link())?;
    if url.scheme() != "https"
        || url.host_str().is_none()
        || !url.username().is_empty()
        || url.password().is_some()
        || url.port() == Some(0)
        || !matches!(url.path(), "" | "/")
        || url.query().is_some()
        || url.fragment().is_some()
    {
        return Err(invalid_link());
    }
    url.set_path("/");
    Ok(url)
}

fn parse(input: &str) -> Result<NavigationDestination> {
    if input.len() > 2048
        || !input.bytes().all(|byte| byte.is_ascii_graphic())
        || input.contains(['\\', '#'])
    {
        return Err(invalid_link());
    }
    // The raw path is intentionally checked BEFORE Url::parse: the URL API
    // removes literal and percent-encoded dot segments during normalization.
    let (base, query) = input.split_once('?').ok_or_else(invalid_link)?;
    let (scheme, rest) = base.split_once("://").ok_or_else(invalid_link)?;
    let (authority, raw_path) = rest.split_once('/').ok_or_else(invalid_link)?;
    if !scheme.eq_ignore_ascii_case("glossia")
        || !authority.eq_ignore_ascii_case("navigate")
        || !raw_path
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'/'))
        || !query.split('&').all(|pair| {
            pair.split_once('=')
                .is_some_and(|(key, _)| matches!(key, "server" | "translation_id"))
        })
    {
        return Err(invalid_link());
    }
    let url = Url::parse(input).map_err(|_| invalid_link())?;
    if url.scheme() != "glossia"
        || !url
            .host_str()
            .is_some_and(|host| host.eq_ignore_ascii_case("navigate"))
        || url.port().is_some()
        || !url.username().is_empty()
        || url.password().is_some()
        || url.fragment().is_some()
        || url.path().strip_prefix('/') != Some(raw_path)
    {
        return Err(invalid_link());
    }
    let mut server = None;
    let mut translation_id = None;
    for (key, value) in url.query_pairs() {
        match key.as_ref() {
            "server" if server.is_none() => server = Some(value.into_owned()),
            "translation_id" if translation_id.is_none() => {
                translation_id = Some(value.into_owned());
            }
            _ => return Err(invalid_link()),
        }
    }
    let mut destination = NavigationDestination {
        screen: Screen::Profile,
        server: server.ok_or_else(invalid_link)?,
        organization: None,
        project: None,
        id: None,
        translation_id,
    };
    let parts: Vec<_> = url.path_segments().ok_or_else(invalid_link)?.collect();
    match parts.as_slice() {
        ["profile"] => {}
        [organization, project, route, tail @ ..] => {
            destination.organization = Some((*organization).to_owned());
            destination.project = Some((*project).to_owned());
            destination.screen = match (*route, tail) {
                ("toki", []) => Screen::Toki,
                ("toki", ["new"]) => Screen::NewConversation,
                ("toki", [id]) => {
                    destination.id = Some((*id).to_owned());
                    Screen::Conversation
                }
                ("translations", []) => Screen::Translations,
                ("translations", [id]) => {
                    destination.id = Some((*id).to_owned());
                    Screen::Translation
                }
                ("analytics", []) => Screen::Analytics,
                _ => return Err(invalid_link()),
            };
        }
        _ => return Err(invalid_link()),
    }
    Ok(destination)
}
