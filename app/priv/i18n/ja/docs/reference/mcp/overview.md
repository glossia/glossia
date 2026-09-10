%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを介してコーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia が提供する [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーによりコーディング エージェントがローカライゼーション プロジェクトと相互作用できるようになります。サーバーは OAuth 2.1、PKCE および Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))、そのため、任意の MCP 互換クライアントは手動の認証情報設定なしに認証できます。

## MCP スーパーが提供するもの

接続後、コーディング エージェントは次のことができます:

- プロジェクト全体の翻訳ステータスを照会
- 翻訳と改訂を開始
- 設定およびコンテンツエントリの確認
- より高度なコード提案のため、プロジェクトコンテキストにアクセス

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは標準の OAuth 2.1 認証コードフローと PKCE を使用します。手動で OAuth クライアントを作成する必要はありません。このフローの仕組みは以下の通りです：

1. エージェントはサーバーを通じて発見します。 `/.well-known/oauth-authorization-server`
2. それ自身を動的登録エンドポイント経由で OAuth クライアントとして登録します。
3. ログインと同意のためブラウザを開きます。
4. 承認後、エージェントはアクセストークンを取得し、すべての MCP リクエストに添付します。

## Glossia をコーディングエージェントに追加

### OpenAI Codex

サーバーを Codex 設定ファイルの以下に追加 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に OAuth 認証を実行：

```bash
codex mcp login glossia
```

認証のためブラウザが開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するには：

```bash
codex mcp list
```

ローカル開発の場合、URL を以下に置き換え：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

サーバーを Claude Code の MCP 設定（`.claude/settings.json` またはグローバル設定ファイル）：

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

Claude Code は最初に接続する際、自動的に OAuth フローを処理します。

### 他の MCP クライアント

MCP 認証仕様をサポートする [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) は動作します。主な要件は次の通りです：

- **トランスポート**：ストリーム可能な HTTP
- **ディスカバリー**：クライアントは OAuth 2.0 Protected Resource Metadata をサポートする必要があります ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**：動的クライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または クライアント ID メタデータドキュメント
- **認証フロー**: PKCE (S256) を利用した認証コード

あなたの Glossia MCP サーバー URL をクライアントに示すと、発見と登録が自動的に処理されます。

## 発見エンドポイント

サーバーは、MCP クライアントが OAuth フローを開始するために使用する 2 つのメタデータドキュメントを公開します。

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ (エンドポイント、サポートされる認証方式、PKCE 方式) |
| `/.well-known/oauth-protected-resource` | 保護されたリソースメタデータ (スコープ、認証サーバー) |

## レート制限

OAuth エンドポイントは悪用を防ぐためにレート制限を適用します：

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 1 分間に 30 リクエスト |

レート制限を超えた場合、サーバーは HTTP 429 を伴う `Retry-After` ヘッダーを返します。

## トラブルシューティング

### 登録が "invalid\_client\_metadata" で失敗しました

動的登録エンドポイントは特定の `token_endpoint_auth_method` 値が必要です。公開クライアント（多くのコーディングエージェント）は送信する `"none"`、Glossia は PKCE 強制を伴ってデフォルトの認証方法にフォールバックすることで自動的に処理します。

### 「無効な OAuth コールバック」承認後

ご設定の URL で Glossia サーバーが稼働しており、アクセス可能であることを確認してください。コールバックは、コーディングエージェントが一時的に開くローカルポートで発生します。ファイアウォールや VPN がこれをブロックする場合があります。

### トークン交換に失敗

認証サーバーメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。PKCE が動作するためには、サーバーは S256 サポートを提供している必要があります。Glossia ではこれがデフォルトで含まれています。

### エージェントがサーバーに到達できない

ローカル開発の場合、Phoenix サーバーが実行中（`mix phx.server`）であり、指定されたポートで待機している（デフォルト：4050）ことを確認してください。MCP エンドポイントはエージェントプロセスからアクセス可能である必要があります。