%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じてコーディングエージェントをあなたの Glossia プロジェクトに接続できます。",
  category: "リファレンス",
  subcategory: "mcp",
  order: 1
}
---

Glossia は [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーを公開しており、コーディングエージェントがローカライゼーションプロジェクトに相互作用するためのことができます。サーバーは OAuth 2.1 ならびに PKCE と Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) を実装しており、MCP 互換のあらゆるクライアントは手動のカredential 設定なしで認証することができます。

## The MCP server provides

接続後では、コーディングエージェントはアカウントとプロジェクトのリスト作成、プロジェクト作成、組織成员と招待の管理、voice と glossary 設定の読み込みまたは更新、アカウントモデルとトークンの管理などを実行することができます。won of course. sudo of course.

サーバーは今現在、翻訳開始やリビジョン開始のツールを公開しておらず、ファイルベースの翻訳ステータスの検査もできません。[tool reference](/docs/reference/mcp) で利用可能なツールを確認してください。

## Server URL

Glossia 公開サービスを `https://glossia.ai/mcp` に接続しましょう。Glossia はこのエンドポイントを動作・維持しています。接続設定はコーディングエージェント側でしか行いません。

## Authentication flow

MCP サーバーは PKCE を使用した OAuth 2.1 の標準的な Authorization Code フローを使用します。OAuth クライアントを手動で作成する必要はありません。フローは以下の通りです：

1. The agent discovers Glossia through `https://glossia.ai/.well-known/oauth-authorization-server`
2. It registers itself as an OAuth client via the dynamic registration endpoint
3. It opens your browser for login and consent
4. After you approve, the agent receives an access token and attaches it to all MCP requests

## Adding Glossia to a coding agent

### OpenAI Codex

[Codex connection guide](https://developers.openai.com/codex/mcp) に記載されている通り、サーバーを Codex の設定ファイル `~/.codex/config.toml` に追加ください：

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

Then run the OAuth login:

```bash
codex mcp login glossia
```

Your browser will open for authentication. After approving, Codex stores the token locally and uses it for future sessions.

To verify the connection:

```bash
codex mcp list
```

### Claude Code

[Claude Code's connection guide](https://code.claude.com/docs/en/mcp) に記載されているコマンドを使用してホスト サーバーを追加します。

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

Run `/mcp` inside Claude Code and follow the browser authentication flow.

### Other MCP clients

A client must support the [Model Context Protocol authorization flow](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) implemented by Glossia. The connection requires:

- **Transport**: Streamable HTTP
- **Discovery**: The client must support OAuth 2.0 Protected Resource Metadata ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registration**: Dynamic Client Registration ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth flow**: Authorization code with PKCE (S256)

Point the client at `https://glossia.ai/mcp` and let it handle discovery and registration automatically.

## Discovery endpoints

The server publishes two metadata documents that MCP clients use to bootstrap the OAuth flow:

| Endpoint | Description |
|---|---|
| `/.well-known/oauth-authorization-server` | Authorization server metadata (endpoints, supported grant types, PKCE methods) |
| `/.well-known/oauth-protected-resource` | Protected resource metadata (scopes, authorization servers) |

## Rate limits

The OAuth endpoints enforce rate limits to prevent abuse:

| Endpoint | Limit |
|---|---|
| `POST /oauth/register` | 5 requests per minute |
| `POST /oauth/token` | 30 requests per minute |
| `POST /oauth/introspect` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 30 リクエスト/分 |

レート制限が超過した場合、サーバーから HTTP 429 と `Retry-After` ヘッダーが返されます。

## トラブルシューティング

### 「invalid_client_metadata」エラーで登録に失敗

動的登録エンドポイントでは特定の `token_endpoint_auth_method` 値のみの受け付けです。公開クライアント（コーディングエージェントの多く）は `"none"` を送信するべきです。Glossia は PKCE 強制付きのデフォルト認証方法にフォールバックすることでこれを自動的に処理します。

### 承認後に「Invalid OAuth callback」

あなたのコーディングエージェントが `https://glossia.ai` にアクセスできることを確認してください。このコールバックはコーディングエージェントがコンピューターで一時的に開くローカルポートで発生します。Glossia は引き続きホストされ、このローカルリスナーはあなたのエージェントに属します。ファイアウォールやVPNがブロックすることもできます。

### トークン交換に失敗

認証サーバーのメタデータに `code_challenge_methods_supported` フィールドが存在するか確認してください。サーバーは PKCE が動作するために S256 サポートを広告する必要があります。Glossia はデフォルトでこれを含んでいます。

### エージェントがサーバーに到達できない

設定されたエンドポイントが `https://glossia.ai/mcp` であることを、そしてネットワークがコーディングエージェントが到達できるようにすることを検証してください。ホストサービスが利用不能のままの場合、Glossia サポートにお問い合わせください。
