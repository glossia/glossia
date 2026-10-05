%{
  title: "ウェブ解析をインストールする",
  summary: "1 行の HTML または npm を通じて Glossia ウェブ SDK をサイトに追加し、ローカライゼーションシグナルの収集を開始しましょう。",
  category: "チュートリアル",
  section: "analytics",
  order: 1
}
---
このガイドでは、プロジェクトの分析設定にサイトドメインが設定済みの Glossia プロジェクトがあると前提としています。収集は当該ドメインで識別されるため、コピーするキーやシークレットはありません。

## オプション A: スクリプトタグ

各ページにこのスニペットを配置し、理想として `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK は自動で初期化され、ロード時にページビューを送信し、シングルページアプリのクライアント側ナビゲーションで以降のページビューも記録します。 `data-domain` 省略時のデフォルトは `window.location.hostname` 省略した場合、単一ドメインサイトではこれを除外できます。カスタム収集エンドポイントを使用するには、追加する `data-endpoint="https://collect.your-host.com"`.

サイトのコンテンツ セキュリティ ポリシーを使用している場合は、許可 `https://glossia.ai` 両方 `script-src` (または `script-src-elem` 存在する場合）と `connect-src`. スクリプトは から読み込まれます `/assets/glossia-web.js` 、イベントを に送信します `/v1/collect` 同じオリジン。

## オプション B: npm

パッケージをインストール:

```bash
npm install @glossia/web
```

アプリケーションのエントリーポイントで一度初期化:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

独自のバンドルでパッケージを使用する際は、コレクションエンドポイントを明示的に設定してください。ホストされたスクリプトアドレスから推測できないためです。

`domain` から推測されます `window.location.hostname` そのため、SDK はあなたのサイトに登録されたプロジェクトに対して記録します。渡してください `{ domain: "example.com" }` オーバーライドするため、例えば、ステージングオリジンからプロダクションと同じプロジェクトへイベントを送信する場合など。

カスタムイベントを記録する（ 例えば、サインアップなど）:

```ts
glossia.track("signup");
```

## ドメインを確認

プロジェクトの **分析設定**, サイトのドメインを保存してください。 **ドメイン所有権の確認** カードにはプロジェクトの正確なレコード名と値が表示されます。ドメインプロバイダーでテキストレコードを追加してください：

| フィールド | 値 |
| --- | --- |
| タイプ | `TXT` ([text record](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Value | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use the domain and token shown in your settings. Some providers add the domain automatically; in that case enter only `_glossia-verify` 名前の通り。レコード公開後にクリック **ドメインを検証**. 反映には時間がかかる場合があります。すぐに見つからない場合は、再試行してください。

ドメインのレコードを編集できない場合は、展開 **代替：ホームページのメタタグによる検証**. 生成されたタグをコピーし、 `<head>` ホームページのメタタグへ追加し、公開してください:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

いずれの方法でも管理権限を証明します。Glossia は設定済みドメインのレコードまたはホームページを確認するため、トークンを別のウェブサイトにコピーしても所有権は保証されません。トークンは公開された証明であり、パスワードではありません。

ドメインが検証されると、Glossia はトラッキングスニペットからイベントを記録します。そのスニペット自体は所有権を検証しません。設定されたドメインを変更する場合は、再度検証が必要です。

## 動作を確認

1. ブラウザでサイトを開きます。
2. ネットワーク タブを開き、確認対象の `POST` リクエストへの `https://glossia.ai/v1/collect` が返ります `202 Accepted`。
3. 収集および処理後、ページビューは以下に表示されます **分析** プロジェクトのダッシュボード内です。Overview ページでの翻訳実行は、ウェブサイトトラフィックとは別です。

A `202 Accepted` レスポンスにより、リクエストがコレクターに到達したことが確認されます。不明または検証されていないドメインも受け付けられますが、イベントは記録されないため、プロジェクトのアナリティクス設定で設定されたドメインが検証済みであることを確認してください。

## 収集内容

ブラウザはページ URL、リファラー、 `navigator.languages`、タイムゾーンおよび画面幅、それに加えてタブごとのセッション ID サーバーは GeoIP から国を追加し、プロジェクトのターゲット言語に対するローカライズギャップを計算します。クッキーは設定されず、指紋登録もされません。