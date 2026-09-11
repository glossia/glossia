%{
  title: "概要",
  summary: "Model Context Protocol を通じて、コーディングエージェントを Glossia プロジェクトに接続できます。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は [モデルコンテキストプロトコル](https://modelcontextprotocol.io) (MCP) サーバーによりコーディングエージェントはローカライズプロジェクトと連携できます。サーバーは OAuth 2.1（PKCE および Dynamic Client Registration ([RFC 7591"）](https://datatracker.ietf.org/doc/html/rfc7591)）、MCP 互換のクライアントは手動の資格設定なしに認証できます。

## MCP サーバーが提供する機能

接続後、コーディングエージェントは以下のことができます:

- プロジェクト全体の翻訳ステータスを照会する
- 翻訳と修正をトリガーする
- 構成とコンテンツエントリを確認する
- プロジェクトのコンテキストを参照して、より賢いコード提案を行う

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |\]
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは PKCE を使用した標準の OAuth 2.1 認証コードフローを使用します。手動で OAuth クライアントを作成する必要はありません。このフローの動作は次の通りです：

1. エージェントはサーバーを発見します `/.well-known/oauth-authorization-server`
2. 動的登録エンドポイントを介して OAuth クライアントとして自らを登録します
3. ログインと同意を得るためにあなたのブラウザを開きます
4. 承認すると、エージェントはアクセストークンを取得し、すべての MCP リクエストに添付します

## コーディングエージェントに Glossia を追加

### OpenAI Codex

サーバーを Codex の設定ファイルに追加し、以下 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に OAuth ログインを実行します:

```bash
codex mcp login glossia
```

ブラウザが認証のために開きます。承認後、Codex はトークンをローカルに保存し、以降のセッションで使用します。

接続を確認するには:

```bash
codex mcp list
```

ローカル開発の場合は、URL を書き換えてください:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

サーバーをあなたの Claude Code の MCP 設定に追加(`.claude/settings.json` または、グローバルの設定ファイル）：

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

MCP 認証仕様に対応する任意のクライアントは [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は：

- **トランスポート**: ストリーミング対応 HTTP
- **ディスカバリー**: クライアントは OAuth 2.0 保護されたリソースメタデータをサポートする必要があります ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **レジストレーション**: ダイナミッククライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または クライアント ID メタデータ文書
- **認証フロー**PKCE (S256) を使用した認証コード

あなたの Glossia MCP サーバー URL を設定し、ディスカバリーと登録を自動的に処理します。

## ディスカバリーエンドポイント

サーバーは、MCP クライアントが OAuth フローを初期化するための 2 つのメタデータドキュメントを公開します:

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ (エンドポイント、サポートされる認可種別、PKCE メソッド) |
| `/.well-known/oauth-protected-resource` | 保護対象リソースメタデータ (スコープ、認証サーバー) |

## レート制限

OAuth エンドポイントは悪用の防止のためにレート制限を適用します:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 分あたり 30 回のリクエスト |

レート制限を超えると、サーバーは HTTP 429 と `Retry-After` ヘッダー。

## トラブルシューティング

### 「invalid\_client\_metadata」で登録に失敗しました。

ダイナミック登録エンドポイントでは特定の `token_endpoint_auth_method` 値のみを受け入れます。パブリッククライアント（多くのコーディングエージェント）は送らなければなりません。 `"none"`、Glossia は PKCE 強制付きのデフォルト認証方式に自動的にフォールバックすることによって処理します。

### 承認後の「無効な OAuth コールバック」

Glossia サーバーが起動しており、設定した URL で到達可能であることを確認してください。コールバックはコーディングエージェントが一時的に開くローカルポートで発生します。ファイアウォールや VPN がこれをブロックすることがあります。

### トークンの交換に失敗

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが含まれていることを確認してください。PKCE が機能するためには、サーバーが S256 のサポートを示す必要があります。Glossia ではこれはデフォルトで含まれています。

### エージェントがサーバーに到達できません

ローカル開発では、Phoenix サーバーが起動していることを確認してください (`mix phx.server`)。期待的なポート (デフォルト：4050) でリスニングしている必要があります。MCP エンドポイントはエージェントプロセスからアクセス可能である必要があります。