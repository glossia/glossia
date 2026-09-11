%{
  title: "ウェブ分析をインストールする",
  summary: "1 行の HTML または npm でサイトに Glossia ウェブ SDK を追加し、ローカライゼーションシグナルの収集を開始します。",
  category: "チュートリアル",
  order: 1
}
---
本ガイドは、プロジェクトの分析設定にサイトドメインが設定済みの Glossia プロジェクトを前提としています。コレクションはドメインで識別されるため、コピーするキーやシークレットはありません。

## オプション A: スクリプトタグ

すべてのページにこのスニペットを追加し、理想としては `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリケーションのクライアント側ナビゲーションで以降のページビューを記録します。 `data-domain` デフォルト設定は `window.location.hostname` 省略された場合は、単一ドメインサイトであれば省略できます。カスタムコレクションエンドポイントを使用するには、追加する `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストール:

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度だけ初期化:

```ts
import glossia from "@glossia/web";

glossia.init();
```

プロジェクト名 `domain` から推定されます `window.location.hostname` そのため、SDK はサイトの登録プロジェクトに対して記録します。指定して `{ domain: "example.com" }` 上書きして、例えばステージングオリジンから本番と同じプロジェクトにイベントを送信する場合。

カスタムイベントを記録するには、例えばサインアップを：

```ts
glossia.track("signup");
```

## 動作が正常かどうか確認してください。

1. ブラウザでサイトを開いてください。
2. ネットワークタブを開き、確認し `POST` リクエストを `/api/analytics/events` 返されます `202 Accepted`。
3. 1 分以内に、ページビューがプロジェクトの分析ダッシュボードに表示されます。

## 収集される情報

ブラウザはページ URL、リファラを、 `navigator.languages`タイムゾーン、画面幅、さらに各タブのセッション ID を含む。サーバーは国（GeoIP から）を追加し、プロジェクトの目標言語とのローカライズギャップを計算します。 クッキーは設定されず、何の情報も指紋化されません。