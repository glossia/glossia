%{
  title: "概要",
  summary: "Model Context Protocol を介してコーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーでコーディングエージェントはあなたのローカリゼーションプロジェクトと連携できます。サーバーは OAuth 2.1、PKCE、および動的クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)、MCP 互換クライアントは手動の認証設定なしで認証できます。

## MCP サーバーが提供するもの

接続後、コーディングエージェントは次のことができます:

- すべてのプロジェクトの翻訳ステータスを照会する
- 翻訳および改定を開始
- 設定およびコンテンツエントリを検証
- よりスマートなコード提案のためのプロジェクトコンテキストへのアクセス

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは標準の OAuth 2.1 認証コードフロー（PKCE 使用）を使用します。手動で OAuth クライアントを作成する必要はありません。フローは以下の通りです：

1. エージェントは以下の通りサーバーを検出します `/.well-known/oauth-authorization-server`
2. 動的登録エンドポイントを通じて、自身を OAuth クライアントとして登録します
3. ログインと同意のためにブラウザを開きます
4. 承認後、エージェントはアクセストークンを取得し、すべての MCP リクエストに付与します

## コーディングエージェントへの Glossia の追加

### OpenAI Codex

サーバーを Codex 設定ファイルの に追加 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に、OAuth ログインを実行：

```bash
codex mcp login glossia
```

ブラウザが認証のために開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するには：

```bash
codex mcp list
```

ローカル開発の場合は、URL を置換：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code の MCP 設定にサーバーを追加（`.claude/settings.json` またはグローバルの設定ファイル）：

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code は最初にご接続する際に OAuth フローを自動的に処理します。

### 他の MCP クライアント

MCP 認証仕様をサポートする任意のクライアントは [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は：

- **トランスポート**: ストリーム可能な HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 保護されたリソースメタデータをサポートする必要があります（[RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: ダイナミック クライアント登録（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) またはクライアント ID メタデータ文書
- **認証フロー**: PKCE (S256) を使用した認証コード

Glossia MCP サーバー URL にクライアントを設定し、発見と登録を自動的に処理させてください。

## 設定用エンドポイント

サーバーは、MCP クライアントが OAuth フローを初期化するために使用する 2 つのメタデータ文書を公開します:

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ（エンドポイント、対応する権限付与方法、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | 保護済みリソースのメタデータ（スコープ、認証サーバー） |

## レート制限

OAuth エンドポイントは不正使用を防ぐためにレート制限を適用しています:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 回のリクエスト |

レート制限が超過されると、サーバーは HTTP 429 を返すとともに `Retry-After` ヘッダー。

## トラブルシューティング

### 登録が "invalid\_client\_metadata" で失敗しました

動的登録エンドポイントは特定の値のみを受け入れます `token_endpoint_auth_method` 値です。パブリック クライアント（ほとんどのコーディング エージェント）は送信し、 `"none"`, Glossia が PKCE 強制を維持しつつデフォルト認証方法へ自動的にフォールバックします。

### 承認後の無効な OAuth コールバック

構成した URL で Glossia サーバーが起動し、アクセス可能であることを確認してください。コーディングエージェントが一時的に開くローカルポートでコールバックが発生します。ファイアウォールまたは VPN がこれをブロックする場合があります。

### トークン交換に失敗

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。PKCE が動作するには、サーバーは S256 サポートを公開する必要があります。Glossia はこれをデフォルトで実装しています。

### エージェントがサーバーに到達できません

ローカル開発の場合、Phoenix サーバーが動作しており（`mix phx.server`）、指定されたポートで待機していることを確認してください（default: 4050）。エージェントプロセスから MCP エンドポイントにアクセス可能であることを確認してください。