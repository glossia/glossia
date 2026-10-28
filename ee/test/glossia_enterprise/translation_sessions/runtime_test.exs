defmodule GlossiaEnterprise.TranslationSessions.RuntimeTest do
  use ExUnit.Case, async: false

  alias GlossiaEnterprise.TranslationSessions.{Job, Runtime}

  setup do
    previous = System.get_env() |> Map.take(["GLOSSIA_TRANSLATION_JOB", "GLOSSIA_ISOLATED_CHILD"])
    System.delete_env("GLOSSIA_TRANSLATION_JOB")
    System.delete_env("GLOSSIA_ISOLATED_CHILD")

    on_exit(fn ->
      System.delete_env("GLOSSIA_TRANSLATION_JOB")
      System.delete_env("GLOSSIA_ISOLATED_CHILD")
      System.put_env(previous)
    end)
  end

  test "enterprise builds select the isolated runtime and sandbox adapter" do
    assert Glossia.Extensions.translation_runtime() == Runtime
    assert Glossia.Sandbox.adapter() == GlossiaEnterprise.Sandbox.KataAdapter
    assert is_nil(Runtime.children())
  end

  test "a translation job boots without HTTP, queues, or another runner pool" do
    System.put_env("GLOSSIA_TRANSLATION_JOB", "1")
    children = Runtime.children()
    assert Job in children
    refute GlossiaWeb.Endpoint in children
    refute Enum.any?(children, &match?({FLAME.Pool, _}, &1))
    assert {Oban, config} = Enum.find(children, &match?({Oban, _}, &1))
    assert config[:queues] == false
    assert config[:plugins] == false
  end

  test "FLAME owns the isolated child supervision tree" do
    System.put_env("GLOSSIA_ISOLATED_CHILD", "1")
    assert Runtime.children() == []
  end
end
