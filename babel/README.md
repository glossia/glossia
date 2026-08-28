# Babel

Babel is Glossia's internal operations platform.

## Local development

From the repository root:

```bash
mise install
cd babel
mix phx.server
```

## Worktree-aware development

The development and test PostgreSQL database names, as well as the server
ports, use the stable suffix assigned to the current Git worktree. This allows
each checkout to run Babel independently without colliding with Glossia or
another Babel checkout.

The environment is loaded automatically by `mise`. The relevant values are:

- `BABEL_POSTGRES_DB` for the development database.
- `BABEL_TEST_POSTGRES_DB` for the test database.
- `BABEL_SERVER_PORT` for the development server.
- `BABEL_TEST_PORT` for the test server.

After starting the server, visit `http://localhost:${BABEL_SERVER_PORT}`. When
the environment is not loaded, Babel falls back to port `4060` and the
`babel_dev` database.
