defmodule Glossia.Translations do
  @moduledoc """
  Server-side content translation.

  Owns the translation prompt construction (`Glossia.Translations.Prompt`) and
  the model call (via `tuist/condukt`), so that logic is never shipped to CLI
  clients. Given a single translation work item — source content plus
  locale/format metadata — it returns the translated content and the resolved
  model.

  Two entry points:

    * `translate/2` — one-shot, returns the final text. Used by the HTTP endpoint.
    * `translate_stream/3` — streams each Condukt turn event to an `on_event`
      callback (for live progress in the translation LiveView) while accumulating
      the final text. Used by the server-side translation workflow.

  The resolved `model`/`provider` are returned so callers can fold them into the
  translation cache key and stay correct when the effective model changes.
  """

  @supported_formats ~w(markdown json yaml po text)

  alias Glossia.Accounts.Account
  alias Glossia.Models.ModelIdentifier
  alias Glossia.Translations.Credentials
  alias Glossia.Translations.LLM
  alias Glossia.Translations.Prompt

  @type result :: %{
          text: String.t(),
          model: String.t(),
          model_handle: String.t() | nil,
          provider: String.t()
        }

  @type error ::
          {:missing_field, String.t()}
          | {:invalid_format, String.t()}
          | {:model_not_found, String.t() | nil}
          | {:llm_failed, term()}

  @doc """
  Translates a single work item for `account`.

  `payload` is the (string-keyed) request body:

    * `"model"` - the account model handle to translate with (account default when omitted)
    * `"format"` - `"markdown" | "json" | "yaml" | "po" | "text"` (default `"markdown"`)
    * `"source_language"`, `"language"`, `"locale"` - required display strings
    * `"source_content"` - the content to translate (required)
    * `"context_body"`, `"locale_override_body"` - optional guidance
    * `"custom_prompt"` - optional per-document instructions
    * `"frontmatter_preserved"` - boolean, whether the client re-attaches frontmatter
    * `"last_error"` - optional prior validation error, for self-correcting retries
  """
  @spec translate(Account.t(), map()) :: {:ok, result()} | {:error, error()}
  def translate(%Account{} = account, payload) do
    with {:ok, credential, system_prompt, user_prompt} <- prepare(account, payload) do
      case LLM.run(credential, system_prompt, user_prompt) do
        {:ok, text} -> {:ok, build_result(credential, text)}
        {:error, reason} -> {:error, {:llm_failed, reason}}
      end
    end
  end

  @doc """
  Streams a translation, invoking `on_event` for every Condukt turn event as it
  occurs and returning the accumulated translated text.

  Events forwarded to `on_event/1` (see `Condukt.stream/3`): `:agent_start`,
  `:turn_start`, `{:text, chunk}`, `{:thinking, chunk}`, `{:tool_call, name, id,
  args}`, `{:tool_result, id, result}`, `:turn_end`, `:agent_end`, `:done`, and
  `{:error, reason}`. The final text is the concatenation of the `{:text, _}`
  chunks; a streamed `{:error, reason}` fails the call.
  """
  @spec translate_stream(Account.t(), map(), (term() -> any())) ::
          {:ok, result()} | {:error, error()}
  def translate_stream(%Account{} = account, payload, on_event)
      when is_function(on_event, 1) do
    translate_stream(account, payload, on_event, [])
  end

  @doc """
  Streams a translation while resolving credentials on a designated node.

  The `:credential_node` option is used by isolated repository runners, which
  cannot access the account database directly.
  """
  @spec translate_stream(Account.t(), map(), (term() -> any()), keyword()) ::
          {:ok, result()} | {:error, error() | {:credential_relay_failed, term()}}
  def translate_stream(%Account{} = account, payload, on_event, opts)
      when is_function(on_event, 1) and is_list(opts) do
    with {:ok, credential, system_prompt, user_prompt} <- prepare(account, payload, opts) do
      case LLM.stream(credential, system_prompt, user_prompt, on_event) do
        {:ok, text} -> {:ok, build_result(credential, text)}
        {:error, reason} -> {:error, {:llm_failed, reason}}
      end
    end
  end

  defp prepare(account, payload, opts \\ []) do
    with {:ok, input} <- normalize(payload),
         {:ok, credential} <- resolve_credential(account, input.model, opts) do
      system_prompt = Prompt.build_system_prompt(input)

      user_prompt =
        Prompt.build_user_prompt(
          input.source_language,
          input.locale,
          input.language,
          input.source_content,
          input.last_error
        )

      {:ok, credential, system_prompt, user_prompt}
    end
  end

  defp resolve_credential(account, model_handle, opts) do
    case Keyword.fetch(opts, :credential_node) do
      {:ok, credential_node} -> Credentials.resolve_on(credential_node, account, model_handle)
      :error -> Credentials.resolve(account, model_handle)
    end
  end

  defp build_result(credential, text) do
    %{
      text: text,
      model: credential.model,
      model_handle: credential.handle,
      provider: ModelIdentifier.provider(credential.model),
      source: credential.source
    }
  end

  defp normalize(payload) do
    format = to_string(payload["format"] || "markdown")

    cond do
      format not in @supported_formats -> {:error, {:invalid_format, format}}
      blank?(payload["source_language"]) -> {:error, {:missing_field, "source_language"}}
      blank?(payload["language"]) -> {:error, {:missing_field, "language"}}
      blank?(payload["locale"]) -> {:error, {:missing_field, "locale"}}
      is_nil(payload["source_content"]) -> {:error, {:missing_field, "source_content"}}
      true -> {:ok, build_input(payload, format)}
    end
  end

  defp build_input(payload, format) do
    %{
      format: format,
      source_language: to_string(payload["source_language"]),
      language: to_string(payload["language"]),
      locale: to_string(payload["locale"]),
      source_content: to_string(payload["source_content"]),
      context_body: to_string(payload["context_body"] || ""),
      locale_override_body: to_string(payload["locale_override_body"] || ""),
      frontmatter_preserved: payload["frontmatter_preserved"] == true,
      custom_prompt: payload["custom_prompt"],
      last_error: payload["last_error"],
      model: to_string(payload["model"])
    }
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false
end
