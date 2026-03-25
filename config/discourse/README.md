# Discourse image

The production Discourse deployment uses a custom image defined in
`config/discourse/Dockerfile`.

Reason: Discourse creates backups from inside the app container, so `pg_dump`,
`pg_restore`, and `psql` in that container must match the major version of the
external Postgres server. The `discourse-postgres` accessory is currently on
Postgres 17, so this image installs `postgresql-client-17`.

Build and push the image before deploying changes to the `discourse` accessory:

```bash
docker build -f config/discourse/Dockerfile -t 89.167.60.202:5000/glossia/discourse:pg17 .
docker push 89.167.60.202:5000/glossia/discourse:pg17
```

When bumping `discourse-postgres` to a new Postgres major version, update both:

- `config/deploy.yml`
- `config/discourse/Dockerfile`
