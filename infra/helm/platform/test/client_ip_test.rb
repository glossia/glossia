require "json"
require "minitest/autorun"
require "open3"
require "yaml"

class ClientIPTest < Minitest::Test
  ROOT = File.expand_path("../../../..", __dir__)
  CHART = File.join(ROOT, "infra/helm/platform")
  ANNOTATION = "load-balancer.hetzner.cloud/uses-proxyprotocol"

  def render(*values, overrides: [], chart: CHART)
    Open3.capture3(
      "helm", "template", "platform", chart, "--namespace", "platform",
      *values.flat_map { |file| ["--values", File.join(ROOT, file)] },
      *overrides.flat_map { |value| ["--set-string", value] }
    )
  end

  def assert_proxy_protocol(values, expected, overrides: [])
    output, error, status = render(*values, overrides: overrides)
    assert status.success?, error
    resources = YAML.load_stream(output).compact
    service = resources.find { |r| r["kind"] == "Service" && r.dig("metadata", "name") == "platform-ingress-nginx-controller" }
    config = resources.find { |r| r["kind"] == "ConfigMap" && r.dig("metadata", "name") == "platform-ingress-nginx-controller" }

    refute_nil service
    refute_nil config
    assert_equal expected, service.dig("metadata", "annotations", ANNOTATION) == "true"
    assert_equal expected, config.dig("data", "use-proxy-protocol") == "true"
    assert_equal "true", config.dig("data", "use-forwarded-headers")
    assert_equal "true", config.dig("data", "compute-full-forwarded-for")
  end

  def test_generic_chart_does_not_require_a_proxy_protocol_load_balancer
    assert_proxy_protocol([], false)
  end

  def test_hetzner_pairs_sender_and_receiver
    assert_proxy_protocol(["infra/helm/platform/values-hetzner.yaml"], true)
  end

  def test_production_flux_values_preserve_client_ips
    release = YAML.load_file(
      File.join(ROOT, "infra/k8s/workload-platforms/glossia-production/platform-helmrelease.yaml")
    )
    assert_proxy_protocol(release.fetch("spec").fetch("chart").fetch("spec").fetch("valuesFiles"), true)
  end

  def test_observability_keeps_the_hetzner_pair
    assert_proxy_protocol([
      "infra/helm/platform/values-hetzner.yaml",
      "infra/helm/platform/values-observability.yaml"
    ], true)
  end

  def test_explicit_false_false_rollback_is_supported
    assert_proxy_protocol(
      ["infra/helm/platform/values-hetzner.yaml"], false,
      overrides: [
        "ingress-nginx.controller.config.use-proxy-protocol=false",
        "ingress-nginx.controller.service.annotations.load-balancer\\.hetzner\\.cloud/uses-proxyprotocol=false"
      ]
    )
  end

  def test_authenticated_access_route_strips_caller_supplied_ip_headers
    output, error, status = render(
      "deploy/helm/glossia/values-production.yaml",
      chart: File.join(ROOT, "deploy/helm/glossia")
    )
    assert status.success?, error
    ingress = YAML.load_stream(output).compact.find do |resource|
      resource["kind"] == "Ingress" &&
        resource.dig("metadata", "labels", "app.kubernetes.io/component") == "pomerium-access"
    end
    refute_nil ingress
    removed_headers = JSON.parse(
      ingress.dig("metadata", "annotations", "ingress.pomerium.io/remove_request_headers")
    )
    assert_equal %w[cf-connecting-ip cf-ipcountry x-real-ip], removed_headers.map(&:downcase).sort
  end

  def test_disabling_only_the_receiver_is_rejected
    _output, error, status = render(
      "infra/helm/platform/values-hetzner.yaml",
      overrides: ["ingress-nginx.controller.config.use-proxy-protocol=false"]
    )
    refute status.success?
    assert_includes error, "must match"
  end

  def test_disabling_only_the_sender_is_rejected
    _output, error, status = render(
      "infra/helm/platform/values-hetzner.yaml",
      overrides: ["ingress-nginx.controller.service.annotations.load-balancer\\.hetzner\\.cloud/uses-proxyprotocol=false"]
    )
    refute status.success?
    assert_includes error, "must match"
  end
end
