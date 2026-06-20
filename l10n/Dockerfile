FROM node:24-alpine AS build

WORKDIR /site

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

ARG SITE_URL=https://l10n.md
ENV SITE_URL=${SITE_URL}

RUN npm run validate && ./node_modules/.bin/eleventy

FROM caddy:2.10-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /site/_site /usr/share/caddy

RUN addgroup -S -g 10001 caddy-static \
  && adduser -S -D -H -u 10001 -G caddy-static caddy-static \
  && chown -R caddy-static:caddy-static /config /data /usr/share/caddy

USER caddy-static
