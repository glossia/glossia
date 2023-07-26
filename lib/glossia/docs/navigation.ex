defmodule Glossia.Docs.Navigation do
  # @navigation_json "priv/docs/navigation.json"
  #                  |> File.read!()

  # @navigation_json_schema %{
  #                           "type" => "object",
  #                           "properties" => %{
  #                             "foo" => %{
  #                               "type" => "string"
  #                             }
  #                           }
  #                         }
  #                         |> ExJsonSchema.Schema.resolve()
  # @navigation_json_path "priv/docs/navigation.json"
  # @external_resource @navigation_json_path
  #   @navigation_json with navigation_json <-
  #                           @navigation_json_path |> File.read!() |> Jason.decode!(),
  #                         {:ok, _} <-
  #                           ExJsonSchema.Validator.validate(
  #                             @navigation_json_schema,
  #                             navigation_json
  #                           ) do
  #     navigation_json
  #   else
  #     {:error, errors} ->
  #       raise """
  #       The navigation.json file is invalid. Please check the following errors:

  #       #{inspect(errors)}
  #       """
  #   end
end
