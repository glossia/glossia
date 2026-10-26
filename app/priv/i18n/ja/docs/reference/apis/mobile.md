%{
  title: "モバイルおよびコンパニオン API",
  summary: "ネイティブ外観、プロフィール、翻訳活動、分析、およびプライベート Toki 会話。",
  category: "参照",
  subcategory: "API",
  order: 4
}
---

パブリックネイティブ外観カタログを除くすべてのエンドポイントにはベアラートークンが必要です。[OpenAPI 仕様](/api/openapi.json) に完全なスキーマが説明されています。既存の[OAuth PKCE フロー](/docs/reference/apis/authentication) を通じてトークンを獲得してください。クライアントに推論プロバイダーキーを埋め込むことは決してしないでください。

## 権限

| エンドポイント | トークンスコープ |
|---|---|
| `GET /api/native/themes` | なし（パブリック外観メタデータ） |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

トークンスコープは上限であり、付与ではありません。各プロジェクトエンドポイントは、ユーザーのプロジェクト読み取り権限も確認します。もう一つの`project:read`**トークン** スコープは要求されないが、明示的な権限を持つ組織メンバーシップは、プロジェクトの読み取りおよび要求された能力の両方を許可する必要があります。新しいメンバーシップにはこれらのモバイル能力が含まれますが、明示的なメンバーシップは自動的に拡張されません。

パーソナルプロジェクトは既存の個人組織メンバーシップ規則に従います。アカウントの可視性がパブリックプロジェクト読み取りを制御します；必要なスコープを持つ認証された外部ユーザーは、パブリックプロジェクトの翻訳アクティビティおよび分析を読める場合があります。Tokike の書き込みにはアカウントメンバーシップが必要です。したがって、パブリックのみの可視性ではアカウントの推論クレジットを消費しません。トキ会話は、パブリックアカウントであっても、プロジェクト内で作成_user_ に私有され続けます。組織またはプラットフォーム管理者は別のユーザーの会話を閲覧することはできません。会話のUUIDを知るだけではアクセスは得られません。

## ネイティブ外観

`GET /api/native/themes` は選択された Glossia サーバーからのインスタンス全体の外観メタデータを返します。認証やユーザー/プロジェクトデータなしで。レスポンスには`Cache-Control: public, max-age=300` が含まれます。これはプロジェクトエンドポイントの何れの認証を変更しません。

レスポンスには 4 つの必須項目が含まれます。

| フィールド | 値 |
|---|---|
| `schema_version` | 整数 `1` |
| `revision` | 非空白のコンテンツ改訂バージョン、最大 128 文字 |
| `default_theme_id` | `"glossia"` |
| `themes` | デフォルト Glossia テーマを含むアレイ |

デフォルトテーマには`id: "glossia"`, `name: "Glossia"`、非空白の`description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`、および`light` と`dark` パレットが含まれます。半径は数値論理ピクセルです。各パレットは以下に示されたすべての 9 フィールドを含み、不透明`#RRGGBB` 色として表されます。

| パレットのフィールド | ライト | ダーク |
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

カタログは、`app/priv/static/assets/styles.css` にある規範的な`:root` カラーおよび半径トークンからコンパイルされます。ダークパレットはネイティブだけセマンティックトークンを使用し、Web レンダリングを変更しません。トークン変更後の再構築は、カタログとその決定論的な改訂を更新します。改訂はカタログコンテンツを含み、関連しないスタイルシートの編集を含みません。ユーザーごとの設定やランタイムテーマ構成は含まれません。

## プロフィール

`GET /api/me` は認証されたユーザーのプロフィールのみを返します。

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

`name` は`null` である場合があります。ハンドルは選択された組織ではなく、ユーザーの個人アカウントに属します。`server_version` は実行中のアプリケーションのバージョンです。

## ページネーション

翻訳および会話リストは`page`（デフォルト`1`、範囲`1–10000`）および`page_size`（デフォルト`20`、範囲`1–50`）を受け入れます。無効な値は`400` を返し、サイレントにクランプしません。メタデータは他の Glossia API リストと同じ形状を使用します。

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

リストは現在の状態を反映し、フrozen のスナップショットではありません。会話順序は最新更新を最初に入れ、UUID を決定論的なタイブレーカーとして使用します。

## 翻訳アクティビティ

`GET /api/:handle/projects/:project/translations?page=1` はそれらを返します:

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

ステータスは`pending`, `running`, `completed`, `failed`、または`cancelled` です。コミットメッセージ、ソース言語、およびサマリーは、作業が保留中または利用不可の場合`null` である場合があります。結果は最新順で、対応プロジェクトに制限されます。

`GET /api/:handle/projects/:project/translations/:id` は`{session: {...}, progress: {...}}` を返します。`session` はリストセッションフィールドに、オプショナル nullable`commit_sha` が含まれ不変です。`progress` は Web ダッシュボードと同じ Elixir 進捗リデューサーを使用して耐久性のあるイベントから再構築されます。これは、ページネーションやセッションの年齢に依存せず、対象プロジェクトおよびアカウント内の直接的な正確な UUID ロックアップです。不正、欠落、および外国プロジェクト ID は`404` とともに`error: "not_found"` を返し; 認証とプロジェクト認証は最初に実行されます（`401`/`403`）。このリソースを開くことは、決して会話を作成せず、メッセージを送信せず、推論を開始しません。それは翻訳されたセグメントテキストまたは翻訳された出力のレビューを提供するのではなく、**セッションサマリーレベルのプロベナンス** および各ファイルの進捗を提供します。

### ネイティブライブ進捗

永続的な Phoenix WebSocket を`/native/socket/websocket?vsn=2.0.0` で開きます（HTTPS サーバー上では`wss`）。Longpoll は無効です。アクセストークンは WebSocket サブプロトコルヘッダーを通じてのみ送信され、クエリパラメータでは決して送信しないでください:

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

サーバーは`phoenix` を交渉します。トピック`translation:<session UUID>` に`{"organization":"account-handle","project":"project-handle"}` で参加します。組織値は HTTP API が使用する同じアカウントハンドルで、パーソナルアカウントを含みます。参加返信および/`snapshot` イベントは HTTP 詳細と同じ完全な投影を含みます:

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

`seq` は永続的な進捗シーケンスであり、**ではなく**一意のスナップショットバージョンです。セッションステータス/公開変更およびライブモデルコールカウントは、同じシーケンスを持つ新しいスナップショットを生成できます；`seq` が不変であっても以前の投影を置換します。ファイルごとのステータスは`queued`, `running`, `done`, `failed`、および`cancelled` です。パス、ロケール、およびファイル参照は、それらが未知の`null` である前にあります。不変のセッションは、シーケンスゼロ、空アイテム、およびゼロカウントを持ちます。サマリーは、**全て** のファイルを含み、アイテムが省略されている場合でも。サマリーの用語集識別子/カウントは Web リデューサーの集計であり、プロバイダーメタデータではありません。

計上インデックス順序で、最大 500 アイテムが含められ、組み合わせたエンコードアイテム予算 512,000 バイトです。適合しないアイテムは省略され、`omitted_items` はどちらかの制限で除外された全行カウントします。生の翻訳出力、ストリーミングテキスト、思考、プライベートプロバイダーペイロード、および生の障害詳細は決して含められません。ライブパブリックモデルコールカウントは再接続または整合後にリセットできます；永続的な最終カウントおよびファイル状態は再構築されます。完全なネイティブスナップショットは 1,000,000 組み込まれたエンコード JSON バイトまで制限されます。もし不変セッションメタデータまたは完全サマリーだけでその制限を超えると、加入は`{"reason":"payload_too_large"}` で失敗するか、既存チャネルは`error` とその理由を受け、クローズします。サイズオーバーフレームを送信するか、またはサイレントに pb too large を切る代わりに。

サーバーは永続的なプレフィックスを **前に** 読み込む前の既存のクロスノードセッション PubSub に購読し、シーケンス重複除去と共にライブテールを折りたたみ、進捗ステータス公開通知を統合して約 100with で完全スナップショットに統合します。各クライアントごとの HTTP ポリングやランナーローカル状態は不要です。5 秒ごとに Authorization を更新し、欠落した通知を修復するために永続状態を再構築します。フォアグラウンド化または経路中断後に再接続し、再度加入します。Join プロジェクションはデルタを再生しないだけであります。接続中は正常な Phoenix ハートビートライフサイクルに従い、表示が終わったらトピックを離れます。

現在の永続化トークン権限、有効期限/リボーク、ユーザー、`translation:read` トークンスコープ、ポリシー権限、プロジェクト可視性、および正確なアカウント/プロジェクト/セッションの関連付けは、加入時およびすべてのスナップショット前にチェックされます。不足するスコープまたはポリシー権限は `{"reason":"forbidden"}` を返し、不足するリソースは `{"reason":"not_found"}` を返し、期限切れ/リボークした認証は `{"reason":"sign_in_required"}` を返します。成功した加入後、拒否は理由とともに `access_revoked` を出力し、別のスナップショットなしでチャネルをすぐに閉じます。更新もアイドルしたチャネルでリボークを検出します。`sign_in_required` に対するは、更新/再認証し、新しい接続を作成します；他の拒否には、保護された詳細の表示を停止します。WebSockets はフォアグラウンドライブ更新メカニズムであり、モバイルアプリがサスペンドされている間の配信の保証ではありません。

## 分析

`GET /api/:handle/projects/:project/analytics?days=30` はサマリー指標、最多 10 ページ、およびトラフィック時間系列を返します。空プロジェクトは返します：

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

`days` のデフォルトは `30` であり、`1` から `365` の整数である必要があります。回転 UTC 報告ウィンドウはリクエスト時点で終了します。これらはダッシュボードと同じプロジェクトスコープの ClickHouse 集計であり、日次回転訪問者識別子を含まれます。ストレージ障害は `503` を `error: "analytics_unavailable"` で返し、零以上の無意味な指標を返しません。

`traffic.granularity` は 2 日までのウィンドウでは `"hour"`、90 日までのウィンドウでは `"day"`、それ以外では `"month"` となります。`traffic.points` は時系列的です。各点是 UTC バケット開始時刻と負でない整数カウントを含みます：

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

カウントは要求された報告ウィンドウ内のイベントのみが含まれます。したがって、最初と最後のバケットは部分的である可能性があります。イベントが存在する場合、そのウィンドウでの静かなバケットはゼロカウント付きで含まれます。イベントが存在しない場合、`points` は合成の平坦傾向の代わりに空です。`unique_visitors` は各バケットの **内** で特異識別子をカウントし、これらの値の合計はその期間の特異訪問者数を示しません。`summary.unique_visitors` をその合計に使用してください。クライアントは返されたバケットを変更せずにプロットし、サマリー指標から傾向を再構築するべきではありません。

## Toki 会話

### 作成およびリスト化

`POST /api/:handle/projects/:project/toki/conversations` はクライアント生成 UUID を受け入れます：

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

それは `201` と `{conversation, messages: []}` を返します。空会話はタイトル `New conversation` とステータス `completed` (アイドル、生成なし) を持っています。同じアクター、プロジェクト、および起源の同じ UUID を再生成すると、別の会話を作成せずに既存の詳細を返します。別のアクター、プロジェクト、または起源で使用すると、`409` と `error: "id_conflict"` を返します。

`GET /api/:handle/projects/:project/toki/conversations` は `{conversations: [...], meta: {...}}` を返します。会話は `id`, `title`, `status`, `updated_at`, オプション `error`, 以及 オプション `translation_session_id` を含みます。タイトルは最初のユーザーメッセージから派生し、2 番目のモデルコールからではありません。

### 翻訳の起源

作成はオプションとして同じプロジェクトからの翻訳セッション UUID を受け入れます：

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

起源は不変です。省略と `null` はどちらも起源がありません。再試行はメッセージ送信后立即に同じ起源を提供する必要があります。起源を後に追加したり、再試行で削除することはできません。破損した起源は `422` を返します；欠落または外国プロジェクトソースは `404` を返します。ソースリンク作成は追加的に `translation:read` トークンスコープと現在のポリシー権限、および `toki:write` とプロジェクト読み取り権限を必要とします。クライアント供給ソースサマリー、メタデータ、ロール、および所有権は無視されます。UUID だけが永続化されます；サーバーは返信時に権限化コンテキストを解決します。

**ソースリンク会話は正常終了しない**：現在の `translation:read` スコープまたはポリシー権限がないと、詳細、一致する起源の作成再生成、メッセージ送信、およびメッセージ再生生成は `403` を返します。不一致の起源はまだ `409` を返しますが、履歴またはソースメタデータを返しません。リストは完全なソースリンク会話を省略し、タイトルとページネーションカウントへの貢献を含むようです。これはソースを言及する可能性のある以前のサステントメッセージを保護します。不足スコープには通常の `WWW-Authenticate` チャレンジが含まれます。リンクされていない会話は既存の Toki 専用認証振る舞いを維持します。

削除または移動されたソースも正常終了：ソースリンク詳細、送信、および一致する生成再生行は `404` を返し、リストは会話を省略します。不変 UUID はソース削除後に格納されるため、再試行がサイレントにリンクから外れることはありません。参照には連鎖的外icles キーがなく、すべての使用は現在のソースの存在と正確なプロジェクト/アカウントをチェックします。ソース参照はアクセス権限を与えたり、 voix、用語集、または共有コンテキストを変更したりしません。

ソースリンク会話の作成または開會是 **ない** メッセージを送信するまたは推論を並行します。ネイティブナビゲーションは最初に翻訳詳細を取得すべきです；明示的なユーザー行動のみが会話を作成し、別個の明示的なメッセージ提出がターンを開始します。提案発行、共有議論レビュー、またはエージェント書式ツールは提供されません。

### 送信およびポーリング

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` はクライアント生成 **メッセージ** UUID を受け入れます：

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

リクエストはユーザーメッセージと Oban のジョブを 1 つのデータベーストランザクションでレコードします。モデルを呼び出しません。ステータス `queued` と現在のメッセージを `202` で返します。ステータスが `queued` または `running` の間は `GET /api/:handle/projects/:project/toki/conversations/:id` をポーリングします；`completed` または `failed` で停止します。

詳細応答はこの形状です：

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

メッセージは役割 `user` または `assistant` を持ち、時系列です。会話は最大 100 メッセージを受け入れ、したがって詳細エンドポイントは追加ページ要求なしでその全体境界履歴を返します。

同じ内容のメッセージ UUID を再生しても、その後の完了や失敗を含め、推論を並行することは決してありません。確定した再生は `200` を返し、待機中の再生は `202` を返します。別の内容または別の会話で UUID を再利用すると `409` が返ります。ターンがアクティブな間、別のメッセージを提出すると `409` に `error: "conversation_busy"` が付与されます。

### モデルの動作と制限

- ユーザーメッセージは空白ではないテキストで、最大 8,000 文字および 32,000 UTF-8 バイトです。無効な UUID、タイプ、またはコンテンツは `422` を返します。
- 各ユーザーは、プロジェクト当たり最大 100 の会話と、プロジェクト全体で 5 つの待機/実行中の会話のみ保持できます。待機中のターンが 5 つを超えると `429` が返り、会話/履歴制限は `422` を返します。
- 新規メッセージは通常 API レート制限に加えて、每户服務器当たりユーザー当たり 1 時間 30 通までです。再生は推論配分を消費しません。
- 専用 Oban キューは每户服務器で 2 つのジョブを並行して実行します。各ターンは最大 1 つの提供者 HTTP 要求を作ります：ReqLLM が提供者要求を準備し、その後 Oban ワーカーがプロバイダーアタッチ後 HTTP 再試行と転送を無効にしながら揃って実行します。Condukt セッション、離脱推論タスク、ツール、サブエージェント、またはファイルシステム指示読み込みは関与しません。提供者は 2,048 出力トークンの天井を受け取り、アシステント返信も最大 8,000 文字および 32,000 バイトまで制限されます。
- HTTP 接続およびプール待ちは 5 秒、ソケット受信待ちは 60 秒まで制限されます。Oban ワーカーには、トリクルして応答を含む 90 秒の硬い壁時計制限があります。ワーカー終了はローカル推論実行も終了します。接続切断はリモート提供者が既に受信した計算のキャンセルを保証できないため、曖昧な失敗は決して自動的に再試行されません。
- モデルは制限されたプロジェクトメタデータを受け取り、トークンと現在のメンバーシップが `translation:read` を許可する際に最大 3 つの最近の翻訳サマリーを受け取ります。最後の 10 通の会話抜粋はストレージから独立して箇所されいます。書き込み機能や一般リポジトリアクセスはなく、モデルには分析データは提供されません。
- ソースリンク会話では、モデルは正確に永続化されたソースは、それが最新でない場合でも追加で受け取ります：UUID、ステータス、コミットメタデータ、言語、カウント、および最大 1,000 サマリー文字まで。コンテキストは `provenance: "session_summary"` とラベルされ、プロンプトはこのサマリーレベル制限の報告を必要とします。セグメントテキスト、リポジトリファイル、またはクライアント提供のソースコンテキストは読み込まれません。
- 認証情報は、アカウントの既存の生成モデルとサーバー推論設定を通じて解決されます。インタラクティブ CLI/OAuth セッションは Toki には使用されません。欠落または未対応の認証情報はステータス `failed` を `error: "provider_unavailable"` とともに返します。
- 提供者失敗は `inference_failed` を作り出します；空またはオーバーサイズの出力は `invalid_provider_response` を作り出します。生の提供者エラーと機密情報ではありません。失敗には合成アシステント返信は挿入されません。
- アカウント/プロジェクトアクセスとソース存在、プロジェクト/アカウント関連付け、および翻訳認可は推論前後で再確認されます。取り消されたアクセスや不足待機スコープはターンに `not_authorized` を失敗し；削除または移動されたソースは `source_unavailable` で失敗します。どちらの失敗にもアシステント応答は永続化されません。
- 回復ジョブは毎分実行され、2 分以上経過した実行中のワークまたは 15 分以上経過したキュー中のワークを `failed` のステータスと `inference_interrupted` とともにマークします。これにより、タイムアウト、遮断、孤児ジョブは推論の再試行なしで解決されます。遅延ジョブは期限切れのメッセージを取得したり、新しいターンを上書きしたりすることはできません。ユーザーは失敗後、意図的に **new** メッセージ UUID を送信できます。

## エラー

`401` は認証失敗を意味します。 `403` はスコープまたはリソースポリシーがアクセスを拒否しました；欠落スコープには `WWW-Authenticate` チャレンジが含まれます。UNKNOWN プロジェクトと国外/私有会話 UUID は `404` を返します。バリデーションは `422` を使用、パギネーションは `400` を使用、UUID/バジユーetical 衝突は `409`、クォータ枯渇は `429` を使用します。
