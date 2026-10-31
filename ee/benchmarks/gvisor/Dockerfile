# Glossia Enterprise License: see ee/LICENSE.md.
# Build context is prepared on the disposable Linux benchmark host, not the repo.
FROM hexpm/elixir:1.18.3-erlang-27.3.4.3-debian-bookworm-20260202-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates util-linux \
    && rm -rf /var/lib/apt/lists/*

ENV ERL_FLAGS="+S 2:2"
WORKDIR /opt/bench
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force && mix deps.get
COPY lib/ lib/
COPY reconcile.exs exercise.exs ./
RUN mix compile --warnings-as-errors

COPY runsc /usr/local/bin/runsc
COPY gvisor-bin/ /usr/local/bin/gvisor-bin/
COPY rootfs.tar /opt/bench/rootfs.tar
COPY preview-runtime.mjs /opt/bench/

# Single-node POSIX fencing survives BEAM restarts against the same PVC.
CMD ["flock", "--nonblock", "/state/writer.lock", "mix", "run", "--no-compile", "reconcile.exs"]
