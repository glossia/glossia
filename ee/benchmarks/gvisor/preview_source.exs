Code.require_file(Path.expand("../../../app/lib/glossia/editor/preview_browser.ex", __DIR__))
source = Glossia.Editor.PreviewBrowser.source()
boundary = "while (true) {\n"

if length(String.split(source, boundary)) != 2,
  do: raise("Preview loop changed; review checkpoint boundary")

barrier = """
  // Benchmark only: main-loop/screenshot boundary, not global CDP quiescence.
  const checkpointRequest = path.join(home, 'checkpoint-request');
  const checkpointReady = path.join(home, 'checkpoint-ready.json');
  if (fs.existsSync(checkpointRequest)) {
    atomic(checkpointReady, JSON.stringify({revision, sequence, input_sequence: inputSequence}));
    while (fs.existsSync(checkpointRequest)) await sleep(25);
    fs.unlinkSync(checkpointReady);
  }
"""

IO.write(String.replace(source, boundary, boundary <> barrier, global: false))
