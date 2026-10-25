%{
  title: "モバイルおよびコンパニオン API",
  summary: "ネイティブ外観、プロフィール、翻訳活動、分析、およびプライベートな Toki 会話。",
  category: "リファレンス",
  subcategory: "API",
  order: 4
}
---

パブリックネイティブ的外観カタログを除く、すべてのエンドポイントではブーラー トークンを必要とします。[OpenAPI 仕様書](/api/openapi.json) が完全なスキーマを記述します。既存の [OAuth PKCE フロー](/docs/reference/apis/authentication) を通じてトークンを取得してください。クライアントに推論プロバイダーのキーを埋め込まないようにしてください。

## 権限

| エンドポイント | トークン スコープ |
|---|---|
| `GET /api/native/themes` | なし（パブリックの外観メタデータ） |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

トークン スコープは上限であり、承認権限ではありません。各プロジェクトエンドポイントでは、ユーザーのプロジェクト読み取り権限も確認されます。2 つ目の `project:read` **トークン** スコープは必須ではありませんが、明示的な権限を持つ組織メンバーシップは、すべてのプロジェクト読み取りと要求された機能の許可を行わなければなりません。新しいメンバーシップにはこれらのモバイル機能が追加され、既存の明示的なメンバーシップは自動的に拡張されることはありません。

個人プロジェクトは、既存の個人・組織メンバーシップルールに従います。アカウントの可視性がパブリックのプロジェクト読み取りを制御します。必要なスコープを持つ認証済み外部ユーザーは、パブリックプロジェクトの翻訳活動や分析を読み取ることができます。Toki 書き込みにはアカウントメンバーシップが必要であるため、単独のパブリック可視性はアカウントの推論クレジットを消費しません。Toki 会話については、パブリックアカウントであっても、プロジェクト内で作成ユーザーにのみ保持されます。組織とプラットフォームの管理者は、他のユーザーの会話を読み取ることができません。会話の UUID を知っているだけではアクセス権が得られません。

## ネイティブの外観

`GET /api/native/themes` 返します。選択された Glossia サーバーからインスタンス全体の的外観メタデータを、認証またはユーザー/プロジェクトデータなしで返します。レスポンスには `Cache-Control: public, max-age=300` を含みます。これにより、どのプロジェクトエンドポイントの権限も変更しません。

レスポンスには、4 つの必須フィールドがあります：

| フィールド | 値 |
|---|---|
| `schema_version` | 整数 `1` |
| `revision` | 空白なしのコンテンツリビジョン、最大 128 文字 |
| `default_theme_id` | `"glossia"` |
| `themes` | デフォルトの Glossia テーマを含むアレイ |

デフォルトテーマには `id: "glossia"`, `name: "Glossia"`、非空白の `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, および `light` および `dark` パレットがあります。半径は数値的な論理ピクセルです。各パレットには、以下のすべての 9 つのフィールドが含まれ、不透明な `#RRGGBB` カラーとして表現されます：

| パレットフィールド | ライト | ダーク |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

カタログは、`app/priv/static/assets/styles.css` の規範的な `:root` カラーおよび半径トークンからコンパイルされます。ダークパレットはネイティブのみセマンティックトークンを使用し、Web レンダリングを変更しません。トークン変更後の再構築は、カタログとその決定論的なリビジョンを更新します。リビジョンはカタログコンテンツをカバーし、無関係なスタイルシート編集はカバーしません。ユーザー別設定や実行時テーマ構成を含めません。

## プロファイル

`GET /api/me` 認証ユーザーのプロファイルのみを返します：

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` は `null` になることがあります。ハンドルはユーザーの個人アカウントに属しており、選択された組織には属しません。`server_version` は現在実行中のアプリケーションのバージョンです。

## ページネーション

翻訳と会話リストは `page` を受け入れます（デフォルト `1`、範囲 `1–10000`）。また `page_size` も受け入れます（デフォルト `20`、範囲 `1–50`）。無効な値は `400` を返し、沈黙して範囲変更は行われません。メタデータは他の Glossia API リストと同じ形式を使用します：

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

リストは現在の状態を反映し、固定的なスナップショットではありません。会話の並べ替えは最新更新順であり、UUID を決定論的なタイブレーキとして使用します。

## 翻訳アクティビティ

`GET /api/:handle/projects/:project/translations?page=1` 返します：

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

ステータスは `pending`, `running`, `completed`, `failed`, または `cancelled` です。コミットメッセージ、ソース言語、およびサマリーは、作業が待機中または利用できない間は `null` になることがあります。結果は最新のものの順に返され、対象プロジェクトに限定されます。

`GET /api/:handle/projects/:project/translations/:id` は `{session: {...}, progress: {...}}` を返します。`session` は、list session フィールドを検索し、加えて nullable `commit_sha` を含む、正確なリストセッションフィールドを得て、unchanged です。`progress` は、Durable イベントから再構築され、同じ Elixir progress reducer を使用します。Web ダッシュボードと同様です。これは、addressed project およびアカウントでの直接的な、exact UUID ルックアップであり、pagination や session の age に依存しません。Malformed、missing、および foreign-project IDs は `404` で `error: "not_found"` を返します。認証とプロジェクト認証は最初に走ります (`401`/`403`)。このリソースを開くことでは、会話を作成したり、メッセージを送信したり、推論を開始したりすることはありません。**session-summary-level provenance** と per-file progress を提供しますが、translated segment text や翻訳結果のレビューではありません。

### ネイティブライブ進行状況

持続 Phoenix WebSocket を `/native/socket/websocket?vsn=2.0.0` で開きます (`wss` 上に HTTPS サーバー)。Longpoll は Disabled です。アクセストークンは WebSocket サブプロトコルヘッダーを介してのみ送信してください。クエリパラメーターを介しては決して送信しないでください：

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

サーバーは `phoenix` を交渉します。トピック `translation:<session UUID>` に `{"organization":"account-handle","project":"project-handle"}` で参加します。組織値とは、HTTP API で使用されるアカウントハンドルと同じであり、個人アカウントを含む。参加応答と各 `snapshot` エベントは HTTP の詳細と同じ完全な投射を持つ：

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` は持続的な進行シーケンスであり、 **独自の** スナップショットバージョンではありません。セッションステータス/公開状態の変更とライブモデルコール回数は、同じシーケンスを持つ新しいスナップショットを生成することがあります。たとえ `seq` が変わらなくても、以前のスナップショットを置換します。ファイルごとのステータスは `queued`, `running`, `done`, `failed`, および `cancelled` です。パス、ローカール、およびファイル参照は不明の `null` になることができます。無効なセッションはシーケンスがゼロで、アイテムが空で、カウントがゼロです。サマリーは、指定されたアイテムが含まれていなくても、すべての **ファイル** をカバーします。サマリーの辞書識別子/カウントは、Web レダクターの集計であり、プロバイダーメタデータではありません。

計画されたインデックス順で、最大 500 のアイテムが含まれ、結合されたエンコードアイテム予算は 512,000 バイトです。フィットしないアイテムは省略され、`omitted_items` は両方の制限によって除外されたすべての行をカウントします。生翻訳出力、ストリーミングテキスト、思考、プライベートプロバイダーペイロード、および生エラー詳細は決して含まれません。ライブパブリックモデルコール計数は再接続または整合後にリセットされることがあり、恒久的な最終カウントとファイルステートは再構築されます。完全なネイティブスナップショットは 1,000,000 エンコード JSON バイトに制限されます。変更のないセッションメタデータまたは完全なサマリーだけがその制限を超えた場合、接続は `{"reason":"payload_too_large"}` で失敗するか、既存のチャンネルはその理由で `error` を受け取り、閉じます。 oversized フレームを送信するか、来歴を沈黙して切り捨てることなく。

サーバーは永続プレフィックスを読み込む **前に** 既存のクロスノードセッション PubSub に購読します。ライブテールをシーケンス重複除去で結合し、progress、status、publication 通知を約 100ms で完全なスナップショットに統合します。クライアントごとの HTTP ポーリングまたはランナーローカル状態は不要です。5 秒ごとに認証を更新し、見逃された通知を修復するために永続状態を再構築します。フォーグランド化またはトランスポート中断後に再接続し、再参加します。参加プロジェクションは Delta の複製なしで十分です。接続中は通常の Phoenix ハートビートライフサイクルに従い、表示しない場合はトピックを離れます。

現在の永続ト〖クン許与、有効期限 / 取消、ユーザー、`translation:read` トークンスコープ、ポリシー許可、プロジェクト可視性、および正確なアカウント / プロジェクト / セッション関連付けは、参加時および各スナップショット前にチェックされます。不足したスコープまたはポリシー許可は `{"reason":"forbidden"}` を返し、欠落したリソースは `{"reason":"not_found"}` を返し、期限切れ / 取消された認証は `{"reason":"sign_in_required"}` を返します。成功した参加後、拒否は `access_revoked` をその理由とともに出力し、別のスナップシートのないようにすぐにチャンネルを閉じます。更新はまた、アイドルチャンネルの取消を検出します。`sign_in_required` の場合、刷新 / 再認証を行い、新しい接続を作成します。他の拒否については、保護された詳細を表示を停止します。WebSocket は Foreground のライブ更新メカニズムであり、モバイルアプリがサスペンデされているときに配送を保証するものではありません。

## 分析

`GET /api/:handle/projects/:project/analytics?days=30` は概要メトロック、最大 10 のトップページ、およびトラフィックタイムシリーズを返します。空のプロジェクトは以下のものを返します:

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` デフォルトは `30` であり、`1` から `365` の間の整数である必要があります。ローリング UTC レポートウィンドウはリクエスト時点に終了します。これらは、日付回転された訪問者 ID を含む、ダッシュボードと同じプロジェクト スコープ ClickHouse 集計です。ストレージ障害は `503` を返します。`error: "analytics_unavailable"` を含めて、決して 0 メトリックを発明しません。

`traffic.granularity` は 2 日以下のウィンドウでは `"hour"`、90 日以下のウィンドウでは `"day"`、それ以外は `"month"` です。`traffic.points` は時系列です。各ポイントは、UTC バケット開始タイムスタンプと非負整数のカウントを含みます:

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

カウントは、リクエストされたレポートウィンドウ内のイベントのみを含みます。そのため、最初のバケットは一部で、最後のバケットも不完全になります。イベントが存在する場合、そのウィンドウ内の静かなバケットはゼロカウントで含まれます。イベントが存在しない場合、`points` は_synthetic 平坦なトレンドではなく空になります。`unique_visitors` は一意の識別子 **各バケット内** を数えます。これらの値合計は期間の一意の訪問者数を得ません。`summary.unique_visitors` を使用してその合計を取得します。

## Toki 会話

### 作成とリスト

`POST /api/:handle/projects/:project/toki/conversations` はクライアント生成の UUID を受けます:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

それは `201` を `{conversation, messages: []}` に返します。空の会話はタイトル `New conversation` とステータス `completed` (idle, not generating) を持っています。同じアクター、プロジェクト、および起源での同じ UUID の再生は、別の会話を作成せずに既存の詳細を返します。別のアクター、プロジェクト、または起源で再利用すると `409` を `error: "id_conflict"` に返します。

`GET /api/:handle/projects/:project/toki/conversations` は `{conversations: [...], meta: {...}}` を返します。会話は `id`, `title`, `status`, `updated_at`, nullable `error`, および nullable `translation_session_id` を含みます。タイトルは最先ユーザーメッセージから導かれ、第二モデルコールからではありません。

### 翻訳起源

作成はオプションで同じプロジェクトからの翻訳セッション UUID を受けます:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

起源は不変です。省略および `null` はどちらも起源はありません。再試行は、メッセージ送信後を含む、同じ起源を提供する必要があります。後に起点を付加することも、再試行で起源を削除することもできません。誤った起源は `422` を返します。欠落したまたは外国プロジェクトのソースは `404` を返します。ソースリンク作成は、さらに `translation:read` トークンスコープと現在のポリシー許可、および `toki:write` および プロジェクト読み取り許可を必要とします。クライアント提供のソースサマリー、メタデータ、役割、および所有物は無視されます。UUID は永続化されだけです；サーバーは返信時にその許可されたコンテキストを解決します。

**ソースリンク会話は閉鎖で失敗します**、UUID を単に削除するのではなく。現在の `translation:read` スコープまたはポリシー許可がない場合、詳細、マッチング起源の再試行、メッセージ送信、およびメッセージ返信は `403` を返します。不一致な起源も、歴史またはソースメタデータを返さないで `409` を返します。リストは、タイトルとページネーションカウントへの寄与を含むソースリンク全体の会話を省略します。これは、ソースを言及する可能性のある早期アシスタントメッセージを保護します。欠落したスコープには、通常の `WWW-Authenticate` チャレンジが含まれます。リンクされていない会話は既存の Toki みの権限化動作を守ります。

削除または移動されたソースも閉鎖運用します。ソースリンク詳細、送信、およびマッチング作成再試行は `404` を返し、リストは会話を省略します。不変 UUID はソース削除後にも保存され、再試行は黙ってリンクを外れません。参照はカッケーディング外部キーを持っていません；すべての使用は現在のソース存在とそれの正確なプロジェクト / アカウントをチェックします。ソース参照はアクセスを付与したり、声や辞書または共有コンテキストを変更したりしません。

ソースリンク会話を生成または開くことは **しない** メッセージを送信または推論をキューにします。ネイティブナビゲーションは翻訳詳細を最初に取得する必要があります。明確なユーザー行動のみで会話を生成し、個別の明らかなメッセージ送信でターンを開始します。提案公表や共有ディスカッション確認、またはエージェント書きツールは提供されていません。

### 送信およびポーリング

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` は別のクライアント生成の **メッセージ** UUID を受けます:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

リクエストはユーザーメッセージと Oban ジョブを一個のトランザクションで永続化します。モデルを呼び出しません。`202` で、ステータス `queued` と現在のメッセージを返します。ステータスが `queued` または `running` の間、`GET /api/:handle/projects/:project/toki/conversations/:id` をポーリングします。`completed` または `failed` で停止します。

詳細応答は以下の形状です:

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

メッセージはロール `user` または `assistant` をもち、時系列です。会話は最大 100 メッセージを保持できるので、詳細エンドポイントは追加のページリクエストなしにその有界された履歴のすべてを返します。

同一コンテンツを持つメッセージ UUID の復元は、完了または失敗を含む他の推論をキューにしません。確定した復元は `200` を返し、保留の復元は `202` を返します。異なるコンテンツを持つ UUID や他の会話での再利用は `409` を返します。ターン中に別のメッセージを送信すると `409` で `error: "conversation_busy"` を含まれます。

### モデルの動作と制限

- 各ユーザーメッセージは空でなく、最大 8,000 キャラクターおよび 32,000 UTF-8 バイトです。無効な UUID、型、またはコンテンツは `422` を返します。
- 各ユーザーは、プロジェクトごとに最大 100 回の会話を保持でき、プロジェクト全体で最大 5 つの非完了/実行中の会話を持てる。待機状態で 5 つを超えるターンは `429` を返し、会話/履歴制限は `422` を返します。
- 新メッセージは、通常の API レート制限に加え、サーバーごとのユーザーごとの 1 時間あたり 30 未満に制限されます。復元では推論クォータは消費しません。
- 専用 Oban クエはサーバーごとに 2 つのジョブを並列実行します。各ターンは最大 1 つのプロバイダー HTTP リクエストを作成します：ReqLLM がプロバイダーリクエストを準備し、次に Oban ワーカーがプロバイダーアタッチ後の HTTP リトライとリダイレクト無効化で同期実行します。Condukt セッション、独立推論タスク、ツール、サブエージェント、またはファイルシステム指示読み込みは関与しません。プロバイダーは 2,048 出力トークン上限を受けます。アシスタント返答も最大 8,000 キャラおよび 32,000 バイトに制限されます。
- HTTP 接続およびプール待ちは 5 秒、ソケット受信待ちは 60 秒に制限されます。Oban ワーカーには 90 秒のハードウォールクロック締め切りがあり、ストリーム応答を含みます。ワーカー終了はローカル推論実行も終了します。接続切断は遠隔プロバイダーによってすでに受け入れられた計算のキャンセルを保証できないため、不明確な失敗は決して自動的に再試行されません。
- モデルは有界プロジェクトメタデータを取得し、トークンと現在のメンバーシップが `translation:read` を許可するときに、最近の翻訳サマリーの最大 3 つを受けます。最後の 10 の会話断片はストレージとは独立して有界されます。モデルには書き込み機能や一般リポジトリアクセスはなく、分析データはモデルに提供されません。
- ソースリンク会話の場合、モデルは正確な永続化ソースをさらに受け取ります。それは最新でなくても構いません：UUID、ステータス、コミットメタデータ、言語、カウント、そして最大 1,000 サマリー文字。コンテキストは `provenance: "session_summary"` としてラベル付けされ、プロンプトはこのサマリーレベルの制限を報告することが必要です。セグメントテキスト、リポジトリファイル、またはクライアント提供のソースコンテキストは読み込まれません。
- 認証情報は、アカウントの既存の生成モデルおよびサーバー推論設定を通じて解決されます。インタラクティブ CLI/OAuth セッションは Toki で使用されません。欠落またはサポートされていない認証情報はステータス `failed` で `error: "provider_unavailable"` を生成します。
- プロバイダーの失敗は `inference_failed` を生成します。空または大きすぎた出力は `invalid_provider_response` を生成します。生のプロバイダーエラーと秘密は返されません。失敗時に作成された合成アシスタント返答は挿入されません。
- アカウント/プロジェクトアクセスおよびソース存在、プロジェクト/アカウント関連、および翻訳承認は推論の前後にチェックされます。撤回アクセスまたは不足キュースコープはターンで `not_authorized` に失敗します。削除または移動されたソースは `source_unavailable` で失敗します。どちらの失敗でもアシスタント応答は永続化されません。
- 復旧ジョブは毎分実行され、2 分以上経過した実行中ジョブ、または 15 分以上経過したキューワークを `failed` で `inference_interrupted` にマークします。これはタイムアウト、終了、孤立ジョブを再試行せずに解決します。遅延ジョブは有効期限切れメッセージを主張したり、新しいターンを書き換えたりできません。ユーザーは失敗後、明示的に **new** メッセージ UUID を送信する可能性があります。

## エラー

`401` は認証失敗を意味します。`403` はスコープまたはリソースポリシーがアクセスを拒否しました。不足スコープは `WWW-Authenticate` チャレンジを含みます。不明なプロジェクトおよび外国/プライベート会話 UUID は `404` を返します。検証は `422` を使用し、ページネーションは `400` を使用し、UUID/忙しい衝突は `409` を使用し、クォータ枯渇は `429` を使用します。
