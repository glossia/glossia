%{
  title: "Web 解析をインストール",
  summary: "Glossia Web SDK を 1 行の HTML または npm でサイトに追加し、ローカライゼーションシグナルの収集を開始します。",
  category: "使い方",
  order: 1
}
---
このガイドは、プロジェクトのアナリティクス設定にサイトドメインが設定された Glossia プロジェクトをお持ちであることを前提としています。収集は当該ドメインによって識別されるため、コピーする必要があるキーやシークレットはありません。

## オプション A: スクリプトタグ

このスニペットを各ページに追加してください。理想の位置は、 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリのクライアント側のナビゲーションで以降のページビューを記録します。 `data-domain` デフォルトは、 `window.location.hostname` 省略された場合は、単一ドメインサイトではそのまま使用できます。カスタムコレクションエンドポイントを使用するには、追加して `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストールします:

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度初期化します:

```ts
import glossia from "@glossia/web";

glossia.init();
```

それ `domain` ～から推測されます。 `window.location.hostname` したがって、SDK は登録されたプロジェクトに対して記録されます。渡す `{ domain: "example.com" }` オーバーライドするため、例えば、ステージオリジンから送られるイベントを本番と同一のプロジェクトへ送る場合、

カスタムイベントを記録するには、例えばサインアップ:

```ts
glossia.track("signup");
```

## 動作を確認してください。

1. ブラウザでサイトを開いてください。
2. ネットワークタブを開き、確認する `POST` リクエストへの `/api/analytics/events` 結果が返される `202 Accepted`。
3. 1 分以内に、ページビューがプロジェクトの分析ダッシュボードに表示されます。

## 収集される情報

ブラウザはページ URL、リファラー、 `navigator.languages`, タイムゾーン、および画面幅、さらにタブごとのセッション ID を送信します。サーバーは国（GeoIP）を追加し、プロジェクトのターゲット言語に対するローカライズギャップを計算します。クッキーは設定されず、指紋化も行われません。