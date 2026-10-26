%{
  title: "認証・認可",
  summary: "権限スコープ、組織ロール、およびリソースレベルのアクセスチェック。",
  category: "参考",
  subcategory: "API",
  order: 2
}
---

認証は身元を確立し、認可はその身元が実行できるアクションを決定します。サインインとトークンのフローについては[認証](/docs/reference/apis/authentication)をご覧ください。

## スコープ

スコープはトークンが実行できるアクションを制御します。同時に、`object:action` パターンに従います。

| スコープ | 説明 |
|-------|-------------|
| `admin:read` | プラットフォーム管理データの読み取り（プラットフォーム管理者のみ） |
| `admin:write` | プラットフォーム管理データの更新（プラットフォーム管理者のみ） |
| `ops:read` | プラットフォーム運用データの読み取り（プラットフォーム管理者のみ） |
| `user:read` | ユーザープロフィール情報の読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧表示 |
| `organization:read` | 組織詳細の読み取り（自分の組織一覧表示含む） |
| `organization:write` | 組織の作成または更新 |
| `organization:claim` | 組織の所有権を請求 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理アクション |
| `members:read` | 組織メンバーと招待の確認読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクト管理アクション |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の読み取り |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声管理アクション |
| `glossary:read` | 用語集エントリの読み取り |
| `glossary:write` | 用語集エントリの作成または更新 |
| `glossary:admin` | 用語集設定の管理 |
| `discussion:read` | ディスカッションの読み取り |
| `discussion:write` | ディスカッションの作成または更新 |
| `discussion:admin` | ディスカッション管理アクション |
| `ticket:read` | チケットの読み取り |
| `ticket:write` | チケットの作成または更新 |
| `ticket:admin` | チケット管理アクション |
| `llm_model:read` | アカウント言語モデルの読み取り |
| `llm_model:write` | アカウント言語モデルの管理 |
| `translation:read` | プロジェクト翻訳アクティビティの読み取り |
| `translation:write` | 翻訳データの書き込み |
| `analytics:read` | プロジェクトウェブサイト分析の読み取り |
| `toki:read` | 自分のプライベートプロジェクト会話を |
| `toki:write` | プライベート会話を作成し、コンパニオン返信をキュー化する |
| `api_credentials:read` | アクセス認証情報の読み取り |
| `api_credentials:write` | アクセス認証情報の管理 |

認証サーバーの[発見メタデータ](/docs/reference/apis/authentication#discovery-endpoints)は、クライアントのアクセス可能なスコープを公開します。スコープが利用可能であることは、それ単体でアクセス権を付与するものではありません。

## 認可モデル

Glossia は **2 つのレイヤー** を [表現状態転送](https://developer.mozilla.org/en-US/docs/Glossary/REST) アプリケーションプログラミングインターフェースと [モデルコンテキストプロトコル](https://modelcontextprotocol.io) サーバーに適用します。

1. **スコープチェック**：アクセストークンは必要な`object:action` スコープを含める必要があります。
2. **リソースレベルポリシー**：現在のユーザーは、明示的なメンバー権限またはロールベースのポリシーを通じて、特定のモーナルに対して認証されなければなりません。

スコープはトークンの*最大* キャパビリティを表します。リソースレベルチェックは特定の資源の*実際の* 権限を強制します。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自分のリソースにアクセスするユーザー |
| `organization_member` | そのリソースを所有する組織のメンバー |
| `organization_admin` | そのリソースを所有する組織の管理者 |
| `public_account` | リソースはパブリックアカウントに属している |

### メンバー権限

管理者でない組織メンバーシップは、明示的な同意権限スコープを notification できます。新メンバーは、アカウント、組織、プロジェクト、音声、用語集、ディスカッション、チケット、翻訳アクティビティ、および分析への読み取りアクセス、および自分のプライベート Toki 会話へのアクセスで始まりです。組織管理者は、[メンバー → 権限](/docs/how-to/member-permissions) を通じてこれらのスコープを置換できます。トークンを使用する際に、要求されたアクションはメンバーの許可されたスコープにもトークンのスコープにも含まれていなければなりません。

プライベート Toki 所有権は、組織メンバースコープオーバーライドの前にチェックされます。どちらもメンバーシップ付与により、または管理者ロールが別のユーザーの会話を許可しません。プロジェクトの可視性は別途チェックされます。エンドポイントスコープと制限については[モバイルおよびコンパニオン API](/docs/reference/apis/mobile) を参照してください。

組織管理者は管理者ロールを維持します。明示的なスコープがない既存のメンバーシップは、パーミッションが保存されるまで beneath のロールベースのポリシーの使用を続けます。

### ロール権限

下部の表は、明示的なスコープを有さないメンバーシップにおける一般的なロールベースルールを示します。完全なポリシーではありません：コレクションリクエスト、一時的なアクセス、プラットフォーム管理者には追加ルールがあります。

| スコープ | 自身 | 組織メンバー | 組織管理者 | パブリックアカウント |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | はい | はい | | |
| `user:write` | はい | | | |
| `account:read` | | はい | はい | はい |
| `organization:read` | | はい | はい | |
| `organization:write` | | | はい | |
| `organization:delete` | | | はい | |
| `organization:admin` | | | はい | |
| `members:read` | | はい | はい | |
| `members:write` | | | はい | |
| `project:read` | | はい | はい | はい |
| `project:write` | | | はい | |
| `project:admin` | | | はい | |
| `project:delete` | | | はい | |
| `voice:read` | | はい | はい | はい |
| `voice:write` | | | はい | |
| `voice:admin` | | | はい | |
| `glossary:read` | | はい | はい | |
| `glossary:write` | | | はい | |
| `glossary:admin` | | | はい | |
