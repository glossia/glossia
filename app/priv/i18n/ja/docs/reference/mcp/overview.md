%{
  title: "概要",
  summary: "Model Context Protocol を通じてコーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は提供しています [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーはコーディングエージェントがローカライゼーションプロジェクトと連携できるようにします。サーバーは OAuth 2.1 と PKCE および Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)），したがって任意の MCP 互換クライアントは手動の認証情報の設定なしで認証できます。

## MCP サーバーが提供する機能

接続後、コーディングエージェントは次のことができます：

- すべてのプロジェクトの翻訳ステータスを照会
- 翻訳・変更開始
- 設定とコンテンツエントリの確認
- プロジェクトコンテキストを活用し、より高度なコード提案

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは、PKCE を使用した標準の OAuth 2.1 認証コードフローを使用します。手動で OAuth クライアントを作成する必要はありません。フローは次のようになります:

1. エージェントはサーバーを通じて検出します `/.well-known/oauth-authorization-server`
2. エージェントは動的な登録エンドポイントを介して OAuth クライアントとして登録します
3. エージェントはログインと同意のためのブラウザを開きます
4. あなたが承認すると、エージェントはアクセストークンを取得し、すべての MCP リクエストに追加します

## コーディングエージェントに Glossia を追加する

### OpenAI Codex

以下の Codex 設定ファイルにサーバーを追加 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

その後、OAuth ログインを実行:

```bash
codex mcp login glossia
```

認証のためブラウザが開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで利用します。

接続を確認するには:

```bash
codex mcp list
```

ローカル開発の場合は、URL を置き換えてください:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code の MCP 設定にサーバーを追加 (`.claude/settings.json` またはグローバル設定ファイル):

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

Claude Code は初回接続時に、自動的に OAuth フローを処理します。

### 他の MCP クライアント

MCP 認証仕様をサポートする [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は以下の通りです：

- **トランスポート**: ストリーム可能な HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 Protected Resource Metadata をサポートする必要があります ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: ダイナミック クライアント 登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または Client ID メタデータドキュメント
- **認証フロー**: PKCE（S256）認証コード

クライアントをあなたの Glossia MCP サーバー URL へ向け、発見と登録の処理を自動的に担当させます。

## 発見エンドポイント

サーバーは 2 つのメタデータドキュメントを公開し、MCP クライアントは OAuth フローの開始にそれらを使用します：

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ（エンドポイント、サポートされている認可タイプ、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | 保護リソースメタデータ（スコープ、認証サーバー） |

## レート制限

OAuth エンドポイントでは、悪用を防ぐためにレート制限が適用されます：

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 回 |
| `POST /oauth/token` | 1 分あたり 30 回 |
| `POST /oauth/introspect` | 1 分あたり 30 回 |
| `POST /oauth/revoke` | 1 分あたり 30 リクエスト |

レート制限を超えると、サーバーは HTTP 429 と `Retry-After` ヘッダーを返します。

## トラブルシューティング

### 登録に失敗し "invalid\_client\_metadata" のエラーになります

動的登録エンドポイントは特定 `token_endpoint_auth_method` の値のみを受け付けます。公開クライアント（多くのコーディングエージェント）は送信し `"none"`, Glossia は PKCE 強制下のデフォルト認証方法へのフォールバックによって自動的に処理します。

### 承認後に「無効な OAuth コールバック」

Glossia サーバーが動作しており、構成した URL で到達可能であることを確認してください。コールバックは、コーディングエージェントが一時的に開くローカルポート上で発生します。ファイアウォールや VPN がこれをブロックすることがあります。

### トークン交換が失敗します

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。PKCE が動作するように、サーバーは S256 のサポートを公開する必要があります。Glossia はこれをデフォルトで含んでいます。

### エージェントがサーバーに到達できません

ローカル開発では、Phoenix サーバーが動作しており（`mix phx.server`）、指定されたポート（デフォルト：4050）でリッスンしていることを確認してください。MCP エンドポイントはエージェントプロセスからアクセス可能である必要があります。