%{
  title: "Glossia をセルフホストする",
  summary:
    "同梱の Helm チャートを使用して独自の Kubernetes クラスタに Glossia をインストールし、チームが独自のインフラストラクチャ上で言語 OS を運用できるようにします。",
  category: "チュートリアル",
  order: 2
}
---
Glossia は、以下のライセンスの下でオープンソースです。 [O'Saasy ライセンス](https://github.com/glossia/glossia/blob/main/LICENSE.md)。組織の内部使用向けに自己展開、変更、および実行が可能です。ただし、本ライセンスは、glossia.ai のホストサービスと競合するホストされたサービスまたは SaaS プロダクトとしてこれを第三者に提供することを認めていません。

このガイドは、空の Kubernetes クラスターから稼働する Glossia インスタンスへのセットアップを支援します。

## 开始前に

必要なもの:

- Helm チャートをインストールできる Kubernetes クラスター (v1.28 以降)
- `helm` および `kubectl` ローカル
- クラスターの Ingress に設定できるドメイン
- 認証用の OpenID Connect プロバイダーまたは SMTP リレー（Glossia は両方をサポートしています）

Helm チャートは Postgres をバンドルしています（ [CloudNativePG](https://cloudnative-pg.io/)）と ClickHouse（ [公式オペレーター](https://github.com/ClickHouse/clickhouse-operator)）外部データベースは不要です。自分で用意したい場合は、設定内で両方とも無効にできます `values.yaml`.

## オペレーターのインストール

有効化予定のコンポーネントに一致するオペレーターをインストールしてください。最低限：

- [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) アプリ用データベースのため
- [ClickHouse Kubernetes operator](https://github.com/ClickHouse/clickhouse-operator) アナリティクス用データベースのため
- Ingress コントローラ（例えば [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS を自動的に設定したい場合

## Glossia チャートをインストールしてください

リポジトリをクローンし、次にチャートをインストールしてください:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## アプリケーションシークレットを入力してください

名前で Kubernetes Secret を作成してください `glossia-app-env` 少なくともこれらのキーを：

| キー | 用途 |
| --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix セッション署名キー |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer トークン 保護 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth の `/ops` ダッシュボード |
| `RELEASE_COOKIE` | 各ポッドで共有される Erlang 分散クッキー |
| `GLOSSIA_SMTP_*` | 送信メール設定 |

これらを直接設定でき、使用 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), またはチャートをシークレットマネージャーに接続して [External Secrets Operator](https://external-secrets.io/) チャートの README に説明されている統合。

## このチャートに含まれるもの

- Glossia ウェブアプリケーション
- アプリケーションデータ用の Postgres（オプション、デフォルトで有効）
- 分析用の ClickHouse（オプション、デフォルトで有効）
- 翻訳ジョブのためのバックグラウンドワーカーで、rolling deploys を凌駕して動作し続けるために Kubernetes Jobs として実行されます。

## 次に進む

- この [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) すべての値に対する完全な参照情報に加え、バックアップ、オブジェクトストレージ、可観測性に関するメモも提供しています。
- [モデルプロバイダーを設定](/docs/how-to/configure-a-model-provider) インスタンスが稼働すると、翻訳タスクで LLM を呼び出すことができます。
- 不具合の報告や改善提案は以下の [GitHub リポジトリ](https://github.com/glossia/glossia).