mod args;
mod commands;
mod config;
mod context;
mod format;
mod glob;
mod hash;
mod llm;
mod locks;
mod output;
mod pathing;
mod reporter;
mod root;
mod runtime_config;
mod translate;
mod validate;

pub fn main_entry() -> i32 {
    commands::main_entry()
}
