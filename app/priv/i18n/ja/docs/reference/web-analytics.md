%{
  title: "分析 SDK",
  summary: "収集フィールド、イベントエンドポイント、そして Glossia ウェブ分析の背景にあるプライバシーモデル。",
  category: "参照",
  order: 1
}
---
## イベント エンドポイント

`POST /api/analytics/events`

JSON イベントを受け取る、 `@glossia/web` SDK。常に応答します `202 Accepted`、不明なドメインや破損ペイロードの場合も含め、どのプロジェクトが分析データを収集しているかを漏洩しません。

スニペットが宣言するサイトドメインによってプロジェクトが解決されます。 `d` 優先されます; 存在しない場合、サーバーはホストの `u` （ページ URL）とその後リクエスト、 `Origin`/`Referer`.

### リクエストボディ

| 項目 | タイプ   | 説明                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 文字列 | プロジェクトを識別するサイトドメイン（例： `example.com`)。必須。|
| `n`   | string | イベント名．デフォルト値は `pageview`.                          |
| `u`   | string | ページ URL (`location.href`).                                  |
| `r`   | string | リファラー (`document.referrer`).                              |
| `l`   | string | ブラウザ言語 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA タイムゾーン (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 画面の CSS ピクセル幅                                  |
| `sid` | string | タブごとのセッション ID (sessionStorage、クローズ時に破棄).       |

CORS は開いています (`Access-Control-Allow-Origin: *`) エンドポイントが認証情報を許可していないためです。

## サーバー派生フィールド

取り込み時に計算され、サーバー側で保存されます。生の IP アドレスと User-Agent は保存されません。

| フィールド             | ソース        | 説明                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + ユーザーエージェント + プロジェクトの毎日ローテーション hashed. 日＝横連携不可.
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 コード。GeoIP が設定されていない場合は空になります。|
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, または `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, または `unknown`.       |
| `os`              | ユーザーエージェント    | `windows`, `macos`, `ios`, `android`, `linux`,、または `unknown`。        |
| `hostname`        | ページ URL      | 小文字のホスト。                                                    |
| `pathname`        | ページ URL      | パス要素。                                                     |
| `referrer_source` | リファラー      | 送信元ホスト、先頭 `www.`/`m.` 削除された。                        |
| `browser_language`| 言語 | 最も優先された正規化されたロケール（例 `pt-BR`).                    |
| `served_locale`   | 計算         | 優先言語に一致した最初の対応ターゲット、それ以外の場合は空。   |
| `has_locale_gap`  | 算出済み      | `1` 訪問者がプロジェクトがサポートしていない言語を好む場合 |

## プライバシーモデル

- **クライアントサイドでの保存は行われません。** SDK はクッキーを設定せず、タブごとにセッション ID を `sessionStorage`, ブラウザが閉じるとクリアされます。
- **フィンガープリンティングは行いません。** キャンバス、WebGL、フォント、およびオーディオのフィンガープリントは収集されません。日替わりのサーバーハッシュはそれらの収集を要さず一意識別を提供します。
- **生識別子は永続化されません。** IP アドレスと User-Agent は一度だけ読み取り、サーバーシークレットと日替わりのソルトでハッシュ化され、その後破棄されます。
- **プロジェクトごとのスコープ。** 2 つのプロジェクトで同じブラウザを使用しても、無関係な訪問者 ID が生成されるため、Glossia の顧客間で訪問者を追跡することはできません。