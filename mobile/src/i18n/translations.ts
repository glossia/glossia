export const SUPPORTED_LOCALES = ["en", "es"] as const;

export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number];

const en = {
  app_loading_session: "Loading session...",
  nav_title_sign_in: "Sign in",
  nav_title_accounts: "Accounts",

  common_cancel: "Cancel",
  common_save: "Save",
  common_use_default: "Use default",
  common_system: "System",
  common_soon: "Soon",

  login_eyebrow: "Glossia Mobile",
  login_title: "Sign in with your Glossia account",
  login_subtitle: "Continue securely with OAuth 2.0 Authorization Code + PKCE.",
  login_endpoint_label: "Endpoint: %{baseUrl}",
  login_redirect_uri_label: "Redirect URI: %{redirectUri}",
  login_change_backend_url: "Change backend URL",
  login_continue_to_sign_in: "Continue to sign in",
  login_preparing_sign_in: "Preparing secure sign in...",
  login_warning_redirect_uri_unsupported:
    "This Expo redirect URI is not registered for the first-party client. Use localhost in Expo Go or a development build with the glossia://oauth/callback scheme.",
  login_error_auth_loading: "OAuth request is still loading. Please try again.",
  login_error_no_code: "OAuth response did not include an authorization code.",
  login_error_missing_pkce_verifier: "OAuth request is missing the PKCE verifier.",
  login_error_generic: "Could not complete OAuth sign in.",
  login_error_cancelled: "Sign in was cancelled.",
  login_error_locked: "Another sign-in request is already in progress.",
  login_backend_save_error: "Could not save backend URL.",
  login_backend_modal_title: "Development backend URL",
  login_backend_modal_subtitle: "Default is production. Override this for local network testing.",
  login_language_label: "Language",
  login_backend_input_placeholder: "http://192.168.1.10:4050",
  login_backend_current_override: "Current override: %{value}",
  login_backend_override_none: "none (using default)",

  accounts_error_load: "Could not load accounts.",
  accounts_sign_out: "Sign out",
  accounts_loading: "Loading accounts...",
  accounts_empty_title: "No accounts found",
  accounts_empty_text: 'Your token may not include "account:read" scope.',
  accounts_meta: "%{type} · %{visibility}",

  account_handle_display: "@%{handle}",
  account_meta: "%{type} · %{visibility}",
  account_projects_title: "Projects",
  account_projects_subtitle: "Tap a project to view sections",
  account_error_load_projects: "Could not load projects.",
  account_empty_projects_title: "No projects yet",
  account_empty_projects_text: "Projects for this account will appear here when available.",
  account_upcoming_title: "Project sections (soon)",
  account_upcoming_text: "These sections are prepared in the navigation:",

  section_overview: "Overview",
  section_issues: "Issues",
  section_glossary: "Glossary",
  section_voice: "Voice",

  project_handle_display: "/%{handle}",
  project_sections_label: "Project sections (soon)",
  project_sections_path: "%{accountHandle}/%{projectHandle}",
} as const;

export type TranslationKey = keyof typeof en;

type TranslationDictionary = Record<TranslationKey, string>;

const es: TranslationDictionary = {
  app_loading_session: "Cargando sesión...",
  nav_title_sign_in: "Iniciar sesión",
  nav_title_accounts: "Cuentas",

  common_cancel: "Cancelar",
  common_save: "Guardar",
  common_use_default: "Usar predeterminado",
  common_system: "Sistema",
  common_soon: "Próximamente",

  login_eyebrow: "Glossia Mobile",
  login_title: "Inicia sesión con tu cuenta de Glossia",
  login_subtitle: "Continúa de forma segura con OAuth 2.0 Authorization Code + PKCE.",
  login_endpoint_label: "Endpoint: %{baseUrl}",
  login_redirect_uri_label: "URI de redirección: %{redirectUri}",
  login_change_backend_url: "Cambiar URL del backend",
  login_continue_to_sign_in: "Continuar para iniciar sesión",
  login_preparing_sign_in: "Preparando inicio de sesión seguro...",
  login_warning_redirect_uri_unsupported:
    "Este URI de redirección de Expo no está registrado para el cliente first-party. Usa localhost en Expo Go o una build de desarrollo con el esquema glossia://oauth/callback.",
  login_error_auth_loading: "La solicitud OAuth todavía se está cargando. Inténtalo de nuevo.",
  login_error_no_code: "La respuesta OAuth no incluyó un código de autorización.",
  login_error_missing_pkce_verifier: "La solicitud OAuth no tiene el verificador PKCE.",
  login_error_generic: "No se pudo completar el inicio de sesión OAuth.",
  login_error_cancelled: "Se canceló el inicio de sesión.",
  login_error_locked: "Ya hay otra solicitud de inicio de sesión en progreso.",
  login_backend_save_error: "No se pudo guardar la URL del backend.",
  login_backend_modal_title: "URL del backend de desarrollo",
  login_backend_modal_subtitle:
    "El valor predeterminado es producción. Cambia esto para pruebas en red local.",
  login_language_label: "Idioma",
  login_backend_input_placeholder: "http://192.168.1.10:4050",
  login_backend_current_override: "Override actual: %{value}",
  login_backend_override_none: "ninguno (usando predeterminado)",

  accounts_error_load: "No se pudieron cargar las cuentas.",
  accounts_sign_out: "Cerrar sesión",
  accounts_loading: "Cargando cuentas...",
  accounts_empty_title: "No se encontraron cuentas",
  accounts_empty_text: 'Tu token podría no incluir el scope "account:read".',
  accounts_meta: "%{type} · %{visibility}",

  account_handle_display: "@%{handle}",
  account_meta: "%{type} · %{visibility}",
  account_projects_title: "Proyectos",
  account_projects_subtitle: "Toca un proyecto para ver secciones",
  account_error_load_projects: "No se pudieron cargar los proyectos.",
  account_empty_projects_title: "Todavía no hay proyectos",
  account_empty_projects_text: "Los proyectos de esta cuenta aparecerán aquí cuando estén disponibles.",
  account_upcoming_title: "Secciones del proyecto (próximamente)",
  account_upcoming_text: "Estas secciones ya están preparadas en la navegación:",

  section_overview: "Resumen",
  section_issues: "Issues",
  section_glossary: "Glosario",
  section_voice: "Voz",

  project_handle_display: "/%{handle}",
  project_sections_label: "Secciones del proyecto (próximamente)",
  project_sections_path: "%{accountHandle}/%{projectHandle}",
};

export const translations: Record<SupportedLocale, TranslationDictionary> = {
  en,
  es,
};
