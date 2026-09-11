%{
  title: "Web アナリティクスのインストール",
  summary: "HTML 1 行のコード、または npm 経由で Glossia Web SDK を 사이트에追加し、ローカライゼーションシグナルの収集を開始できます。",
  category: "チュートリアル",
  order: 1
}
---
このガイドでは、プロジェクトの設定にある「分析設定」にサイト ドメインを構成した Glossia プロジェクトをお持ちであると前提としています。データ収集はこのドメインによって識別されるため、コピーする必要があるキーまたはシークレットはありません。

## オプション A: スクリプト タグ

すべてのページにこのスニペットを含め、理想の場合、以下の `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページ アプリ クライアント サイド ナビゲーション時の以降のページビューも記録します。 `data-domain` defaults to `window.location.hostname` 省略した場合は、単一ドメインのサイトでも問題なく動作します。カスタム クレクション エンドポイントを使用するには、追加 `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストール:

```bash
npm install @glossia/web
```

アプリケーションのエントリポイントで一度初期化:

```ts
import glossia from "@glossia/web";

glossia.init();
```

これ `domain` 推測されます `window.location.hostname` そのため、SDK はサイトの登録済みプロジェクトに対して記録を行います。傳遞 `{ domain: "example.com" }` 上書きする場合、例えばステージングオリジンから本番と同じプロジェクトへイベントを送信する場合。

カスタムイベントを記録する（例えばサインアップ）:

```ts
glossia.track("signup");
```

## 動作を確認する

1. ブラウザでサイトをオープンしてください。
2. ネットワークタブを開き、 `POST` リクエスト `/api/analytics/events` が返る `202 Accepted`.
3. 1 分以内にプロジェクトの分析ダッシュボードにページビューが表示されます。

## 収集されている内容

ブラウザはページ URL とリファラ、 `navigator.languages`, タイムゾーンと画面幅、さらにタブごとのセッション ID を送信します。サーバーは国（GeoIP の情報から）を追加し、プロジェクトのターゲット言語に対するローカライズギャップを計算します。クッキーは設定されず、何も指紋化されません。