%{
  title: "ウェブアナリティクスをインストールする",
  summary: "サイトに Glossia Web SDK を HTML 1 行または npm で追加し、ローカリゼーションシグナルを収集を開始できます。",
  category: "チュートリアル",
  order: 1
}
---
このガイドでは、Glossia プロジェクトがあり、プロジェクトのアナリティクス設定にサイトのドメインが設定済みであると前提します。収集はこのドメインによって特定されるため、コピーする必要のあるキーまたはシークレットはありません。

## Option A: スクリプトタグ

各ページにこのスニペットを追加します。理想の位置は以下の `<head>`：

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリケーションでのクライアントサイド ナビゲーション時に後続のページビューを記録します。 `data-domain` 省略時はデフォルトとなります `window.location.hostname` 単一ドメインサイトではそのまま使用できます。カスタムの収集エンドポイントを使用するには、追加 `data-endpoint="https://collect.your-host.com"`。

## Option B: npm

パッケージをインストールします:

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度初期化します:

```ts
import glossia from "@glossia/web";

glossia.init();
```

その `domain` から推測されます `window.location.hostname` ため、SDK は登録されたプロジェクトに対して記録を行います。指定 `{ domain: "example.com" }` 上書きするため、例えば、ステージングオリジンからのイベントをプロダクションと同じプロジェクトに送信する。

カスタムイベント（例：ログイン）を記録するには:

```ts
glossia.track("signup");
```

## 動作を確認します

1. ブラウザでサイトを閲覧します。
2. ネットワークタブを開き、確認 `POST` へのリクエスト `/api/analytics/events` されます `202 Accepted`。
3. 1 分以内に、プロジェクトのアナリティクスダッシュボードにページビューが表示されます。

## 収集される情報

ブラウザはページ URL、リファラーを `navigator.languages`タイムゾーン、画面幅、タブごとのセッション ID を。サーバーは国（GeoIP）とプロジェクトのターゲット言語に対するローカライズギャップを計算します。クッキーは設定せず、何のフィンガープリント化も行われません。