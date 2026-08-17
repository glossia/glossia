defmodule Glossia.Sandbox.SafeCommand do
  @moduledoc false

  @shell_metacharacters [
    ";",
    "&",
    "|",
    "`",
    "$",
    "<",
    ">",
    "*",
    "?",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    "\\"
  ]

  def parse(command) when is_binary(command) do
    command = String.trim(command)

    cond do
      command == "" ->
        {:error, :empty_command}

      String.match?(command, ~r/[[:cntrl:]]/) ->
        {:error, :shell_syntax_not_supported}

      true ->
        argv = OptionParser.split(command)

        with :ok <- validate_argument_syntax(argv) do
          validate_argv(argv)
        end
    end
  rescue
    _error -> {:error, :shell_syntax_not_supported}
  end

  def parse(_command), do: {:error, :invalid_command}

  def validate(command) do
    case parse(command) do
      {:ok, _argv} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_argument_syntax(["chromium" | _args]), do: :ok

  defp validate_argument_syntax(argv) do
    if Enum.any?(argv, fn argument ->
         Enum.any?(@shell_metacharacters, &String.contains?(argument, &1))
       end) do
      {:error, :shell_syntax_not_supported}
    else
      :ok
    end
  end

  defp validate_argv(["echo" | _args] = argv), do: {:ok, argv}
  defp validate_argv(["printf" | _args] = argv), do: {:ok, argv}
  defp validate_argv([command] = argv) when command in ~w(false pwd true), do: {:ok, argv}

  defp validate_argv([command | paths] = argv) when command in ~w(cat ls),
    do: validate_paths(argv, paths)

  defp validate_argv(["mkdir" | args] = argv), do: validate_paths(argv, path_args(args, ["-p"]))

  defp validate_argv(["rm" | args] = argv),
    do: validate_paths(argv, path_args(args, ["-r", "-f", "-rf", "-fr"]))

  defp validate_argv(["chromium" | args] = argv), do: validate_chromium(argv, args)

  defp validate_argv([name | _]), do: {:error, {:unsupported_command, name}}
  defp validate_argv([]), do: {:error, :empty_command}

  defp validate_paths(argv, []), do: {:ok, argv}

  defp validate_paths(argv, paths) do
    if Enum.all?(paths, &safe_relative_path?/1) do
      {:ok, argv}
    else
      {:error, :path_outside_sandbox}
    end
  end

  defp path_args(args, flags) do
    {_flags, paths} = Enum.split_while(args, &(&1 in flags))
    paths
  end

  defp validate_chromium(argv, args) do
    {flags, addresses} = Enum.split_while(args, &String.starts_with?(&1, "--"))

    cond do
      length(addresses) != 1 ->
        {:error, :invalid_browser_command}

      not Enum.all?(flags, &allowed_chromium_flag?/1) ->
        {:error, :invalid_browser_flag}

      not valid_browser_address?(List.first(addresses)) ->
        {:error, :invalid_browser_address}

      true ->
        {:ok, argv}
    end
  end

  defp allowed_chromium_flag?(flag)
       when flag in [
              "--headless",
              "--disable-gpu",
              "--disable-dev-shm-usage",
              "--dump-dom",
              "--hide-scrollbars",
              "--virtual-time-budget=5000",
              "--window-size=1440,1000"
            ],
       do: true

  defp allowed_chromium_flag?("--screenshot=" <> path), do: safe_relative_path?(path)

  defp allowed_chromium_flag?("--host-resolver-rules=" <> rules) do
    case String.split(rules, ",", trim: true) do
      [] -> false
      rules -> valid_host_resolver_rules?(rules)
    end
  end

  defp allowed_chromium_flag?(_flag), do: false

  defp valid_host_resolver_rules?(rules) do
    List.last(rules) == "MAP * ~NOTFOUND" and
      Enum.all?(rules, fn rule ->
        case String.split(rule, " ", trim: true) do
          ["MAP", pattern, replacement] ->
            valid_resolver_token?(pattern, true) and valid_resolver_token?(replacement, false)

          _other ->
            false
        end
      end)
  end

  defp valid_resolver_token?("*", true), do: true
  defp valid_resolver_token?("~NOTFOUND", false), do: true

  defp valid_resolver_token?(token, _pattern?) do
    token != "" and String.match?(token, ~r/\A[a-zA-Z0-9.:[\]_-]+\z/)
  end

  defp valid_browser_address?("about:blank"), do: true

  defp valid_browser_address?(address) do
    case URI.parse(address) do
      %URI{scheme: scheme, host: host, userinfo: nil, query: nil, fragment: nil}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        true

      _ ->
        false
    end
  end

  defp safe_relative_path?(path) do
    Path.type(path) == :relative and not String.starts_with?(path, "-") and
      ".." not in Path.split(path)
  end
end
