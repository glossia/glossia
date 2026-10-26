%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じてコーディングエージェントをあなたの Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---

Glossia は [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーを提供し、コーディングエージェントがローカライゼーションプロジェクトと対話できるようにします。このサーバーは OAuth 2.1 で PKCE と Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) を実装しているため、MCP 互換クライアントは手動の認証情報設定なしで認証できます。

## MCP サーバーが提供する機能

接続後、コーディングエージェントは account とプロジェクトの一覧を表示し、プロジェクトを作成し、組織メンバーと招待を管理し、voice と glossary 設定を読みまたは更新し、account モデルとトークンを管理できます。ただし、その権限によっては制約があります。

サーバーは現在、翻訳やリビジョンを開始するためのツール、またはファイルごとの翻訳ステータスを確認するためのツールを公開していません。利用可能なツールについては [tool reference](/docs/reference/mcp) を参照してください。

## サーバー URL

Glossia のホストサービス `https://glossia.ai/mcp` に接続します。Glossia がこのエンドポイントを運用・維持しており、接続設定はコーディングエージェント側でしか行いません。

## 認証フロー

MCP サーバーは PKCE を使用した標準の OAuth 2.1 認証コードフローを使用します。OAuth クライアントを手動で作成する必要はありません。フローは以下のように動作します:

1. エージェントは `https://glossia.ai/.well-known/oauth-authorization-server` 経由で Glossia を発見します
2. エージェントはダイナミック登録エンドポイント経由で OAuth クライント作為自らを登録します
3. ブラウザでログインと同意のために開きます
4. 承認後、エージェントはアクセストークンを受け取り、すべての MCP リクエストに添付します

## コーディングエージェントへの Glossia の追加

### OpenAI Codex

[Codex connection guide](https://developers.openai.com/codex/mcp) に従い、サーバーをあなたの Codex 設定ファイル `~/.codex/config.toml` に追加します:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

その後、OAuth ログインを実行します:

```bash
codex mcp login glossia
```

ブラウザが認証のために開きます。承認後、Codex はトークンをローカルに保存し、今後のセッションで使用します。

接続を確認するために:

```bash
codex mcp list
```

### Claude Code

[Claude Code's connection guide](https://code.claude.com/docs/en/mcp) でドキュメントされているコマンドを使用してホストサーバーを追加します:

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Claude Code 内で `/mcp` を実行し、ブラウザ認証フローに従ってください。

### その他の MCP クライアント

クライアントは Glossia が実装している [Model Context Protocol authorization flow](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) をサポートする必要があります。接続には以下が必要です:

- **Transport**: Streamable HTTP
- **Discovery**: クライアントは OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)) をサポートする必要があります
- **Registration**: Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth flow**: PKCE (S256) を使用した認証コード

クライアントを `https://glossia.ai/mcp` に向かせ、発見と登録を自動的に処理させます。

## 発見エンドポイント

サーバーは OAuth フローを開始するために MCP クライアントが使用する 2 つのメタドキュメントを公開します:

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | Authorization サーバーのメタデータ（エンドポイント、サポートされている grant タイプ、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | Protected resource metatadata（scopes、Authorization サーバー） |

## レート制限

OAuth エンドポイントは暴走を防ぐためにレート制限を強制します:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 30 リクエスト/分 |

レート制限を超えた場合、サーバーは HTTP 429 と `Retry-After` ヘッダを返します。

## ## トラブルシューティング

### 「invalid_client_metadata」で登録に失敗します

ダイナミック登録エンドポイントは特定の `token_endpoint_auth_method` 値のみを受け付けます。公開クライアント（ほとんどのコーディングエージェント）は `"none"` を送信すべきで、Glossia は PKCE 強制によるデフォルト認証方法へのフォールバックによりこれを自動的に処理します。

### ## 承認後に「Invalid OAuth callback」

コーディングエージェントが `https://glossia.ai`. に接続できることを確認してください。コールバックはコーディングエージェントがあなたのコンピュータで時に開くローカルポートで発生します。Glossia はホストされたままです。このローカルリスナーはあなたのエージェントに属します。ファイアウォールや仮想プライベートネットワークがコールバックをブロックすることがあります。

### ## トークン交換に失敗

認証サーバーメタデータに `code_challenge_methods_supported` フィールドが存在するか確認してください。サーバーは PKCE が機能するように S256 サポートを広告する必要があります。Glossia はデフォルトでこれを含まれています。

### ## エージェントがサーバーに接続できません

設定されたエンドポイントが `https://glossia.ai/mcp` であることを確認し、ネットワークがコーディングエージェントの到達を許可していることを確認してください。ホストされたサービスが利用不可能のままの場合、Glossia サポートに連絡してください。
