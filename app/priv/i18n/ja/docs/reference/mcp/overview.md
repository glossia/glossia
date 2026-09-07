%{
  title: "概要",
  summary: "Model Context Protocol を介してコーディングエージェントを Glossia プロジェクトに接続できます。",
  category: "リファレンス",
  subcategory: "mcp",
  order: 1
}
---
Glossia は [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーはコーディングエージェントがローカライゼーションプロジェクトと対話できるようにします。このサーバーは OAuth 2.1、PKCE および動的クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), そのため、MCP 互換のクライアントは手動の認証設定なしで認証できます。

## MCP サーバーが提供するもの

接続後、コーディングエージェントは次のことができます：

- 各プロジェクトの翻訳ステータスを照会する
- 翻訳と改訂を開始
- 設定とコンテンツエントリを確認
- よりスマートなコードの提案のためにプロジェクトコンテキストにアクセス

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは、PKCE を含む標準の OAuth 2.1 認証コードフローを使用します。手動で OAuth クライアントを作成する必要はありません。フローは以下の通りです:

1. エージェントはあなたのサーバーを通じて検出します `/.well-known/oauth-authorization-server`
2. エージェントはダイナミック登録エンドポイントを介して OAuth クライアントとして登録します
3. エージェントは、ログインと同意のために、あなたのブラウザを開きます
4. あなたが承認した後、エージェントはアクセストークンを取得し、すべての MCP リクエストに追加します

## コーディングエージェントに Glossia を追加

### OpenAI Codex

サーバーを Codex 設定ファイルに追加し、以下 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に OAuth ログインを実行してください:

```bash
codex mcp login glossia
```

ブラウザが認証のために開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するには:

```bash
codex mcp list
```

ローカル開発の場合、URL を置換してください:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

サーバーを Claude Code MCP 設定に追加 (`.claude/settings.json` またはグローバル設定ファイル):

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

Claude Code は最初に接続する際に OAuth フローを自動的に処理します。

### 他の MCP クライアント

MCP 認証仕様に対応する [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は次の通りです：

- **トランスポート**: ストリーム可能 HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 保護されたリソースメタデータをサポートする必要があります ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: ダイナミック クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または クライアント ID メタデータドキュメント
- **認証フロー**: PKCE (S256) を使用した認証コード

Glossia MCP サーバー URL にクライアントを指定し、発見と登録を自動的に処理します。

## 発見エンドポイント

サーバーは二つのメタデータドキュメントを公開しており、MCP クライアントが OAuth フローを初期化するためにこれらを使用します。

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ (エンドポイント、サポートされる 権限付与タイプ、PKCE メソッド) |
| `/.well-known/oauth-protected-resource` | 保護リソースメタデータ (スコープ、認証サーバー) |

## レート制限

OAuth エンドポイントは、悪用防止のためにレート制限を適用します:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 件のリクエスト |

レート制限を超えると、サーバーは HTTP 429 を、 `Retry-After` ヘッダーを返します。

## トラブルシューティング

### 登録が "invalid\_client\_metadata" のエラーで失敗しました。

動的登録エンドポイントでは、特定の `token_endpoint_auth_method` 値のみを受け付けます。パブリック クライアント（多くのコーディング エージェント）は送信し、 `"none"`, Glossia は自動的にデフォルト認証方式へのフォールバックを行い、PKCE 強制を適用します。

### 「無効な OAuth コールバック」 承認後

設定した URL で Glossia サーバーが実行中かつアクセス可能であることを確認してください。コールバックは、コーディングエージェントが一時的に使用するローカルポートで発生します。ファイアウォールまたは VPN がこれをブロックすることがあります。

### トークン交換が失敗

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在しているか確認してください。PKCE が動作するには、サーバーは S256 サポートを明示している必要があります。Glossia はこれをデフォルトで提供しています。

### エージェントがサーバーにアクセスできない

ローカル開発では、Phoenix サーバーが実行中 (`mix phx.server`) かつ指定されたポートでリスニングしていることを確認してください（デフォルト：4050）。MCP エンドポイントがエージェントプロセスからアクセス可能である必要があります。