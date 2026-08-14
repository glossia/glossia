%{
  title: "概要",
  summary: "Model Context Protocol を介してコーディングエージェントを Glossia プロジェクトに接続します。",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia は、コーディングエージェントがローカライゼーションプロジェクトを操作できる [Model Context Protocol](https://modelcontextprotocol.io)（MCP）サーバーを提供します。このサーバーは、PKCE と動的クライアント登録（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)）を使用する OAuth 2.1 を実装しているため、MCP 対応クライアントは資格情報を手動で設定せずに認証できます。

## MCP サーバーが提供する機能

接続すると、コーディングエージェントは次の操作を実行できます。

- 複数のプロジェクトにわたる翻訳ステータスの照会
- 翻訳と修正の実行
- 設定とコンテンツエントリの確認
- より適切なコード提案に必要なプロジェクトコンテキストへのアクセス

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発環境 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは、PKCE を使用する標準の OAuth 2.1 認可コードフローを使用します。OAuth クライアントを手動で作成する必要はありません。フローは次のとおりです。

1. エージェントが `/.well-known/oauth-authorization-server` を通じてサーバーを検出します
2. 動的登録エンドポイントを介して自身を OAuth クライアントとして登録します
3. ログインと同意のためにブラウザーを開きます
4. 承認すると、エージェントはアクセストークンを受け取り、すべての MCP リクエストに付加します

## コーディングエージェントへの Glossia の追加

### OpenAI Codex

`~/.codex/config.toml` にある Codex 設定ファイルにサーバーを追加します。

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に、OAuth ログインを実行します。

```bash
codex mcp login glossia
```

認証用のブラウザーが開きます。承認すると、Codex はトークンをローカルに保存し、以降のセッションで使用します。

接続を確認するには、次を実行します。

```bash
codex mcp list
```

ローカル開発では、URL を置き換えます。

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code の MCP 設定（`.claude/settings.json` またはグローバル設定ファイル）にサーバーを追加します。

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

### その他の MCP クライアント

[MCP 認可仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)をサポートするクライアントであれば利用できます。主な要件は次のとおりです。

- **トランスポート**: ストリーミング対応 HTTP
- **検出**: クライアントが OAuth 2.0 保護リソースメタデータ（[RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)）をサポートしていること
- **登録**: 動的クライアント登録（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)）またはクライアント ID メタデータドキュメント
- **認証フロー**: PKCE（S256）を使用する認可コードフロー

クライアントに Glossia MCP サーバーの URL を指定すると、検出と登録が自動的に処理されます。

## 検出エンドポイント

サーバーは、MCP クライアントが OAuth フローの初期化に使用する 2 つのメタデータドキュメントを公開します。

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認可サーバーのメタデータ（エンドポイント、サポートされるグラントタイプ、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | 保護リソースのメタデータ（スコープ、認可サーバー） |

## レート制限

OAuth エンドポイントでは、不正利用を防ぐためにレート制限を適用します。

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 1 分あたり 30 リクエスト |

レート制限を超えると、サーバーは `Retry-After` ヘッダーを含む HTTP 429 を返します。

## トラブルシューティング

### "invalid_client_metadata" により登録が失敗する

動的登録エンドポイントは、特定の `token_endpoint_auth_method` 値のみを受け付けます。公開クライアント（ほとんどのコーディングエージェント）は `"none"` を送信してください。Glossia は、PKCE を適用した既定の認証方式にフォールバックすることで、これを自動的に処理します。

### 承認後に「Invalid OAuth callback」と表示される

Glossia サーバーが稼働しており、設定した URL からアクセスできることを確認してください。コールバックは、コーディングエージェントが一時的に開くローカルポートで実行されます。ファイアウォールや VPN によってブロックされる場合があります。

### トークン交換に失敗する

認可サーバーのメタデータに `code_challenge_methods_supported` フィールドが含まれていることを確認してください。PKCE を動作させるには、サーバーが S256 のサポートを公開する必要があります。Glossia では既定でこれが含まれています。

### エージェントがサーバーに接続できない

ローカル開発では、Phoenix サーバーが稼働しており（`mix phx.server`）、想定されるポート（既定値: 4050）で待ち受けていることを確認してください。エージェントのプロセスから MCP エンドポイントにアクセスできる必要があります。