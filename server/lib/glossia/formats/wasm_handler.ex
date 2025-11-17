defmodule Glossia.Formats.WasmHandler do
  @moduledoc """
  Executes Wasm-based format handlers using Wasmex.

  Handlers are loaded from priv/wasm/zig-out/build/*.wasm and cached in an ETS table.
  """

  require Logger

  @wasm_dir "priv/wasm/zig-out/build"

  # ETS table for caching loaded Wasm modules
  @table_name :wasm_handlers

  @doc """
  Initializes the Wasm handler system.
  Creates ETS table for caching modules.
  """
  def init do
    unless :ets.whereis(@table_name) != :undefined do
      :ets.new(@table_name, [:named_table, :public, read_concurrency: true])
    end
    :ok
  end

  @doc """
  Loads a Wasm handler module by name.
  Modules are cached after first load.
  """
  def load_handler(name) when is_binary(name) do
    case :ets.lookup(@table_name, name) do
      [{^name, instance}] when is_pid(instance) ->
        # Check if cached instance is still alive
        if Process.alive?(instance) do
          {:ok, instance}
        else
          # Reload if process died
          load_and_cache_handler(name)
        end

      [] ->
        load_and_cache_handler(name)
    end
  end

  defp load_and_cache_handler(name) do
    wasm_path = Path.join([@wasm_dir, "#{name}.wasm"])
    abs_path = Path.expand(wasm_path)

    case File.exists?(abs_path) do
      true ->
        case Wasmex.start_link(%{bytes: File.read!(abs_path)}) do
          {:ok, instance} ->
            :ets.insert(@table_name, {name, instance})
            Logger.debug("Loaded Wasm handler: #{name}")
            {:ok, instance}

          {:error, reason} ->
            Logger.error("Failed to load Wasm handler #{name}: #{inspect(reason)}")
            {:error, :load_failed}
        end

      false ->
        Logger.error("Wasm handler not found: #{abs_path}")
        {:error, :not_found}
    end
  end

  @doc """
  Calls validate function on the handler.
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate(handler_name, content) when is_binary(content) do
    # Handle empty content
    if content == "" do
      :ok
    else
      with {:ok, instance} <- load_handler(handler_name),
           {:ok, store} <- Wasmex.store(instance),
           {:ok, memory} <- Wasmex.memory(instance) do
        # Allocate memory in Wasm
        content_len = byte_size(content)
        {:ok, [content_ptr]} = Wasmex.call_function(instance, "alloc", [content_len])

        # Write content to Wasm memory
        :ok = Wasmex.Memory.write_binary(store, memory, content_ptr, content)

        # Call validate
        {:ok, [result]} = Wasmex.call_function(instance, "validate", [content_ptr, content_len])

        # Free memory
        Wasmex.call_function(instance, "dealloc", [content_ptr, content_len])

        if result == 0 do
          :ok
        else
          {:error, :invalid_content}
        end
      else
        error -> error
      end
    end
  end
end
