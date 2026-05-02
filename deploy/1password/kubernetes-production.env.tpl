# 1Password secret references for the production Kubernetes deploy path.
# Expected layout:
#   vault: glossia-production
#   item: kubernetes
#
# Required fields must exist. Optional integrations can be omitted entirely;
# the loader skips missing optional fields automatically.

K8S_KUBECONFIG_B64=op://glossia-production/kubernetes/K8S_KUBECONFIG_B64
POSTGRES_PASSWORD=op://glossia-production/kubernetes/POSTGRES_PASSWORD
SECRET_KEY_BASE=op://glossia-production/kubernetes/SECRET_KEY_BASE
METRICS_BEARER_TOKEN=op://glossia-production/kubernetes/METRICS_BEARER_TOKEN
OPS_AUTH_PASSWORD=op://glossia-production/kubernetes/OPS_AUTH_PASSWORD
SMTP_HOST=op://glossia-production/kubernetes/SMTP_HOST
SMTP_PORT=op://glossia-production/kubernetes/SMTP_PORT
SMTP_USERNAME=op://glossia-production/kubernetes/SMTP_USERNAME
SMTP_PASSWORD=op://glossia-production/kubernetes/SMTP_PASSWORD
GF_SECURITY_ADMIN_PASSWORD=op://glossia-production/kubernetes/GF_SECURITY_ADMIN_PASSWORD
CLOUDFLARE_API_TOKEN=op://glossia-production/kubernetes/CLOUDFLARE_API_TOKEN
CLOUDFLARE_ZONE_ID=op://glossia-production/kubernetes/CLOUDFLARE_ZONE_ID
GHCR_PULL_USERNAME=op://glossia-production/kubernetes/GHCR_PULL_USERNAME
GHCR_PULL_TOKEN=op://glossia-production/kubernetes/GHCR_PULL_TOKEN
ENCRYPTION_KEY=op://glossia-production/kubernetes/ENCRYPTION_KEY
SENTRY_DSN=op://glossia-production/kubernetes/SENTRY_DSN
SENTRY_DSN_JS=op://glossia-production/kubernetes/SENTRY_DSN_JS
GITHUB_CLIENT_ID=op://glossia-production/kubernetes/GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=op://glossia-production/kubernetes/GITHUB_CLIENT_SECRET
GITHUB_WEBHOOK_SECRET=op://glossia-production/kubernetes/GITHUB_WEBHOOK_SECRET
GITHUB_APP_ID=op://glossia-production/kubernetes/GITHUB_APP_ID
GITHUB_APP_PRIVATE_KEY=op://glossia-production/kubernetes/GITHUB_APP_PRIVATE_KEY
GITHUB_APP_SLUG=op://glossia-production/kubernetes/GITHUB_APP_SLUG
GITLAB_CLIENT_ID=op://glossia-production/kubernetes/GITLAB_CLIENT_ID
GITLAB_CLIENT_SECRET=op://glossia-production/kubernetes/GITLAB_CLIENT_SECRET
GITLAB_WEBHOOK_SECRET=op://glossia-production/kubernetes/GITLAB_WEBHOOK_SECRET
S3_ACCESS_KEY_ID=op://glossia-production/kubernetes/S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY=op://glossia-production/kubernetes/S3_SECRET_ACCESS_KEY
S3_ENDPOINT=op://glossia-production/kubernetes/S3_ENDPOINT
S3_REGION=op://glossia-production/kubernetes/S3_REGION
S3_BUCKET=op://glossia-production/kubernetes/S3_BUCKET
