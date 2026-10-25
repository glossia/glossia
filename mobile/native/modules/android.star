# Once owns Rust and build ordering. AGP owns Maven AAR/manifest/resource merging.
def _glossia_android_impl(ctx):
    native = ctx["deps"][0]["android_native_libraries"][0]
    apk = declare_output("GlossiaAndroid.apk")
    run_action(
        argv = [
            host_which("gradle"), "--no-daemon", "--console=plain",
            "-p", execution_path("android"), "packageOnce",
            "-PonceNativeLibrary=" + execution_path(native["path"]),
            "-PonceNativeAbi=" + native["abi"],
            "-PonceOutputApk=" + execution_path(apk),
        ],
        inputs = glob(ctx["srcs"]) + [native["path"]],
        outputs = [apk],
        # Gradle manages its incremental outputs and dependency cache locally.
        # Do not represent that mutable cache as a hermetic Once action.
        sandbox = "off",
        cacheable = False,
        inherit_parent_env = True,
        identifier = ctx["label"]["id"] + ":material-android",
        display_name = "Build Material Android app",
    )
    return {"label_id": ctx["label"]["id"], "android_apk": apk, "default_output": apk}

glossia_android_application = target_kind(
    deps = [dep("deps", ["android_native_library"], "Once-built Rust JNI", min_count = 1, max_count = 1)],
    providers = ["android_apk"],
    capabilities = [capability("build", ["default"])],
    tools = [tool("gradle", executables = ["gradle"])],
    impl = _glossia_android_impl,
)
