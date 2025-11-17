# Wasm Format Handlers

Format handlers implemented in Zig and compiled to WebAssembly for portability and performance.

## Architecture

- **handlers/** - Zig source code for format handlers
- **build/** - Compiled .wasm modules (gitignored, built locally)
- **build.sh** - Build script to compile all handlers

## Why Wasm?

✅ **Portability** - Handlers run anywhere (server, CLI, edge, browser)
✅ **Language flexibility** - Implement in Zig, Rust, Go, etc.
✅ **Sandboxing** - Isolated execution environment
✅ **Performance** - Near-native speed (~10-40KB per handler)
✅ **Versioning** - Ship handler versions as .wasm files

## Prerequisites

### Install Zig

**macOS:**
```bash
brew install zig
```

**Linux:**
```bash
# Download from https://ziglang.org/download/
# Extract and add to PATH
```

**Verify:**
```bash
zig version
# Should be >= 0.13.0
```

## Building Handlers

```bash
# Build all handlers
./build.sh

# Or build individually
zig build-lib handlers/ftl.zig \
  -target wasm32-freestanding \
  -dynamic \
  -rdynamic \
  -O ReleaseSmall \
  -femit-bin=build/ftl.wasm
```

## Handler Interface

Each handler exports these functions:

### Memory Management
```zig
export fn alloc(size: usize) ?[*]u8
export fn dealloc(ptr: [*]u8, size: usize) void
export fn get_output_ptr() [*]u8
export fn get_output_len() usize
```

### Core Functions
```zig
// Validate content format
// Returns: 0 = valid, -1 = invalid
export fn validate(content_ptr: [*]const u8, content_len: usize) i32

// Extract translatable strings as JSON array
// Output: [{"index":N,"key":"...","value":"..."}]
export fn extract_strings(content_ptr: [*]const u8, content_len: usize) i32

// Apply translations to content
// Input: [{"index":N,"translation":"..."}]
export fn apply_translations(
    content_ptr: [*]const u8,
    content_len: usize,
    translations_ptr: [*]const u8,
    translations_len: usize
) i32
```

## Development Workflow

1. **Edit handler** - Modify `handlers/*.zig`
2. **Build** - Run `./build.sh`
3. **Test** - Elixir automatically loads updated .wasm files
4. **Iterate** - Changes are picked up on next request (dev) or restart (prod)

## Adding a New Handler

1. Create `handlers/your_format.zig`
2. Implement the required exports
3. Run `./build.sh`
4. Create corresponding Elixir module:

```elixir
defmodule Glossia.Formats.YourFormatHandler do
  @behaviour Glossia.Formats.Handler
  alias Glossia.Formats.WasmHandler

  @handler_name "your_format"

  def translate(content, source, target) do
    with {:ok, strings} <- WasmHandler.extract_strings(@handler_name, content) do
      # Translate strings...
      WasmHandler.apply_translations(@handler_name, content, translations)
    end
  end

  def validate(content) do
    WasmHandler.validate(@handler_name, content)
  end
end
```

## Size Optimization

Current sizes (with `-O ReleaseSmall`):
- **ftl.wasm**: ~15-30KB

Further optimizations:
```bash
# Strip debug info
wasm-strip build/ftl.wasm

# Or use wasm-opt (from binaryen)
wasm-opt -Oz build/ftl.wasm -o build/ftl.opt.wasm
```

## Troubleshooting

**"zig: command not found"**
- Install Zig from https://ziglang.org/download/

**"Wasm handler not found"**
- Run `./build.sh` to compile handlers
- Check that `build/*.wasm` files exist

**"Failed to load Wasm handler"**
- Check Elixir logs for detailed error
- Verify .wasm file is valid: `wasm-validate build/ftl.wasm`

## Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [WebAssembly Spec](https://webassembly.github.io/spec/)
- [Wasmex Documentation](https://hexdocs.pm/wasmex/)
