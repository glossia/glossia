defmodule GlossiaEnterprise.Runners.ManagedTest do
  use ExUnit.Case, async: true

  alias GlossiaEnterprise.Runners.Managed

  describe "behaviour compliance" do
    test "implements the Glossia.Runners behaviour" do
      assert Glossia.Runners in Managed.module_info(:attributes)[:behaviour]
    end

    test "reports a distinct pool name from the OSS default" do
      # The OSS default is a DynamicSupervisor keyed on a different atom,
      # so the assertion is that the enterprise pool has its own name.
      assert Managed.pool_name() == GlossiaEnterprise.ManagedRunnerPool
    end
  end

  describe "pool_child_spec/0" do
    setup do
      previous = Application.get_env(:glossia_enterprise, :managed_runner)
      on_exit(fn -> Application.put_env(:glossia_enterprise, :managed_runner, previous || []) end)
      :ok
    end

    test "defaults min above zero so capacity is pre-warmed" do
      Application.put_env(:glossia_enterprise, :managed_runner, [])
      {FLAME.Pool, opts} = Managed.pool_child_spec()
      assert Keyword.fetch!(opts, :min) >= 1
    end

    test "reads sizing from :glossia_enterprise, :managed_runner" do
      Application.put_env(:glossia_enterprise, :managed_runner,
        min: 5,
        max: 40,
        max_concurrency: 3,
        idle_shutdown_after: 600_000,
        timeout: 7_200_000,
        boot_timeout: 240_000,
        log: true,
        k8s: [app_container_name: "web"]
      )

      {FLAME.Pool, opts} = Managed.pool_child_spec()

      assert Keyword.fetch!(opts, :min) == 5
      assert Keyword.fetch!(opts, :max) == 40
      assert Keyword.fetch!(opts, :max_concurrency) == 3
      assert Keyword.fetch!(opts, :idle_shutdown_after) == 600_000
      assert Keyword.fetch!(opts, :timeout) == 7_200_000
      assert Keyword.fetch!(opts, :boot_timeout) == 240_000
      assert Keyword.fetch!(opts, :log) == true
    end

    test "names the pool with a distinct atom for metrics isolation" do
      Application.put_env(:glossia_enterprise, :managed_runner, [])
      {FLAME.Pool, opts} = Managed.pool_child_spec()
      assert Keyword.fetch!(opts, :name) == GlossiaEnterprise.ManagedRunnerPool
    end

    test "selects the k8s backend only when configured for :k8s" do
      Application.put_env(:glossia_enterprise, :managed_runner,
        backend: :k8s,
        k8s: [app_container_name: "web"]
      )

      {FLAME.Pool, opts} = Managed.pool_child_spec()
      assert {FLAMEK8sBackend, _} = Keyword.fetch!(opts, :backend)

      Application.put_env(:glossia_enterprise, :managed_runner, backend: :local)
      {FLAME.Pool, opts} = Managed.pool_child_spec()
      assert :error = Keyword.fetch(opts, :backend)
    end
  end
end
