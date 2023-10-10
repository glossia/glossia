defmodule Glossia.Features.Docs.Core.Models.Navigation.Item do
  @derive [Nestru.Decoder]
  use TypedStruct

  typedstruct do
    field :name, String.t()
    field :path, String.t()
    field :children, list(__MODULE__.t())
  end
end
