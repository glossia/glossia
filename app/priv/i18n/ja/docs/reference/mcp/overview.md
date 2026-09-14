%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じて、コーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は、 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーが、翻訳プロジェクトとコーディングエージェントの連携を可能にし、このサーバーは OAuth 2.1 に PKCE および Dynamic Client Registration を実装しています。([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)), したがって、MCP 互換クライアントは手動の資格情報設定なしで認証を実行できます。

## MCP サーバーが提供するもの

接続後、コーディングエージェントは以下のことができます：

- プロジェクト全体の翻訳ステータスを照会します
- 翻訳と改訂をトリガーする
- 設定とコンテンツエントリを確認する
- よりスマートなコード提案のため、プロジェクトコンテキストにアクセスする

## サーバー URL

| 環境 | URL |
|---|---|
| 本番環境 | `https://glossia.ai/mcp` |
| ローカル開発 | `http://localhost:4050/mcp` |

## 認証フロー

MCP サーバーは標準的な OAuth 2.1 認証コードフロー（PKCE）を使用します。手動で OAuth クライアントを作成する必要はありません。フローは以下の通りです：

1. エージェントはあなたのサーバーを発見します `/.well-known/oauth-authorization-server`
2. 動的登録エンドポイントを介して、自身を OAuth クライアントとして登録します
3. ログインおよび同意のためにブラウザを開きます
4. あなたが承認すると、エージェントはアクセストークンを取得し、すべての MCP リクエストに添付します

## コーディングエージェントに Glossia を追加

### OpenAI Codex

サーバーを Codex 設定ファイルに追加してください `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に OAuth ログインを実行:

```bash
codex mcp login glossia
```

ブラウザが認証のために開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するには:

```bash
codex mcp list
```

ローカル開発の場合は、URL を置換:

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

Claude Code MCP 設定にサーバーを追加 (`.claude/settings.json` またはグローバル設定ファイル):

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

Claude Code は最初の接続時に OAuth フローを自動的に処理します。

### 他の MCP クライアント

MCP 認証仕様に対応する [MCP 認証仕様](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 動作します。主な要件は:

- **トランスポート**: ストリーム対応 HTTP
- **発見**: クライアントは OAuth 2.0 保護リソースメタデータをサポートする必要があります ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**: ダイナミッククライアント登録 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) または クライアント ID メタデータ ドキュメント
- **認証フロー**: PKCE (S256) を使用した認証コード

Glossia MCP サーバー URL にクライアントを向け、発見と登録を自動的に処理させてください。

## 発見エンドポイント

サーバーは、MCP クライアントが OAuth フローを開始するために使用する 2 つのメタデータドキュメントを公開します：

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ (エンドポイント、サポートされる権限付与タイプ、PKCE メソッド) |
| `/.well-known/oauth-protected-resource` | 保護されたリソースメタデータ (スコープ、認証サーバー) |

## レート制限

OAuth エンドポイントは、濫用を防ぐためにレート制限を適用します：

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 回のリクエスト |

レート制限を超過した場合、サーバーは HTTP 429 の `Retry-After` ヘッダーを返します。

## トラブルシューティング

### 登録に失敗し \\"invalid\_client\_metadata\\" です。

動的登録エンドポイントでは特定の `token_endpoint_auth_method` 値のみを受け取ります。公開クライアント (主にコーディングエージェント) は送信し、 `"none"`Glossia は PKCE 強制を含むデフォルトの認証メソッドへのフォールバックで自動的に処理します。

### "無効な OAuth callback" 承認後

構成済みの URL で Glossia サーバーが実行中でありアクセス可能であることを確認してください。コーディングエージェントが一時的に開くローカルポートでコールバックが発生します。ファイアウォールまたは VPN は場合によってはこれをブロックする可能性があります。

### トークン交換に失敗

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在していることを確認してください。正常に動作するには、サーバーが PKCE の S256 サポートを公開している必要があります。Glossia はこれをデフォルトで用意しています。

### エージェントがサーバーに到達できません

ローカル開発では、Phoenix サーバーが実行中（`mix phx.server`）で、予期されたポート（デフォルト：4050）でリスニングされていることを確認してください。エージェントプロセスから MCP エンドポイントにアクセス可能である必要があります。