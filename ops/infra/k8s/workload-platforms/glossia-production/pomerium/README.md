# Babel Pomerium access

Pomerium protects `https://babel.glossia.ai` with Google Workspace. Its policy
allows every authenticated `@glossia.ai` account and does not assign roles.

Before Flux reconciles this configuration, add these values to the
`/kubernetes` Infisical item:

- `POMERIUM_GOOGLE_CLIENT_ID`
- `POMERIUM_GOOGLE_CLIENT_SECRET`
- `POMERIUM_POSTGRES_PASSWORD`

Create a Google [Open Authorization 2.0](https://oauth.net/2/) web client with
this callback URL:

```text
https://authenticate-babel.glossia.ai/oauth2/callback
```

The Pomerium route forwards a signed [JSON Web Token](https://jwt.io/)
assertion to Babel. Babel verifies its signature, issuer, audience, and
timestamps with Pomerium's public key, accepts traffic only from the Pomerium
pods, and creates its local account record the first time that person visits
the service.
