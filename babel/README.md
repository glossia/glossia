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

## Glossia production data

Babel reaches Glossia through a cluster-only
[Transport Layer Security](https://en.wikipedia.org/wiki/Transport_Layer_Security)
listener, not through a production PostgreSQL connection. The listener has no
ingress route, only Babel can reach its service port, and Glossia rejects this
endpoint on its public listener before authentication is attempted. Each Babel
pod receives a short-lived Kubernetes service-account token with the
`glossia-internal` audience. Glossia verifies the token as a
[JSON Web Token](https://jwt.io/introduction) against the production
[JSON Web Key Set](https://datatracker.ietf.org/doc/html/rfc7517), then checks
the issuer, audience, namespace, service-account name, and lifetime.

The database request is constrained in three layers:

- Only `SELECT`, `WITH`, `EXPLAIN`, and `SHOW` statements are accepted.
- The statement runs in a read-only transaction with a five-second timeout and
  a 200-row response limit.
- Glossia switches to the non-login `glossia_babel_ro` PostgreSQL role, which
  inherits PostgreSQL's
  [`pg_read_all_data`](https://www.postgresql.org/docs/current/predefined-roles.html)
  role and has no write permission.

To verify the deployed connection, run this from an authenticated cluster
terminal:

```bash
kubectl -n babel exec deploy/babel -c web -- \
  /app/bin/babel eval 'IO.inspect(Babel.Glossia.query("SELECT 1 AS connection_ok"))'
```
