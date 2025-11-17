# Wasm Format Validators

Format validators implemented in Zig and compiled to WebAssembly for portability and performance.

## Architecture

**Validation-Only Approach:**
- Wasm handlers validate format syntax
- LLM translates full content with format-aware instructions
- Much simpler than extract/translate/apply pattern

**Directory Structure:**
- **handlers/** - Zig source code for validators
- **zig-out/build/** - Compiled .wasm modules (gitignored, built by Mix)
- **build.zig** - Zig build system configuration

## Why Wasm?

✅ **Portability** - Validators run anywhere (server, CLI, edge, browser)
✅ **Language flexibility** - Implement in Zig, Rust, Go, etc.
✅ **Sandboxing** - Isolated execution environment
✅ **Performance** - Near-native speed (~5-15KB per validator)
✅ **Versioning** - Ship validator versions as .wasm files

## Prerequisites

### Install Zig via Mise

This project uses [Mise](https://mise.jdx.dev/) for tool version management.

```bash
# Install mise if you haven't already
curl https://mise.run | sh

# Install Zig (version specified in .mise.toml)
mise install
```

**Verify:**
```bash
mise exec -- zig version
# Should show: 0.13.0
```

## Building Validators

Validators are automatically built by Mix when needed:

```bash
# Compile validators (happens automatically during mix compile)
mix compile.wasm

# Or build manually via Zig
cd priv/wasm
mise exec -- zig build
```

Mix's lazy compilation only rebuilds when source files are newer than compiled .wasm files.

## Validator Interface

Each validator exports these functions:

### Memory Management
```zig
export fn alloc(size: usize) ?[*]u8
export fn dealloc(ptr: [*]u8, size: usize) void
```

### Validation Function
```zig
// Validate content format
// Returns: 0 = valid, -1 = invalid
export fn validate(content_ptr: [*]const u8, content_len: usize) i32
```

**That's it!** No extract_strings or apply_translations needed.

## How Translation Works

1. **Validate input** - Wasm validator checks syntax
2. **LLM translates** - Full content sent to LLM with format-specific instructions
3. **Validate output** - Wasm validator ensures output is still valid

Example from FTL handler:
```elixir
def translate(content, source_locale, target_locale) do
  # Validate input
  with :ok <- validate(content),
       # LLM translates with format instructions
       {:ok, translated} <-
         Translator.translate_with_instructions(
           content,
           source_locale,
           target_locale,
           @format_instructions
         ),
       # Validate output
       :ok <- validate(translated) do
    {:ok, translated}
  end
end
```

## Development Workflow

1. **Edit validator** - Modify `handlers/*.zig`
2. **Run tests** - `mix test` (automatically recompiles if needed)
3. **Iterate** - Changes picked up on next compilation

## Adding a New Validator

### 1. Create Zig validator

Create `handlers/your_format.zig`:
```zig
const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

export fn alloc(size: usize) ?[*]u8 {
    const buf = allocator.alloc(u8, size) catch return null;
    return buf.ptr;
}

export fn dealloc(ptr: [*]u8, size: usize) void {
    const slice = ptr[0..size];
    allocator.free(slice);
}

export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    // Your validation logic here
    // Return 0 if valid, -1 if invalid

    return 0;
}
```

### 2. Add to build.zig

Update the `handlers` array:
```zig
const handlers = [_][]const u8{ "ftl", "your_format" };
```

### 3. Create Elixir handler

```elixir
defmodule Glossia.Formats.YourFormatHandler do
  @behaviour Glossia.Formats.Handler

  alias Glossia.Formats.WasmHandler
  alias Glossia.AI.Translator

  @handler_name "your_format"

  @format_instructions """
  This is a YourFormat file. You MUST:
  - Preserve all structure and formatting
  - Only translate the translatable text
  - Keep all syntax intact
  """

  def translate(content, source_locale, target_locale) do
    with :ok <- validate(content),
         {:ok, translated} <-
           Translator.translate_with_instructions(
             content,
             source_locale,
             target_locale,
             @format_instructions
           ),
         :ok <- validate(translated) do
      {:ok, translated}
    end
  end

  def validate(content) do
    WasmHandler.validate(@handler_name, content)
  end
end
```

### 4. Test it

```bash
mix test test/glossia/formats/your_format_handler_test.exs
```

## Size Optimization

Current sizes (with `-O ReleaseSmall`):
- **ftl.wasm**: ~5-7KB (validation-only, down from 15KB)

The validation-only approach significantly reduces Wasm size since we removed all the parsing/extraction logic.

Further optimizations:
```bash
# Strip debug info
wasm-strip zig-out/build/ftl.wasm

# Or use wasm-opt (from binaryen)
wasm-opt -Oz zig-out/build/ftl.wasm -o ftl.opt.wasm
```

## Troubleshooting

**"Zig is not installed"**
- Run `mise install` to install the correct Zig version

**"Wasm handler not found"**
- Run `mix compile.wasm` to compile validators
- Check that `zig-out/build/*.wasm` files exist

**"Failed to load Wasm handler"**
- Check Elixir logs for detailed error
- Verify .wasm file is valid: `wasm-validate zig-out/build/ftl.wasm`

## Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [WebAssembly Spec](https://webassembly.github.io/spec/)
- [Wasmex Documentation](https://hexdocs.pm/wasmex/)
- [Mise Documentation](https://mise.jdx.dev/)
