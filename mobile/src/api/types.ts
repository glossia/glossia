export interface OAuthTokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  refresh_token?: string;
  id_token?: string;
}

export interface AccountSummary {
  handle: string;
  type: string;
  visibility: string;
}

export interface AccountsResponse {
  accounts: AccountSummary[];
}

export interface ProjectSummary {
  handle: string;
  name: string;
}

export interface ProjectsResponse {
  projects: ProjectSummary[];
}
