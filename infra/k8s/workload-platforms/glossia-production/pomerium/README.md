# Babel Pomerium access

Pomerium protects `https://babel.glossia.ai` and the temporary-access host at
`https://access.glossia.ai` with Google Workspace. Its policy allows every
authenticated `@glossia.ai` account and does not assign roles.

Before Flux reconciles this configuration, add these values to the
`/kubernetes` Infisical item:

- `POMERIUM_GOOGLE_CLIENT_ID`
- `POMERIUM_GOOGLE_CLIENT_SECRET`
- `POMERIUM_POSTGRES_PASSWORD`

Create a Google [Open Authorization 2.0](https://oauth.net/2/) web client with
this callback URL:

```text
https://authenticate.glossia.ai/oauth2/callback
```

The Pomerium routes forward a signed [JSON Web Token](https://jwt.io/)
assertion. Babel verifies it before recording a temporary access grant. The
temporary-access host forwards a separate assertion to Glossia, which verifies
the signature, issuer, audience, and timestamps before binding the grant to
that employee's Pomerium subject. Glossia grants read-only access only while
the recorded grant remains active.
