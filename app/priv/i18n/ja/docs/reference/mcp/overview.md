%{
  title: "概要",
  summary: "モデルコンテキストプロトコルを通じてコーディングエージェントを Glossia プロジェクトに接続します。",
  category: "参照",
  subcategory: "mcp",
  order: 1
}
---
Glossia は、 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) サーバーはコーディングエージェントがローカライゼーションプロジェクトと対話できるようにします。サーバーは OAuth 2.1、PKCE、および動的クライアント登録（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)）、そのため、MCP 互換クライアントは手動の認証情報の設定を行わずに認証できます。

## MCP サーバーが提供しているもの

接続後、コーディングエージェントはアカウントとプロジェクトの一覧を取得し、プロジェクトを作成し、組織メンバーおよび招待を管理し、音声および用語集の設定を読み書きできます。ただし、権限によって制限されます。

サーバーは現在、翻訳やリビジョンを開始するツール、またはファイル別の翻訳状態を確認するツールを提供していません。詳細は、 [ツール参照](/docs/reference/mcp) 利用可能なツールに関する。

## サーバー URL

Glossia のホストサービスに接続します `https://glossia.ai/mcp`. Glossia はこのエンドポイントを運用・維持しています。接続設定はコーディングエージェントで行います。

## 認証フロー

MCP サーバーは、PKCE を使用した標準の OAuth 2.1 認証コードフローを使います。手動で OAuth クライアントを作成する必要はありません。このフローは以下のように動作します:

1. エージェントは、を通じて Glossia を検出します `https://glossia.ai/.well-known/oauth-authorization-server`
2. 動的登録エンドポイントを通じて、自身を OAuth クライアントとして登録します
3. ログインと同意を取得するためにブラウザを開きます
4. 承認後、エージェントはアクセストークンを取得し、すべての MCP リクエストに添付します

## コーディングエージェントに Glossia を追加する

### OpenAI Codex

次の [Codex 接続ガイド](https://developers.openai.com/codex/mcp)、サーバーを Codex 設定ファイルに追加します `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

次に OAuth ログインを実行します：

```bash
codex mcp login glossia
```

認証のためにブラウザが開きます。承認後、Codex はトークンをローカルに保存し、以降のセッションで使用します。

接続を確認するには：

```bash
codex mcp list
```

### Claude Code

以下のドキュメントに記載されたコマンドでホストされたサーバーを追加： [Claude Code の接続ガイド](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

実行 `/mcp` Claude Code の中で実行し、ブラウザの認証フローに従ってください。

### 他の MCP クライアント

クライアントはこれができないと破綻します [モデルコンテキストプロトコルの認証フロー](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) Glossia によって実装されています。接続には以下の条件が必要です:

- **トランスポート**: Streamable HTTP
- **発見**： クライアントは、OAuth 2.0 保護リソースメタデータ（[RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **登録**： 動的クライアント登録（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **認証フロー**： PKCE (S256) の認可コード

クライアントを `https://glossia.ai/mcp` し、発見と登録を自動的に処理させます。

## 発見エンドポイント

サーバーは、MCP クライアントが OAuth フローを開始するために使用する 2 つのメタデータドキュメントを公開します：

| エンドポイント | 説明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 認証サーバーメタデータ（エンドポイント、サポートされているグラントタイプ、PKCE メソッド） |
| `/.well-known/oauth-protected-resource` | 保護されたリソースのメタデータ（スコープ、認証サーバー） |

## レート制限

OAuth エンドポイントは不正使用を防ぐためにレート制限を適用します:

| エンドポイント | 制限 |
|---|---|
| `POST /oauth/register` | 1 分あたり 5 回 |
| `POST /oauth/token` | 1 分あたり 30 回 |
| `POST /oauth/introspect` | 1 分あたり 30 回 |
| `POST /oauth/revoke` | 1 分あたり 30 回 |

レート制限を超えると、サーバーは HTTP 429 と共に `Retry-After` ヘッダーを返します。

## トラブルシューティング

### 登録に失敗しました "invalid\_client\_metadata"

動的登録エンドポイントでは特定の `token_endpoint_auth_method` 値のみを受け入れます。パブリッククライアント（多くのコーディングエージェント）は `"none"`、Glossia は PKCE 強制を適用したデフォルト認証方式へ自動的にフォールバックすることで処理を行います。

### "無効な OAuth コールバック" の承認後

コーディングエージェントが に到達できることを確認してください `https://glossia.ai`. コールバックはコーディングエージェントが一時的にあなたのコンピュータ上で開くローカルポートで発生します。Glossia は引き続きホストされています。このローカルリスナーはあなたのエージェントに属し、ファイアウォールまたは仮想プライベートネットワークは場合によってはコールバックをブロックする可能性があります。

### トークン交換に失敗しました

～を確認してください `code_challenge_methods_supported` 認証サーバーメタデータにはこのフィールドが含まれています。PKCE が動作するためには、サーバーが S256 サポートを公開している必要があります。Glossia にはデフォルトでこれが含まれています。

### エージェントがサーバーに接続できません

設定されたエンドポイントが、 `https://glossia.ai/mcp` また、あなたのネットワークがコーディングエージェントによる接続を許可していることを確認してください。ホストされたサービスが引き続き利用できない場合、Glossia サポートにご連絡ください。