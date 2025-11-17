defmodule Glossia.Formats.WasmHandler do
  @moduledoc """
  Executes Wasm-based format handlers using Wasmex.

  In development: Hot-reloads handlers when .wasm files change.
  In production: Caches compiled Wasm bytes for fast instantiation.

  Handlers are loaded from priv/wasm/zig-out/build/*.wasm.
  """

  require Logger

  @wasm_dir "priv/wasm/zig-out/build"

  # ETS table for caching Wasm bytes and metadata
  @table_name :wasm_handlers

  @doc """
  Initializes the Wasm handler system.
  Creates ETS table for caching Wasm bytes.
  """
  def init do
    unless :ets.whereis(@table_name) != :undefined do
      :ets.new(@table_name, [:named_table, :public, read_concurrency: true])
    end
    :ok
  end

  @doc """
  Loads Wasm bytes for a handler, with hot-reload support in dev.
  Returns {:ok, bytes} or {:error, reason}.
  """
  def load_wasm_bytes(name) when is_binary(name) do
    wasm_path = Path.join([@wasm_dir, "#{name}.wasm"])
    abs_path = Path.expand(wasm_path)

    case File.exists?(abs_path) do
      true ->
        if dev_mode?() do
          load_with_hot_reload(name, abs_path)
        else
          load_with_cache(name, abs_path)
        end

      false ->
        Logger.error("Wasm handler not found: #{abs_path}")
        {:error, :not_found}
    end
  end

  # Development: Check file mtime and reload if changed
  defp load_with_hot_reload(name, abs_path) do
    current_mtime = File.stat!(abs_path).mtime

    case :ets.lookup(@table_name, name) do
      [{^name, bytes, cached_mtime}] when cached_mtime == current_mtime ->
        {:ok, bytes}

      _ ->
        # File changed or not cached - reload
        case File.read(abs_path) do
          {:ok, bytes} ->
            :ets.insert(@table_name, {name, bytes, current_mtime})
            Logger.info("Hot-reloaded Wasm handler: #{name}")
            {:ok, bytes}

          {:error, reason} ->
            Logger.error("Failed to read Wasm handler #{name}: #{inspect(reason)}")
            {:error, :load_failed}
        end
    end
  end

  # Production: Cache bytes permanently (no mtime checks)
  defp load_with_cache(name, abs_path) do
    case :ets.lookup(@table_name, name) do
      [{^name, bytes, _mtime}] ->
        {:ok, bytes}

      [] ->
        case File.read(abs_path) do
          {:ok, bytes} ->
            # Store with nil mtime in production (never expires)
            :ets.insert(@table_name, {name, bytes, nil})
            Logger.debug("Cached Wasm handler: #{name}")
            {:ok, bytes}

          {:error, reason} ->
            Logger.error("Failed to read Wasm handler #{name}: #{inspect(reason)}")
            {:error, :load_failed}
        end
    end
  end

  defp dev_mode? do
    Application.get_env(:glossia, :environment, :prod) == :dev
  end

  @doc """
  Validates content using the specified Wasm handler.
  Creates a fresh instance per call (stateless, concurrency-safe).
  Returns :ok if valid, {:error, reason} if invalid.
  """
  def validate(handler_name, content) when is_binary(content) do
    # Handle empty content
    if content == "" do
      :ok
    else
      with {:ok, bytes} <- load_wasm_bytes(handler_name),
           {:ok, instance} <- Wasmex.start_link(%{bytes: bytes}),
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

        # Clean up instance (Wasmex handles this automatically, but explicit is clearer)
        GenServer.stop(instance, :normal)

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
