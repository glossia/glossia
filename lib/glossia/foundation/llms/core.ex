defmodule Glossia.Foundation.LLMs.Core do
  def default do
    Glossia.Features.LLMs.Core.OpenAIChatGPT
  end
end
