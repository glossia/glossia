defmodule Glossia.Translations.JsonArrayTest do
  use ExUnit.Case, async: true

  alias Glossia.Translations.JsonArray

  test "decodes a bare JSON array" do
    assert {:ok, ["Hola", "Resumen"]} = JsonArray.decode(~s(["Hola", "Resumen"]))
  end

  test "decodes an array inside a fenced JSON response with an introduction" do
    response = """
    Here is the translated array:

    ```json
    ["Hola", "Resumen"]
    ```
    """

    assert {:ok, ["Hola", "Resumen"]} = JsonArray.decode(response)
  end

  test "rejects non-array JSON" do
    assert {:error, :invalid_json_array} = JsonArray.decode(~s({"text":"Hola"}))
  end
end
