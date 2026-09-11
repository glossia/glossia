%{
  title: "Web 分析のインストール",
  summary: "1 行の HTML または npm を通じて Glossia Web SDK をサイトに追加し、ローカライズシグナルの収集を開始しましょう。",
  category: "使い方",
  order: 1
}
---
このガイドでは、プロジェクトの分析設定にサイトドメインが設定済みの Glossia プロジェクトをお持ちであることを前提としています。収集は当該ドメインによって識別されるため、コピーするキーまたはシークレットは不要です。

## オプション A: スクリプトタグ

このスニペットを各ページに追加してください。理想的には `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリのクライアントサイドナビゲーション中以降のページビューも記録します。 `data-domain` 省略するとデフォルト値は `window.location.hostname` 単一ドメインサイトでも利用可能です。カスタム収集エンドポイントを使用するには追加する `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストール：

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度初期化：

```ts
import glossia from "@glossia/web";

glossia.init();
```

その `domain` 推測されます `window.location.hostname` そのため、SDK はあなたのサイト向けに登録されたプロジェクトに対して記録します。指定して `{ domain: "example.com" }` オーバーライドするため、例えばステージングオリジンからのイベントを本番と同じプロジェクトに送信する

カスタムイベントを記録するため、例えばサインアップの

```ts
glossia.track("signup");
```

## 動作を確認

1. ブラウザであなたのサイトを開く。
2. ネットワークタブを開き、確認 `POST` リクエストに `/api/analytics/events` 返されます `202 Accepted`。
3. 1 分以内に、ページビューがプロジェクトの分析管理ダッシュボードに表示されます。

## 何が収集されるか

ブラウザはページ URL とリファラーを `navigator.languages`タイムゾーン、画面幅、およびタブごとのセッション ID も送信します。サーバーは GeoIP から国を追加し、プロジェクトのターゲット言語とのローカライズギャップを計算します。クッキーは設定されず、何らのフィンガープリンティングも行われません。