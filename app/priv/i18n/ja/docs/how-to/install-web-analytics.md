%{
  title: "ウェブ解析のインストール",
  summary: "Glossia Web SDK を HTML で 1 行または npm を通じてサイトに追加し、ローカライゼーションシグナルの収集を開始できます。",
  category: "ガイド",
  order: 1
}
---
このガイドは、プロジェクトの分析設定にサイトドメインが設定済みである Glossia プロジェクトを前提としています。コレクションはこのドメインによって識別されるため、コピーするキーやシークレットはありません。

## オプション A: スクリプトタグ

このスニペットをすべてのページに追加し、できれば、 `<head>`再構成ドキュメントは以前検証に失敗しました：Markdown テキスト文字列の復元には、同じ長さの JSON 文字列配列を返す必要があります。

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK は自動的に初期化され、読み込み時にページビューを送信し、シングルページ アプリのクライアント側ナビゲーションにおいて以降のページビューを記録します。 `data-domain` デフォルトは `window.location.hostname` 省略すると、単一ドメインのサイトでは構いません。カスタムコレクションエンドポイントを使用するには、追加 `data-endpoint="https://collect.your-host.com"`.

## オプション B: npm

パッケージをインストール:

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度初期化:

```ts
import glossia from "@glossia/web";

glossia.init();
```

その `domain` は推定されます `window.location.hostname` そのため、SDK は登録されたプロジェクトに対して記録されます。渡す `{ domain: "example.com" }` をオーバーライドする例、すなわちステージングオリジンから本番と同じプロジェクトにイベントを送信する。

カスタムイベントを記録する場合、例えばサインアップ:

```ts
glossia.track("signup");
```

## 動作を確認

1. ブラウザでサイトを開く
2. ネットワークタブを開き、 `POST` リクエスト `/api/analytics/events` が返されます `202 Accepted`。
3. 1 分以内に、ページビューがプロジェクトの分析ダッシュボードに表示されます。

## 収集されるデータ

ブラウザはページ URL、リファラを `navigator.languages`タイムゾーン、画面幅、さらにタブごとのセッション ID を記録します。サーバーは GeoIP から国を追加し、プロジェクトのターゲット言語に対する ローカライゼーションギャップを計算します。クッキーは設定されず、何ものもフィンガープリント化されません。