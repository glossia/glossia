%{
  title: "Glossia をセルフホスト",
  summary:
    "同梱された Helm チャートを使って、自社の Kubernetes クラスターに Glossia をインストールし、チームが独自のインフラ上で言語 OS を実行できるようにします。",
  category: "チュートリアル",
  order: 2
}
---
Glossia はオープンソースで、以下の [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md)。組織の内部利用向けに自己ホストし、改変し、実行できます。ライセンスが許可しない唯一のことは、glossia.ai のホストサービスと競合するホストされたおよび SaaS 製品として第三者に提供することです。

このガイドは、空の Kubernetes クラスターから、動作する Glossia インスタンスへ到達します。

## 開始前に

必要なもの:

- Helm チャートをインストールできる Kubernetes クラスター (v1.28 またはそれ以降)
- `helm` と `kubectl` ローカルに
- クラスタ Ingress に設定できるドメイン
- 認証用の OpenID Connect プロバイダーまたは SMTP レイリー (Glossia は両方をサポート)

Helm チャートは Postgres をバンドル (via [CloudNativePG](https://cloudnative-pg.io/)）、また、ClickHouse (via the [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)" ) そのため、外部データベースは不要です。自作を持ち込みたい場合は、どちらも in で無効化できます `values.yaml`.

## オペレーターのインストール

有効化予定のコンポーネントに一致するオペレーターをインストールしてください。最低限：

- [CloudNativePG オペレーター](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリデータベース用
- [ClickHouse Kubernetes オペレーター](https://github.com/ClickHouse/clickhouse-operator) 分析データベース用
- Ingress コントローラー（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS を使用したい場合

## Glossia チャートをインストール

リポジトリをクローンし、チャートをインストール：

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリのシークレットを指定

指定された名称の Kubernetes Secret を作成 `glossia-app-env` 少なくともこれらのキー：

| キー | 目的 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン 保護 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 基本認証用 `/ops` ダッシュボード |
| `RELEASE_COOKIE` | すべての Pod で共有される Erlang のディストリビューションクッキー |
| `GLOSSIA_SMTP_*` | 送信メール設定 |

これらを直接プロビジョニングし、使用するには [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), またはチャートをあなたのシークレットマネージャーを通じて [External Secrets Operator](https://external-secrets.io/) チャート README で説明されている統合。

## チャートに含まれる内容

- Glossia ウェブアプリケーション
- アプリケーションデータ向けの Postgres（オプション、デフォルトでオン）
- 分析向けの ClickHouse（オプション、デフォルトでオン）
- 翻訳ジョブ用のバックグラウンドワーカーで、Kubernetes ジョブとして実行されるため、ロールデプロイを超えて存続します

## 次の更新先

- 以下の [Helm チャート README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) すべての値に対する完全な参照を含み、バックアップ、オブジェクトストレージ、そして観測可能性に関する注記もあります。
- [モデルプロバイダーを設定](/docs/how-to/configure-a-model-provider) インスタンスが稼働している際に、翻訳が LLM を呼び出せるようにするため。
- 問題の報告や改善提案は以下の [GitHub リポジトリ](https://github.com/glossia/glossia).