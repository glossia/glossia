defmodule Glossia.Features.LLMs.Core do
  use Boundary, exports: [OpenAIChatGPT], deps: [Glossia.Foundation.LLMs.Core]
end
