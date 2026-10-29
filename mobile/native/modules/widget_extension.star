# Once 0.68.2 compiles extension-safe Apple executables but always emits .app.
# Keep its Swift/SDK/signing pipeline; only provide the missing .appex wrapper.
# Host apps embed this declared tree in a postbuild action, before final signing.
def _glossia_widget_extension_impl(ctx):
    source = ctx["deps"][0]
    if not source.get("application_extension"):
        fail("Widget source must set application_extension = true")
    output = declare_output("GlossiaActivity.appex")
    run_action(
        argv = [host_which("ditto"), execution_path(source["app_path"]), execution_path(output)],
        inputs = source["app_files"],
        outputs = [output],
        identifier = ctx["label"]["id"] + ":appex",
        display_name = "Package WidgetKit extension",
    )
    result = dict(source)
    result["label_id"] = ctx["label"]["id"]
    result["app_path"] = output
    result["app_executable"] = output + "/GlossiaActivity"
    result["app_files"] = [output]
    result["default_output"] = output
    return result

glossia_widget_extension = target_kind(
    deps = [dep("deps", ["apple_application"], "Once-compiled extension executable", min_count = 1, max_count = 1)],
    providers = ["apple_application", "apple_bundle"],
    capabilities = [capability("build", ["default", "bundle"])],
    impl = _glossia_widget_extension_impl,
)
