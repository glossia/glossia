defmodule Glossia.Foundation.LLMs.Core do
  use Boundary, exports: [LLM]

  def default do
    Glossia.Features.LLMs.Core.OpenAIChatGPT
  end
end
