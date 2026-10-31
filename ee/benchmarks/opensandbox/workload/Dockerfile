FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends chromium util-linux iproute2 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/glossia-bench /tmp/glossia/repo/es \
    && printf '%s\n' '{"title":"Original product"}' > /tmp/glossia/repo/es/products.json

# Build with this workload directory as the Docker build context. The parent
# uploads the real PreviewBrowser.source runtime and its config at execution time.
COPY server.mjs start.sh probe.mjs /opt/glossia-bench/
RUN chmod 755 /opt/glossia-bench/start.sh

WORKDIR /tmp/glossia/repo
# OpenSandbox injects execd. No app/CDP port is exposed and no launcher is run
# automatically: the benchmark invokes start.sh once through trusted execd.
