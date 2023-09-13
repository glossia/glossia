defmodule Glossia.Features.Marketing.Core do
  use Boundary, exports: [
    Blog,
    Blog.Author,
    Blog.Post
  ]
end
