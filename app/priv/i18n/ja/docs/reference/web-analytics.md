%{
  title: "分析 SDK",
  summary: "収集フィールド、イベントエンドポイント、ならびに Glossia ウェブ分析の背後にあるプライバシーモデルです。",
  category: "参考",
  order: 1
}
---
## イベントエンドポイント

`POST /api/analytics/events`

SDK から JSON イベントを受け取り、 `@glossia/web` SDK は常に応答します。 `202 Accepted`、不明なドメインや不正なペイロードについても応答するため、どのプロジェクトが分析データを収集しているかを SDK に漏らしません。

スニペットが宣言するサイトドメインによってプロジェクトが解決されます。 `d` 権威性を有し、存在しない場合はサーバーが `u` ( ページ URL のホスト) およびその後リクエスト `Origin`/`Referer`.

### リクエストボディ

| フィールド | タイプ   | 説明                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 文字列 | プロジェクトを特定するドメイン名 (例. `example.com`)。必須。 |
| `n`   | 文字列 | イベント名。デフォルト値 `pageview`。                          |
| `u`   | 文字列 | ページ URL (`location.href`).                                  |
| `r`   | string | リファラー (`document.referrer`).                              |
| `l`   | string | ブラウザの言語 (`navigator.languages.join(",")`)         |
| `tz`  | string | IANA タイムゾーン (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | CSS ピクセルの画面幅。                                  |
| `sid` | string | タブごとのセッション ID (sessionStorage、クローズ時にクリアされる)。       |

CORS は開itespace (`Access-Control-Allow-Origin: *`) はエンドポイントが認証情報を許可しないため。

## サーバー由来のフィールド

これらは取り込み時に計算されサーバー側に保存されます。生の IP アドレスと User-Agent は保存されません。

| フィールド             | ソース        | 説明                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + プロジェクトの 1 日ごとのハッシュ。日を跨いでリンクできません。 |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 コード。GeoIP が設定されていない場合は空。        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`または, `unknown`.                 |
| `browser`         | ユーザーエージェント    | `chrome`, `safari`， `firefox`以前に検証に失敗した再構成ドキュメント：マークダウンのテキストリテラル回復は、一致する長さの JSON 文字列配列を返す必要があります `edge`", `opera`, または `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 或者 `unknown`.        |
| `hostname`        | ページ URL      | 小文字化されたホスト。                                                    |
| `pathname`        | ページ URL      | パスコンポーネント。                                                     |
| `referrer_source` | リファラ      | リファラ送信元、先頭 `www.`/`m.` 除去され。                        |
| `browser_language`| 言語     | 最も優先される正規化されたロケール (e.g. `pt-BR`).                    |
| `served_locale`   | 計算済み        | 優先言語に一致する最初の対応ターゲット、それ以外の場合は空。   |
| `has_locale_gap`  | 計算        | `1` プロジェクトが対応していない言語を訪問者が好む場合 |

## プライバシー モデル

- **クライアントサイドの保存なし。** SDK はクッキーを設定せず、タブごとのセッション ID のみにより、 `sessionStorage`, ブラウザが閉じられるとクリアされます。
- **指紋化なし。** Canvas、WebGL、フォント、および音声指紋は収集されません。それらなしで一意な ID を生成するため、毎日更新されるサーバーハッシュを使用します。
- **生識別子は永続化されません。** IP アドレスと User-Agent は一度読み取られ、サーバーシークレットと日替わりソルトでハッシュ化され、その後破棄されます。
- **プロジェクトごとのスコープ。** 同じブラウザが二つのプロジェクトで使用されても、関連しない訪問者 ID が生成されるため、Glossia の顧客間で訪問者を追跡することはできません。