use clap::{Parser, Subcommand};
use glossia_core::{greet, GlossiaConfig};

#[derive(Parser)]
#[command(name = "glossia")]
#[command(about = "Glossia CLI - Manage your Glossia applications", long_about = None)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Greet a user
    Greet {
        /// Name of the person to greet
        #[arg(short, long, default_value = "World")]
        name: String,
    },
    /// Show configuration
    Config,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Greet { name } => {
            let message = greet(&name);
            println!("{}", message);
        }
        Commands::Config => {
            let config = GlossiaConfig::default();
            let json = serde_json::to_string_pretty(&config)?;
            println!("{}", json);
        }
    }

    Ok(())
}
