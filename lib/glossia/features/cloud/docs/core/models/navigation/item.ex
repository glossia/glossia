defmodule Glossia.Features.Cloud.Docs.Core.Models.Navigation.Item do
  use TypedStruct
  use Domo

  typedstruct do
    field :name, String.t(), enforce: true
    field :children, [%__MODULE__{}] | nil, enforce: false, default: nil
    field :path, String.t() | nil, enforce: false, default: nil
  end
end
