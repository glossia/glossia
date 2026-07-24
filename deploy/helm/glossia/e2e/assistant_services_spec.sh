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

Describe 'Glossia chart assistant services'
  It 'renders analytics delivery and read-only assistant workloads'
    When call render_assistant_services
    The status should be success
    The stdout should include 'name: GLOSSIA_SMOLANALYTICS_URL'
    The stdout should include 'image: "ghcr.io/arjun0606/smolanalytics:v0.9.11"'
    The stdout should include 'image: "nousresearch/hermes-agent:v2026.7.20"'
    The stdout should include 'image: "grafana/mcp-grafana:0.17.2"'
    The stdout should include 'url: http://127.0.0.1:8000/mcp'
    The stdout should include '- --disable-write'
    The stdout should include '- mcp-analytics'
    The stdout should include '- instrumentation_health'
  End

  It 'rejects Hermes without its analytics service'
    When call render_hermes_without_analytics
    The status should be failure
    The stderr should include 'smolanalytics.enabled must be true when hermes.enabled=true'
  End
End
