defmodule Glossia.Foundation.Localizations.Core.Utilities.Parser do
  def parse_localization_request(request) do
    Enum.map(request[:modules], fn module ->
      format = module[:format]
      id = module[:id]

      # Source
      source_localizable = module[:localizables][:source]
      source_id = source_localizable[:id]
      source_context = source_localizable[:context]
      _source_content_checksum_cache_id = source_localizable[:checksum][:cache_id]

      source_content_checksum_value = source_localizable[:checksum][:content][:value]
      source_content_checksum_algorithm = source_localizable[:checksum][:content][:algorithm]

      content_and_context_checksum =
        calculate_checksum(
          source_content_checksum_value,
          source_context,
          source_content_checksum_algorithm
        )

      [source_cache_checksum_value, source_cache_checksum_algorithm] =
        case source_localizable[:checksum][:cache] do
          nil -> [nil, nil]
          cache -> [cache[:value], cache[:algorithm]]
        end

      # Target
      target_localizables = module[:localizables][:target]

      # The source content or context hasn't changed
      target =
        if content_and_context_checksum == source_cache_checksum_value &&
             source_content_checksum_algorithm == source_cache_checksum_algorithm do
          []
        else
          Enum.flat_map(target_localizables, fn target_localizable ->
            # From the target localizables we select those that already exist but
            # need to reflect the changes.
            target_id = target_localizable[:id]
            target_context = target_localizable[:context]

            _target_content_checksum_cache_id = target_localizable[:checksum][:cache_id]
            _target_content_checksum_value = target_localizable[:checksum][:content][:value]

            _target_content_checksum_algorithm =
              target_localizable[:checksum][:content][:algorithm]

            [target_cache_checksum_value, target_cache_checksum_algorithm] =
              case target_localizable[:checksum][:cache] do
                nil -> [nil, nil]
                cache -> [cache[:value], cache[:algorithm]]
              end

            if !target_cache_checksum_value || !target_cache_checksum_algorithm do
              [
                {
                  :new_target_localizable,
                  %{
                    id: target_id,
                    context: target_context,
                    checksum_cache_id: target_localizable[:checksum][:cache_id]
                  }
                }
              ]
            else
              []
            end
          end)
        end

      %{
        id: id,
        format: format,
        source: %{
          id: source_id,
          context: source_context,
          checksum_cache_id: source_localizable[:checksum][:cache_id]
        },
        target: target
      }
    end)
  end

  defp calculate_checksum(content_checksum, context, "sha256") do
    content =
      [
        content_checksum
        | context |> Map.keys() |> Enum.sort() |> Enum.map(fn key -> context[key] end)
      ]
      |> Enum.join("-")

    :crypto.hash(:sha256, content)
    |> Base.encode16()
    |> String.downcase()
  end
end
