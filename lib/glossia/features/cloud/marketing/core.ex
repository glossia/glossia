defmodule Glossia.Features.Cloud.Marketing.Core do
  use Boundary,
    exports: [
      Blog,
      Blog.Author,
      Blog.Post
    ]
end
