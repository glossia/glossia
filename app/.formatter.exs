[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter, Quokka],
  quokka: [
    # Keep Quokka integrated in CI while avoiding massive repo-wide rewrites.
    # We can relax this incrementally once we schedule a dedicated style pass.
    exclude: [
      :blocks,
      :comment_directives,
      :configs,
      :defs,
      :deprecations,
      :line_length,
      :module_directives,
      :pipes,
      :single_node,
      :tests
    ]
  ],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
