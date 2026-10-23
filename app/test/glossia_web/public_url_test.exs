defmodule GlossiaWeb.PublicURLTest do
  use ExUnit.Case, async: true
  use GlossiaWeb, :verified_routes
  use Mimic

  alias GlossiaWeb.PublicURL

  test "reads runtime configuration without calling the web endpoint" do
    expected = GlossiaWeb.Endpoint.struct_url()

    reject(&GlossiaWeb.Endpoint.url/0)
    reject(&GlossiaWeb.Endpoint.struct_url/0)
    reject(&GlossiaWeb.Endpoint.path/1)
    reject(&GlossiaWeb.Endpoint.config/2)

    assert PublicURL.base_uri() == expected
  end

  test "explicit public settings override the internal listener address" do
    base_uri =
      PublicURL.base_uri(
        url: [scheme: "https", host: "glossia.ai", port: 443],
        http: [port: 4050]
      )

    assert URI.to_string(base_uri) == "https://glossia.ai"
    assert url(base_uri, ~p"/docs") == "https://glossia.ai/docs"
  end

  test "uses the HTTP listener port for local development" do
    base_uri = PublicURL.base_uri(url: [host: "localhost"], http: [port: 4050])

    assert URI.to_string(base_uri) == "http://localhost:4050"
  end

  test "prefers the HTTPS listener when both listeners are configured" do
    base_uri =
      PublicURL.base_uri(
        url: [host: "glossia.ai"],
        https: [port: 4443],
        http: [port: 4050]
      )

    assert URI.to_string(base_uri) == "https://glossia.ai:4443"
  end

  test "uses standard listener ports when none is configured" do
    assert URI.to_string(PublicURL.base_uri(https: [])) == "https://localhost"
    assert URI.to_string(PublicURL.base_uri(http: [])) == "http://localhost"
    assert URI.to_string(PublicURL.base_uri([])) == "http://localhost"
  end

  test "normalizes string ports from configuration" do
    assert %URI{port: 443} = PublicURL.base_uri(url: [port: "443"])
    assert %URI{port: 4050} = PublicURL.base_uri(http: [port: "4050"])
  end

  test "retains a deployment path prefix in verified links" do
    base_uri =
      PublicURL.base_uri(url: [scheme: "https", host: "glossia.ai", port: 443, path: "/glossia"])

    assert url(base_uri, ~p"/docs") == "https://glossia.ai/glossia/docs"
  end

  test "does not duplicate the leading slash for a root deployment path" do
    base_uri = PublicURL.base_uri(url: [host: "localhost", path: "/"])

    assert base_uri.path == nil
    assert url(base_uri, ~p"/docs") == "http://localhost/docs"
  end
end
