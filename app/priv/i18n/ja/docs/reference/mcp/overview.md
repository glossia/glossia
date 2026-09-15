%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じて、コーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は [モデルコンテキストプロトコル](https://modelcontextprotocol.io) (MCP) サーバーはコーディングエージェントがあなたのローカライゼーションプロジェクトと対話できるようにします。サーバーは OAuth 2.1、PKCE および Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), したがって、MCP 互換のクライアントは手動の認証情報設定なしで認証できます。

## MCP サーバーが提供するもの

接続後、コーディングエージェントは:

- プロジェクト全体での翻訳ステータスを照会できます
- 翻訳と改訂を開始する
- 設定およびコンテンツエントリを確認
- プロジェクトコンテキストにアクセスし、より高度なコード提案を取得

## サーバー URL

| 環境 | URL |
|---|---|
| 本番 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは、標準の OAuth 2.1 認証コードフロー（PKCE）を使用します。手動で OAuth クライアントを作成する必要はありません。このフローは次の通りです：

1. エージェントはあなたのサーバーを検出します。 `/.well-known/oauth-authorization-server`
2. それは、動的登録エンドポイントを介して OAuth クライアントとして登録されます。
3. それはログインと同意のためにブラウザを開きます。
4. あなたが承認した後、エージェントはアクセストークンを取得し、すべての MCP リクエストに追加します。

## コーディングエージェントに Glossia を追加

### OpenAI Codex

OpenAI Codex の設定ファイルにサーバーを追加します `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

その後、OAuth ログインを実行してください:

```bash
codex mcp login glossia
```

認証のためにブラウザが開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認:

```bash
codex mcp list
```

ローカル開発の場合、URL を書き換えてください:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code の MCP 設定 ( にサーバーを追加するか、`.claude/settings.json` またはグローバル設定ファイル):

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

MCP 認証仕様をサポートする任意のクライアントは [MCP 認証規格を満たす場合](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は次の通りです。

- **トランスポート**: ストリーミング可能な HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 Protected Resource Metadata をサポートする必要があります([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: ダイナミッククライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または Client ID メタデータドキュメント
- **認証フロー**: PKCE（S256）認証コード

Glossia MCP サーバーの URL をクライアントに指定し、発見と登録を自動的に処理させます。

## 発見エンポイント

サーバーは、MCP クライアントが OAuth フローの初期化に使用する 2 つのメタデータドキュメントを公開しています。

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ（エンドポイント、サポートされた権付与方法、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | 保護リソースメタデータ（スコープ、認証サーバー） |

## レート制限

OAuth エンドポイントは、悪用を防ぐためにレート制限を適用しています:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 30 リクエスト／分 |

レート制限を超えると、サーバーは HTTP 429 を、 `Retry-After` ヘッダーを伴って返します。

## トラブルシューティング

### 登録に失敗しました（"invalid\_client\_metadata"）

ダイナミック登録エンドポイントは特定の `token_endpoint_auth_method` 値のみを受け付けます。公開クライアント（多くのコーディングエージェント）は送信する、 `"none"`、Glossia が自動的にデフォルト認証方法へのフォールバックおよび PKCE 強制を実行して処理します。

### "無効な OAuth コールバック" 承認後

設定した URL で、Glossia サーバーが動作中かつ到達可能であることを確認してください。コールバックは、コーディングエージェントが一時的に開くローカルポートで発生します。ファイアウォールや VPN がこれをブロックすることがあります。

### トークン交換に失敗しました

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。PKCE を正常に動作させるには、サーバーが S256 サポートを公開している必要があります。Glossia ではデフォルトでこれをサポートしています。

### エージェントはサーバーに到達できません

ローカル開発では、Phoenix サーバーが動作中（`mix phx.server`）で、指定されたポート（デフォルト：4050）でリスニングされていることを確認してください。エージェントプロセスから MCP エンドポイントにアクセス可能である必要があります。