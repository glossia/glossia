%{
  title: "Web アナリティクスをインストール",
  summary: "HTML 1 行または npm で Glossia Web SDK をサイトに追加し、ローカライゼーションシグナルの収集を開始してください。",
  category: "ハウツー",
  order: 1
}
---
このガイドはプロジェクトの分析設定にサイトドメインが構成された Glossia プロジェクトをお持ちであることを前提とします。収集は当該ドメインによって識別されるため、キーやシークレットをコピーする必要はありません。

## オプション A: スクリプトタグ

このスニペットを各ページに追加し、理想としては `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリにおけるクライアントサイドでのナビゲーション時に次のページビューを記録します。 `data-domain` デフォルトは `window.location.hostname` 省略された場合でも、単一ドメインのサイトにそのまま適用可能です。カスタム収集エンドポイントを使用するには、 `data-endpoint="https://collect.your-host.com"`。

## オプション B: npm

パッケージをインストールします:

```bash
npm install @glossia/web
```

アプリケーションのエントリポイントで一度初期化します:

```ts
import glossia from "@glossia/web";

glossia.init();
```

それ `domain` 〜 から推測されます `window.location.hostname` そのため、SDK はサイトの登録プロジェクトに対して記録されます。指定する `{ domain: "example.com" }` 上書きする場合、例えば、ステージングオリジンからのイベントを本番プロジェクトと同じプロジェクトへ送信する場合

カスタムイベント（例：サインアップ）を記録します:

```ts
glossia.track("signup");
```

## 動作を確認してください

1. ブラウザでサイトを閲覧してください
2. ネットワークタブを開き `POST` リクエスト `/api/analytics/events` が返信される `202 Accepted`。
3. 1 分以内で、プロジェクトの分析ダッシュボードにページビューが表示されます

## 収集される内容

ブラウザはページ URL、リファラーを送信する、 `navigator.languages`タイムゾーン、画面幅、およびタブごとのセッション ID。サーバーは GeoIP から国を取得し、プロジェクトのターゲット言語とのローカリゼーションギャップを計算します。クッキーは設定されず、何らフィンガープリンティングも行われません。