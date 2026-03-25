FROM discourse/discourse:latest

USER root

# Discourse runs backups from inside the app container, so its Postgres client
# tools must stay on the same major version as the external database server.
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client-17 \
 && ln -sf /usr/lib/postgresql/17/bin/pg_dump /usr/local/bin/pg_dump \
 && ln -sf /usr/lib/postgresql/17/bin/pg_restore /usr/local/bin/pg_restore \
 && ln -sf /usr/lib/postgresql/17/bin/psql /usr/local/bin/psql \
 && rm -rf /var/lib/apt/lists/*
