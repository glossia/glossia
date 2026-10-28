defmodule Glossia.TranslationSessions.LauncherTest do
  use ExUnit.Case, async: true
  use Mimic

  alias Glossia.Extensions
  alias Glossia.TranslationSessions.{Launcher, LocalRuntime, Translate, TranslateWorker}

  test "local translation runs to completion in the worker process" do
    stub(Extensions, :translation_runtime, fn -> LocalRuntime end)
    caller = self()

    expect(Translate, :run, fn "local-session" ->
      assert self() == caller
      :ok
    end)

    assert :ok = TranslateWorker.perform(%Oban.Job{args: %{"session_id" => "local-session"}})
    assert :ok = Launcher.cancel("local-session")
  end
end
