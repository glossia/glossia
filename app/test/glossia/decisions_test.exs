defmodule Glossia.DecisionsTest do
  use Glossia.DataCase, async: true

  alias Glossia.Decisions
  alias Glossia.LLMModels
  alias Glossia.TestHelpers
  alias Glossia.TranslationRouting
  alias Glossia.Translations.Credentials
  alias Glossia.Translations.Context

  setup do
    user = TestHelpers.create_user("decisions@test.com", "decisions")
    %{user: user, account: user.account}
  end

  defp decision_attrs(handle),
    do: %{
      handle: handle,
      category: "decision",
      model: "typesafe/jev-latest",
      api_key: "decision-secret"
    }

  test "configured decision credentials reach the native provider", %{
    user: user,
    account: account
  } do
    {:ok, _} = LLMModels.create_model(account, user, decision_attrs("quality"))
    configuration = Decisions.configuration(account)

    Req.Test.expect(__MODULE__, fn conn ->
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer decision-secret"]
      assert conn.request_path == "/v1/systemone"
      Req.Test.json(conn, %{model: "jev-1.13.0", answers: %{}})
    end)

    assert {:ok, %{"model" => "jev-1.13.0"}} =
             Decisions.evaluate(account, configuration, %{}, %{},
               plug: {Req.Test, __MODULE__},
               credential_node: node()
             )

    Req.Test.verify!(__MODULE__)
  end

  test "changes during a run fail rather than silently evaluating with a different configuration",
       %{user: user, account: account} do
    {:ok, model} = LLMModels.create_model(account, user, decision_attrs("quality"))
    configuration = Decisions.configuration(account)
    {:ok, _} = LLMModels.update_model(account, user, model, %{decision_min_score: 8.0})

    assert {:error, :decision_configuration_changed} =
             Decisions.evaluate(account, configuration, %{}, %{})
  end

  test "making the current default explicit does not replace it", %{user: user, account: account} do
    {:ok, _} = LLMModels.create_model(account, user, decision_attrs("alpha"))

    {:ok, zeta} =
      LLMModels.create_model(account, user, Map.put(decision_attrs("zeta"), :default, true))

    assert {:ok, _} = LLMModels.update_model(account, user, zeta, %{default: true})
    assert LLMModels.default_model(account, "decision").id == zeta.id
  end

  test "routed generative models cannot be converted to decision models", %{
    user: user,
    account: account
  } do
    {:ok, writer} =
      LLMModels.create_model(account, user, %{
        handle: "writer",
        model: "openai/gpt-4o",
        api_key: "secret"
      })

    {:ok, _} = TranslationRouting.create_rule(account, user, writer, %{"target_locale" => "es"})

    assert {:error, changeset} =
             LLMModels.update_model(account, user, writer, %{
               category: "decision",
               model: "typesafe/jev-latest"
             })

    assert Keyword.has_key?(changeset.errors, :category)
    assert LLMModels.default_model(account).id == writer.id
  end

  test "defaults remain independent through creation, replacement, and deletion", %{
    user: user,
    account: account
  } do
    assert {:ok, decision} = LLMModels.create_model(account, user, decision_attrs("quality"))
    assert is_nil(LLMModels.default_model(account))
    assert LLMModels.default_model(account, "decision").id == decision.id

    assert {:ok, generative} =
             LLMModels.create_model(account, user, %{
               handle: "writer",
               model: "openai/gpt-4o",
               api_key: "writer-secret"
             })

    assert generative.default
    assert {:ok, second} = LLMModels.create_model(account, user, decision_attrs("other-quality"))
    assert {:ok, _} = LLMModels.update_model(account, user, second, %{default: true})
    assert LLMModels.default_model(account).id == generative.id
    assert LLMModels.default_model(account, "decision").id == second.id
    assert {:ok, _} = LLMModels.delete_model(account, user, second)
    assert LLMModels.default_model(account, "decision").id == decision.id
    assert LLMModels.default_model(account).id == generative.id
  end

  test "invalid writes retain form actions and deleted models return changesets", %{
    user: user,
    account: account
  } do
    assert {:error, %{action: :insert}} =
             LLMModels.create_model(account, user, decision_attrs("X"))

    {:ok, model} = LLMModels.create_model(account, user, decision_attrs("quality"))

    assert {:error, %{action: :update}} =
             LLMModels.update_model(account, user, model, %{decision_min_score: 11})

    {:ok, _} = LLMModels.delete_model(account, user, model)

    assert {:error, %{action: :update}} =
             LLMModels.update_model(account, user, model, %{handle: "new-quality"})

    assert {:error, %{action: :delete}} = LLMModels.delete_model(account, user, model)
  end

  test "moving a default between categories repairs both category defaults", %{
    user: user,
    account: account
  } do
    {:ok, writer} =
      LLMModels.create_model(account, user, %{
        handle: "writer",
        model: "openai/gpt-4o",
        api_key: "secret"
      })

    {:ok, replacement} =
      LLMModels.create_model(account, user, %{
        handle: "replacement",
        model: "openai/gpt-4o",
        api_key: "secret"
      })

    {:ok, _} = LLMModels.create_model(account, user, decision_attrs("quality"))

    assert {:ok, moved} =
             LLMModels.update_model(account, user, writer, %{
               category: "decision",
               model: "typesafe/jev-latest"
             })

    assert LLMModels.default_model(account, "decision").id == moved.id
    assert LLMModels.default_model(account).id == replacement.id
  end

  test "Jev requires the decision category and valid thresholds", %{user: user, account: account} do
    assert {:error, _} =
             LLMModels.create_model(account, user, %{
               handle: "jev",
               model: "typesafe/jev-latest",
               api_key: "secret"
             })

    for attrs <- [
          %{model: "openai/gpt-4o"},
          %{decision_min_score: 11},
          %{category: "unknown"},
          %{translation_concurrency: 3}
        ] do
      assert {:error, _} =
               LLMModels.create_model(account, user, Map.merge(decision_attrs("quality"), attrs))
    end
  end

  test "decision models cannot write translations or enter locale routing", %{
    user: user,
    account: account
  } do
    {:ok, model} = LLMModels.create_model(account, user, decision_attrs("quality"))
    assert {:error, {:model_not_found, "quality"}} = Credentials.resolve(account, "quality")

    assert {:error, changeset} =
             TranslationRouting.create_rule(account, user, model, %{"target_locale" => "es"})

    assert Keyword.has_key?(changeset.errors, :llm_model_id)
  end

  test "run snapshot includes public evaluator settings without credentials", %{
    user: user,
    account: account
  } do
    {:ok, _} = LLMModels.create_model(account, user, decision_attrs("quality"))
    assert {:ok, snapshot} = Context.snapshot(account)

    assert snapshot.decision_model == %{
             handle: "quality",
             model: "typesafe/jev-latest",
             base_url: nil,
             decision_min_score: 7.0
           }

    refute inspect(snapshot) =~ "decision-secret"

    assert {:ok, %{api_key: "decision-secret"}} =
             Decisions.credential_on(node(), account, "quality")

    other = TestHelpers.create_user("other-decisions@test.com", "other-decisions")
    assert {:error, :decision_model_not_found} = Decisions.credential(other.account, "quality")
  end
end
