# Credo configuration for Glossia.
#
# Run `mix credo` to lint `app/lib` and `app/test`. The current configuration
# only enables the project's own checks; built-in Credo checks can be added
# incrementally as we agree on a baseline.

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "test/"
        ],
        excluded: [
          ~r"/_build/",
          ~r"/deps/"
        ]
      },
      plugins: [],
      requires: ["lib/glossia/credo_checks/no_type_annotations.ex"],
      strict: false,
      checks: %{
        enabled: [
          {Glossia.CredoChecks.NoTypeAnnotations, []}
        ]
      }
    }
  ]
}
