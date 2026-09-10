%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じて、コーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---
Glossia は公開しています、 [モデルコンテキストプロトコル](https://modelcontextprotocol.io) (MCP) サーバーは、コーディングエージェントがローカライズプロジェクトと連携できるようにします。サーバーは OAuth 2.1 と PKCE を採用したダイナミック クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), そのため、MCP 互換クライアントは手動の認証情報設定なしで認証できます。

## MCP サーバー提供内容

接続後、コーディングエージェントは以下を実行できます:

- プロジェクト全体の翻訳ステータスを照会
- 翻訳と改訂を開始
- 設定とコンテンツエントリの確認
- より高度なコード提案のためにプロジェクトコンテキストにアクセス

## サーバー URL

| 環境 | URL |
|---|---|
| 本番 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは標準の OAuth 2.1 認証コードフローと PKCE を使用しています。手動で OAuth クライアントを作成する必要はありません。フローは以下の通りです：

1. エージェントはサーバーを以下を通じて発見します `/.well-known/oauth-authorization-server`
2. 動的登録エンドポイント経由で OAuth クライアントとして自身を登録します
3. ログインおよび同意のためにブラウザを開きます
4. 承認後、エージェントはアクセストークンを受け取り、すべての MCP リクエストに添付します

## コーディングエージェントに Glossia を追加する

### OpenAI Codex

以下の Codex 設定ファイルにサーバーを追加してください `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

その後、OAuth ログインを実行してください：

```bash
codex mcp login glossia
```

認証のためにブラウザが開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するには：

```bash
codex mcp list
```

ローカル開発の場合、URL を置換してください：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code の MCP 設定にサーバーを追加 (`.claude/settings.json` またはグローバル設定ファイル ):

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

Claude Code は初回接続時に OAuth フローを自動的に処理します。

### 他の MCP クライアント

MCP 認証仕様に準拠する [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) で動作します。主な要件は:

- **トランスポート**: ストリーマブル HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 Protected Resource Metadata ( をサポートする必要があります[RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: 動的クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) またはクライアント ID メタデータ文書
- **認証フロー**: PKCE (S256) を使用した認証コード

クライアントをあなたの Glossia MCP サーバー URL に向け、発見と登録を自動的に処理してください。

## ディスカバリー エンドポイント

サーバーは、MCP クライアントが OAuth フローの起動に使用する 2 つのメタデータ文書を公開しています：

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーのメタデータ（エンドポイント、サポートされる認可方法、PKCE 方法） |
| `/.well-known/oauth-protected-resource` | 保護リソースのメタデータ（スコープ、認証サーバー） |

## レート制限

OAuth エンドポイントは不正使用を防ぐためレート制限を適用します:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 回のリクエスト |

レート制限を超えると、サーバーは HTTP 429 を、 `Retry-After` ヘッダー。

## トラブルシューティング

### 登録に失敗しました: "invalid\_client\_metadata"

動的登録エンドポイントでは、特定の `token_endpoint_auth_method` 値のみを受け入れます。公開クライアント（多くのコーディングエージェント）は送信、 `"none"`、Glossia は自動的に PKCE 強制下でデフォルト認証方法へのフォールバック処理を行います。

### 承認後に無効な OAuth コールバック

設定した URL で Glossia サーバーが実行され、アクセス可能であることを確認してください。呼び戻しは、コーディングエージェントが一時的に開くローカルポートで発生します。ファイアウォールまたは VPN がこれをブロックすることがあります。

### トークン交換に失敗します

認証サーバーメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。PKCE が動作するには、サーバーで S256 対応が示されている必要があります。Glossia はこれをデフォルトで含んでいます。

### エージェントがサーバーに到達できません

ローカル開発の場合、Phoenix サーバーを実行（`mix phx.server`）し、期待されるポートでリスニングしていることを確認してください（デフォルト：4050）。エージェントプロセスから MCP エンドポイントにアクセス可能である必要があります。