render_assistant_services() {
  helm template glossia "${CHART_DIR:-deploy/helm/glossia}" \
    --namespace glossia \
    --set smolanalytics.enabled=true \
    --set hermes.enabled=true
}

render_hermes_without_analytics() {
  helm template glossia "${CHART_DIR:-deploy/helm/glossia}" \
    --namespace glossia \
    --set hermes.enabled=true
}

# Emit only documents whose metadata.name is glossia-hermes (the PVC, the
# headless Service, and the StatefulSet). Scoping by name keeps the assertions
# from being cross-matched by smolanalytics' legitimate Recreate strategy or by
# the app's own headless Service in the same combined render. Documents are
# delimited by a line holding exactly `---`.
render_hermes_statefulset() {
  render_assistant_services |
    awk 'BEGIN { doc=""; in_hermes=0 }
      /^---$/ {
        if (in_hermes) printf "%s", doc
        doc=""; in_hermes=0; next
      }
      { doc = doc $0 "\n" }
      /name: glossia-hermes/ { in_hermes=1 }
      END { if (in_hermes) printf "%s", doc }'
}

Describe 'Glossia chart assistant services'
  It 'renders analytics delivery and read-only assistant workloads'
    When call render_assistant_services
    The status should be success
    The stdout should include 'kind: StatefulSet'
    The stdout should include 'name: GLOSSIA_SMOLANALYTICS_URL'
    The stdout should include 'image: "ghcr.io/arjun0606/smolanalytics:v0.9.11"'
    The stdout should include 'image: "nousresearch/hermes-agent:v2026.7.20"'
    The stdout should include 'image: "grafana/mcp-grafana:0.17.2"'
    The stdout should include 'provider: "custom:together"'
    The stdout should include 'default: "MiniMaxAI/MiniMax-M3"'
    The stdout should include 'base_url: "https://api.together.ai/v1"'
    The stdout should include 'key_env: "TOGETHER_API_KEY"'
    The stdout should include '- name: TOGETHER_API_KEY'
    The stdout should include 'url: http://127.0.0.1:8000/mcp'
    The stdout should include '- --disable-write'
    The stdout should include '- mcp-analytics'
    The stdout should include '- instrumentation_health'
  End

  It 'keeps Hermes as an OnDelete StatefulSet with a matching headless Service'
    When call render_hermes_statefulset
    The status should be success
    The stdout should include 'kind: StatefulSet'
    The stdout should include 'serviceName: glossia-hermes'
    The stdout should include 'updateStrategy:'
    The stdout should include 'type: OnDelete'
    # Guard the two invariants this spec exists to protect: the headless Service
    # that carries the StatefulSet identity, and that Hermes is NOT a Recreate
    # Deployment (which is what used to tear the bot down on every deploy).
    The stdout should include 'clusterIP: None'
    The stdout should include 'publishNotReadyAddresses: true'
    The stdout should not include 'type: Recreate'
  End

  It 'rejects Hermes without its analytics service'
    When call render_hermes_without_analytics
    The status should be failure
    The stderr should include 'smolanalytics.enabled must be true when hermes.enabled=true'
  End
End
