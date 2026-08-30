render_clickhouse_babel() {
  helm template glossia "${CHART_DIR:-deploy/helm/glossia}" \
    --namespace glossia \
    --set externalSecrets.enabled=true \
    --set clickhouse.babelReadonly.enabled=true
}

Describe 'Glossia chart Babel ClickHouse access'
  It 'renders a restricted ClickHouse user and private credential flow'
    When call render_clickhouse_babel
    The status should be success
    The stdout should include 'name: glossia-clickhouse-babel'
    The stdout should include 'name: GLOSSIA_BABEL_CLICKHOUSE_PASSWORD'
    The stdout should include 'glossia_babel_clickhouse_ro:'
    The stdout should include 'GRANT SELECT ON glossia.*'
    The stdout should include 'readonly: 1'
    The stdout should include 'max_execution_time: 5'
    The stdout should include 'GLOSSIA_CLICKHOUSE_READONLY_URL:'
  End
End
