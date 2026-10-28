# syntax=docker/dockerfile:1.7
# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=debian
# https://hub.docker.com/_/debian?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bookworm-20260202-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: https://pkgs.org/search/?q=telefonBuch
#
ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3.4.3
ARG DEBIAN_VERSION=bookworm-20260202-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
ARG GLOSSIA_EDITION=core

# BuildKit prunes the unselected source stage. A core build does not resolve
# the ee context and needs no enterprise files or enterprise license.
FROM ${RUNNER_IMAGE} AS source-core
RUN mkdir -p /ee /enterprise-licenses

FROM source-core AS source-enterprise
COPY --from=ee . /ee
COPY --from=ee LICENSE.md /enterprise-licenses/
COPY --from=ee licenses /enterprise-licenses/third-party/

FROM source-${GLOSSIA_EDITION} AS edition-source

FROM rust:1-bookworm AS cli_builder

WORKDIR /cli
COPY --from=cli Cargo.toml Cargo.lock ./
COPY --from=cli src src
RUN cargo build --release --bin glossia

FROM node:22-bookworm-slim AS node_runtime

FROM ${BUILDER_IMAGE} AS builder

COPY --from=node_runtime /usr/local/ /usr/local/

# install build dependencies. curl + ca-certificates are needed to bootstrap
# rustup below.
RUN apt-get update -y && apt-get install -y build-essential git curl ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Rust for building mdex_native from source (see MDEX_NATIVE_BUILD below).
# rustup's stable is used instead of Debian apt's rustc because apt ships an
# older version that cannot read the Cargo.lock v4 used by upstream crates.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"
ARG GLOSSIA_EDITION
ENV GLOSSIA_EDITION=${GLOSSIA_EDITION}
ARG GLOSSIA_VERSION=0.1.0
ENV GLOSSIA_VERSION=${GLOSSIA_VERSION}
# mdex_native's precompiled variant selector falls back to `legacy_cpu_lumis`
# on CPUs that miss any of avx/fma, and that variant is not always published
# as a precompiled artifact — the without-Lumis binary is what actually gets
# downloaded, and every content page then fails at compile time with "Lumis
# is not enabled". Force the source build instead.
ENV MDEX_NATIVE_BUILD=true
# Lumis is also a native dependency. Its precompiled release download can
# fail independently of mdex_native, so use the Rust toolchain already here
# rather than depending on that additional binary download during releases.
ENV LUMIS_BUILD=true

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib
COPY --from=edition-source /ee /ee

# Credo checks are development-only and depend on Credo, which is excluded
# from production dependencies.
RUN rm -rf lib/glossia/credo_checks

COPY assets/package.json assets/aube-lock.yaml assets/
RUN npm install --prefix assets --ignore-scripts

COPY assets assets

COPY --from=sdk web /sdk/web

# Compile the project (needed before assets for colocated hooks)
RUN mix compile

# compile assets
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

COPY --from=node_runtime /usr/local/ /usr/local/

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates chromium git curl \
  && npm install -g opencode-ai@1.17.15 @openai/codex@0.144.5 @anthropic-ai/claude-code@2.1.214 \
  && npm cache clean --force \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# kubectl for the Kata sandbox adapter's exec + cp operations. Pinned to
# match the workload cluster's minor version so the API surface stays aligned;
# nothing in the sandbox path depends on a newer subcommand.
RUN ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/') \
 && curl -fsSL "https://dl.k8s.io/release/v1.34.0/bin/linux/${ARCH}/kubectl" \
    -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl

ENV XDG_CONFIG_HOME=/tmp/.chromium
ENV XDG_CACHE_HOME=/tmp/.chromium

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/glossia ./
COPY --from=cli_builder /cli/target/release/glossia /usr/local/bin/glossia
COPY --from=licensing LICENSE.md LICENSE-APACHE /app/licenses/
COPY --from=edition-source /enterprise-licenses /app/licenses/enterprise/

USER nobody

# Verify that Chromium can start as the unprivileged runtime user. Docker build
# sandboxes do not permit Chromium's own namespace sandbox, so disable it only
# for this build-time smoke check.
RUN chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage --dump-dom about:blank >/dev/null

CMD ["/app/bin/start"]
