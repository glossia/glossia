const environmentVariables = {
  databaseUrl: {
    name: 'DATABASE_URL',
    required: true
  },
  sessionCookieSalt: {
    name: 'SESSION_COOKIE_SALT',
    required: true
  }
}

export function getDatabaseURL() {
  return process.env[environmentVariables.databaseUrl.name] as string
}

export function getSessionCookieSalt(): string {
  return process.env[environmentVariables.sessionCookieSalt.name] as string
}

export function validatePresenceOfRequiredEnvVariables() {
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

