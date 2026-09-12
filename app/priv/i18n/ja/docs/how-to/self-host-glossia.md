%{
  title: "Glossia をセルフホスト",
  summary:
    "同梱された Helm チャートを使用して、ご自身の Kubernetes クラスターに Glossia をインストールすることで、チームは独自のインフラ上で言語 OS を実行できます。",
  category: "チュートリアル",
  order: 2
}
---
Glossia はオープンソースであり、 [O'Saasy ライセンス](https://github.com/glossia/glossia/blob/main/LICENSE.md)。ご自身でホストし、修正して社内利用のために運用できます。ただし、ライセンスが許可しない唯一のことは、glossia.ai のホストサービスと競合するホスト型または SaaS プロダクトとしてこれを第三者に提供することですが、

このガイドは、空の Kubernetes クラスターから稼働する Glossia インスタンスへご案内します。

## 開始する前に

必要なもの：

- Helm チャートをインストールできる Kubernetes クラスタ (v1.28 以降)
- `helm` および `kubectl` ローカルに
- クラスターの ingress に指定するドメインです
- 認証用の OpenID Connect プロバイダーまたは SMTP リレーです（Glossia は両方に対応しています）

Helm チャートは Postgres を（ [CloudNativePG](https://cloudnative-pg.io/)）および ClickHouse を（ [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)）そのため、外部データベースは不要です。自分自身で用意する場合は、両方とも設定で無効にできます `values.yaml`.

## オペレーターをインストール

有効化予定のコンポーネントに一致するオペレーターをインストールしてください。最低限:

- [CloudNativePG オペレーター](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリデータベース向け
- [ClickHouse Kubernetes オペレーター](https://github.com/ClickHouse/clickhouse-operator) 分析データベース向け
- インゲスコントローラー（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 自動 TLS が必要ない場合は

## Glossia チャートをインストールする

レポジトリをクローンし、次にチャートをインストールします：

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリシークレットを提供する

Kubernetes シークレットを名前にして作成します `glossia-app-env` 少なくともこれらのキー:

| キー | 目的 |
| --- | |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン 保護 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth 向けの `/ops` ダッシュボード |
| `RELEASE_COOKIE` | すべてのポッドで共有される Erlang ディストリビューション クッキー |
| `GLOSSIA_SMTP_*` | 外部メールの設定 |

これらを直接プロビジョニングし、使用できます [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), またはチャートをシークレットマネージャーに接続するのを介して [External Secrets Operator](https://external-secrets.io/) Registry グレード。またはチャートの README に記載されている統合.

## チャートに含まれるもの

- Glossia ウェブアプリケーション
- アプリケーションデータ用の Postgres（オプション、デフォルトでオン）
- 分析用 ClickHouse（オプション、デフォルトでオン）
- 翻訳ジョブのバックグラウンドワーカーは、Kubernetes Jobs として実行されるため、ローリングデプロイ後も存続します。

## 次に進む

- その [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) すべての値に対する完全なリファレンスに加え、バックアップ、オブジェクトストレージ、および可観測性に関する注釈を含んでいます。
- [モデルプロバイダーを設定する](/docs/how-to/configure-a-model-provider) インスタンスが稼働した後に、翻訳が LLM を呼び出せるように設定します。
- 問題の報告や改善提案は以下の場所で [GitHub リポジトリ](https://github.com/glossia/glossia).