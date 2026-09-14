%{
  title: "アナリティクス SDK",
  summary: "収集されたフィールド、イベントエンドポイント、および Glossia ウェブ分析の背後にあるプライバシーモデル",
  category: "参照",
  order: 1
}
---
## イベント エンドポイント

`POST /api/analytics/events`

JSON イベントを受け取るため、 `@glossia/web` SDK。常にレスポンスします。 `202 Accepted`, 不明なドメインや不正なペイロードの場合も同様で、SDK はどのプロジェクトが分析を収集しているか漏らしたことはありません。

プロジェクトはスニペットが宣言するサイト ドメインによって解決されます。 `d` それが権威的であり、欠落している場合、サーバーはホストの `u` （ページの URL）およびその後リクエスト `Origin`/`Referer`.

### リクエスト本文

| フィールド | タイプ   | 説明                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | プロジェクトを識別するサイト ドメイン (e.g. `example.com`). 必須 |
| `n`   | string | イベント名。デフォルトは `pageview`。                          |
| `u`   | string | ページ URL (`location.href`）。                                  |
| `r`   | string | リファラ (`document.referrer`）。                              |
| `l`   | string | ブラウザ言語 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA タイムゾーン (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 画面幅（CSS ピクセル）                                  |
| `sid` | 文字列 | タブ固有のセッション ID (sessionStorage、閉じるとクリア)。       |

CORS は有効 (`Access-Control-Allow-Origin: *`) 無いため、このエンドポイントが認証情報を許可しません。

## サーバー由来のフィールド

インジェスト時に計算され、サーバー側で保存されます。生の IP アドレスと User-Agent は決して保存されません。

| フィールド          | ソース         | 説明                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + プロジェクトの 1 日ごとのハッシュ。1 日を超えてリンク不可。  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 コード。GeoIP が設定されていない場合は空です。        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, または `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`再構成されたドキュメントは以前検証に失敗しました: Markdown テキストリテラルの復元は一致する長さの JSON 文字列配列を返す必要があります。 `opera`、または `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`、 `linux`, または `unknown`.        |
| `hostname`        | ページ URL      | 小文字のホスト.                                                    |
| `pathname`        | ページ URL      | パス コンポーネント.                                                     |
| `referrer_source` | リファラ            | リファラ ホスト、先頭 `www.`/`m.` 削除されます。                |
| `browser_language`| 言語          | 最も好まれる正規化されたロケール（例：" `pt-BR`)。                    |
| `served_locale`   | 計算            | 優先言語に一致する最初のターゲット、そうでなければ空。   |
| `has_locale_gap`  | 推計        | `1` プロジェクトが対応していない言語を訪問者が選択した場合。 |

## プライバシーモデル

- **クライアントサイドストレージなし。** SDK はクッキーを設定せず、タブごとのセッション ID だけを保持し `sessionStorage`、ブラウザが閉じられた時点でクリアされます。
- **フィンガープリンティングなし。** キャンバス、WebGL、フォント、および音声の指紋は収集されません。日替わりのサーバーハッシュにより、それらなしに一意の識別子が生成されます。
- **生の識別子は永続化されません。** IP アドレスとユーザーエージェントは一度だけ読み取られ、サーバー秘密鍵と日次ソルトでハッシュ化され、その後破棄されます。
- **プロジェクトごとのスコーピング。** 2 つのプロジェクトで同じブラウザを使用しても、無関係なビジター ID が生成されるため、Glossia 顧客間での追跡はできません。