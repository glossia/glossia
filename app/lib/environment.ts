const environmentVariables = {
  databaseUrl: {
    name: 'DATABASE_URL',
    required: true
  },
  sessionCookieSalt: {
    name: 'SESSION_COOKIE_SALT',
    required: true
  },
  githubAppClentId: {
    name: 'GITHUB_APP_CLIENT_ID',
    required: true
  },
  githubAppClientSecret: {
    name: 'GITHUB_APP_CLIENT_SECRET',
    required: true
  }
}

export function isProduction() {
  return process.env.NODE_ENV === 'production'
}

export function getDatabaseURL() {
  return process.env[environmentVariables.databaseUrl.name] as string
}

export function getSessionCookieSalt(): string {
  return process.env[environmentVariables.sessionCookieSalt.name] as string
}

export function getGitHubAppClientId(): string {
  return process.env[environmentVariables.githubAppClentId.name] as string
}

export function getGitHubAppClientSecret(): string {
  return process.env[environmentVariables.githubAppClientSecret.name] as string
}

export function getGitHubAppCallbackURL(): URL {
  let url = getBaseURL()
  url.pathname = "/auth/github/callback"
  return url
}

export function getBaseURL(): URL {
  if (isProduction()) {
    return new URL("https://app.glossia.ai")
  } else {
    return new URL("http://localhost:3000")
  }
}

export function isTruthy(variable: string | undefined) {
  return ["1", "true", "TRUE", "yes", "YES"].includes(variable ?? "")
}

export function validatePresenceOfRequiredEnvVariables() {
  if (!isTruthy(process.env["GLOSSIA_VALIDATE_VARIABLES_PRESENCE"])) {
    return;
  }
  let missingVariables: string[] = []
  Object.values(environmentVariables).forEach((environmentVariable) => {
    if (environmentVariable.required && !process.env[environmentVariable.name]) {
      missingVariables.push(environmentVariable.name)
    }
  })
  if (missingVariables.length !== 0) {
    throw new Error(`The following environment variables which are required are missing: ${missingVariables.join(", ")}`)
  }
}

