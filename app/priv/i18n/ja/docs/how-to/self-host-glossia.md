%{
  title: "Glossia をセルフホストする",
  summary:
    "バンドルされた Helm チャートを使用して独自の Kubernetes クラスターに Glossia をインストールし、チームが独自のインフラストラクチャ上で言語 OS を稼働させることができます。",
  category: "チュートリアル",
  order: 2
}
---
Glossia は以下でオープンソースです [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). これらを独自にホストし、修正し、組織内の内部利用で使用できます。ライセンスは第三者に glosisa.ai のホストサービスと競合するホスト型または SaaS プロダクトとして提供することを許可していません。

このガイドは、空の Kubernetes クラスターから動作する Glossia インスタンスへ案内します。

## 開始前に

必要なのは:

- Helm チャートをインストールできる Kubernetes クラスター (v1.28 以降)
- `helm` および `kubectl` ローカルで
- クラスタ Ingress の先につなげられるドーマイン
- 認証用 OpenID Connect プロバイダーおよび SMTP リレー（Glossia は両方をサポートしています）

Helm チャートは PostgreSQL をバンドルします（介して [CloudNativePG](https://cloudnative-pg.io/)）および ClickHouse（介して [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)）外部データベースは不要です。自前のものを導入したい場合は、どちらも無効にできる `values.yaml`.

## オペレーターのインストール

有効化するコンポーネントに対応するオペレーターをインストールしてください。最低限:

- [CloudNativePG オペレーター](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリケーションデータベース用の
- [ClickHouse Kubernetes オペレーター](https://github.com/ClickHouse/clickhouse-operator) 分析データベース用の
- Ingress コントローラー (例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS を使用したい場合

## Glossia チャートをインストールします

リポジトリをクローンし、チャートをインストールします:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリのシークレットを提供してください

名前付きの Kubernetes Secret を作成します `glossia-app-env` 少なくとも以下のキーを含む：

| キー | 目的 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン保護 | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth の `/ops` ダッシュボード |
| `RELEASE_COOKIE` | Erlang のディストリビューション クッキー は各ポッドで共有されます |
| `GLOSSIA_SMTP_*` | アウトバウンド メール設定 |

これら を直接プロビジョニングできます、使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)、またはチャートをシークレットマネージャーに接続するための [External Secrets Operator](https://external-secrets.io/) チャート README に記載されている統合

## チャートに含まれるもの

- Glossia ウェブ アプリケーション
- アプリケーションデータ用の Postgres (オプション、デフォルトは有効)
- 分析用の ClickHouse (オプション、デフォルトは有効)
- 翻訳ジョブ向けのバックグラウンドワーカーで、Kubernetes Jobs として実行されるため、ロールアウト展開後も稼働し続けます。

## 次のどこへ

- この [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 各値に対する完全な参照を含み、バックアップ、オブジェクトストレージ、および可観測性に関する注記も備えています。
- [モデルプロバイダーを設定する](/docs/how-to/configure-a-model-provider) インスタンスが稼働した際、翻訳タスクが LLM を呼び出すことができるようにするため。
- 問題の報告や改善の提案はこちらで [GitHub リポジトリ](https://github.com/glossia/glossia).