defmodule Glossia.Quality.URLSafetyTest do
  use ExUnit.Case, async: false

  alias Glossia.Quality.URLSafety

  setup do
    previous = Application.get_env(:glossia, Glossia.Quality, [])
    Application.put_env(:glossia, Glossia.Quality, allow_private_origins: false)

    on_exit(fn -> Application.put_env(:glossia, Glossia.Quality, previous) end)
  end

  test "rejects local and non-web origins" do
    assert {:error, :private_origin_not_allowed} =
             URLSafety.validate_origin("http://localhost:4000")

    assert {:error, :private_origin_not_allowed} =
             URLSafety.validate_origin("http://127.0.0.1")

    assert {:error, :private_origin_not_allowed} =
             URLSafety.validate_origin("http://[::1]")

    assert {:error, :invalid_origin} = URLSafety.validate_origin("file:///etc/passwd")
  end

  test "pins approved hosts and denies every other browser resolution" do
    Application.put_env(:glossia, Glossia.Quality, allow_private_origins: true)

    assert {:ok, policy} =
             URLSafety.browser_policy(%{
               "en" => "http://localhost:4000",
               "es" => "http://127.0.0.1:4000/es"
             })

    assert policy.pinned_hosts["localhost"] in ["127.0.0.1", "[::1]"]
    assert policy.pinned_hosts["127.0.0.1"] == "127.0.0.1"
    assert policy.resolver_rules =~ "MAP localhost "
    assert String.ends_with?(policy.resolver_rules, "MAP * ~NOTFOUND")
  end
end
