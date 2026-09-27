%{
  title: "Web アナリティクスをインストールする",
  summary: "HTML の 1 行または npm を通じてサイトに Glossia Web SDK を追加し、ローカライゼーションのシグナル収集を開始します。",
  category: "チュートリアル",
  section: "分析",
  order: 1
}
---
このガイドは、プロジェクトの解析設定にサイトのドメインが構成されている Glossia プロジェクトを前提としています。収集は当該ドメインで識別されるため、コピーするキーまたはシークレットはありません。

## オプション A: script タグ

このスニペットを各ページに追加してください。理想的には `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動初期化され、ロード時にページビューを送信し、シングルページアプリケーションのクライアントサイドナビゲーション時の後続のページビューを記録します。 `data-domain` デフォルトは `window.location.hostname` 省略された場合、単一ドメインのサイトでも問題なく動作します。カスタム収集エンドポイントを使用する場合は、追加 `data-endpoint="https://collect.your-host.com"`.

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

それ、 `domain` 推測されます `window.location.hostname` そのため、SDK はあなたのサイトに登録されているプロジェクトに対して記録されます。渡す、 `{ domain: "example.com" }` 上書きし、例えばステージングオリジンのイベントを本番と同じプロジェクトに送信する。

カスタムイベントを記録するには、例えばサインアップを:

```ts
glossia.track("signup");
```

## 動作を確認します

1. ブラウザでサイトを開いてください。
2. ネットワークタブを開いて、 `POST` リクエストの `/api/analytics/events` 結果が返ります `202 Accepted`。
3. 1 分以内に、ページビューがプロジェクトの分析ダッシュボードに表示されます。

## 何が収集されるか

ブラウザはページ URL、リファラー、 `navigator.languages`, タイムゾーン、および画面の幅、さらにタブごとのセッション ID も含みます。サーバーは国情報（GeoIP から）を追加し、プロジェクトのターゲット言語に対するローカライズギャップを計算します。クッキーは設定されず、指紋化も行われません。