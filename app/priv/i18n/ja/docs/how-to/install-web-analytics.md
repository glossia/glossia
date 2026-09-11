%{
  title: "Web アナリティクスをインストール",
  summary: "1 ラインの HTML または npm を使用してサイトに Glossia Web SDK を追加し、ローカライゼーションシグナルの収集を開始できます。",
  category: "チュートリアル",
  order: 1
}
---
このガイドは、Glossia プロジェクトの分析設定にサイトのドメインが設定済みであることを前提としています。収集はそれらのドメインによって識別されるため、コピーするキーまたはシークレットはありません。

## オプション A: スクリプトタグ

このスニペットを各ページに追加し、できれば以下の `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK はロード時に自動で初期化され、ページビューを送信し、シングルページアプリのクライアントサイドナビゲーションで後続のページビューを記録します。 `data-domain` デフォルトに `window.location.hostname` 省略された場合は、単一ドメインサイトではそのまま使えます。カスタムコレクションエンドポイントを使用するには、追加 `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストールします：

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで 1 回初期化してください：

```ts
import glossia from "@glossia/web";

glossia.init();
```

その `domain` は...から推測されます `window.location.hostname` したがって、SDK はサイトの登録プロジェクトに対して記録されます。渡す `{ domain: "example.com" }` オーバーライドするため、例えば、ステージングオリジンからのイベントを本番と同じプロジェクトに送信する場合。

独自イベントを記録するため、例えば、サインアップの場合：

```ts
glossia.track("signup");
```

## 動作を確認してください。

1. ブラウザでご自分のサイトを開いてください。
2. ネットワークタブを開き、確認します `POST` リクエスト `/api/analytics/events` が返されます `202 Accepted`。
3. 一分以内には、ページビューがプロジェクトの分析ダッシュボードに表示されます。

## 収集されるデータは何ですか？

ブラウザはページ URL、リフェラー、 `navigator.languages`, タイムゾーン、および画面の幅、さらに各タブのセッション ID を送信します。サーバーは国の情報（GeoIP から）を追加し、プロジェクトの目標言語に対する局所化のギャップを計算します。クッキーは設定されず、指紋化も一切行われません。