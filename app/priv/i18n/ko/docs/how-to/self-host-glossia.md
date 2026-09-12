%{
  title: "Glossia 셀프 호스팅",
  summary:
    "제공된 Helm 차트를 사용하여 자체 Kubernetes 클러스터에 Glossia 를 설치하여, 귀 팀은 자체 인프라에서 언어 OS 를 운영할 수 있습니다.",
  category: "사용 가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 하에 오픈 소스입니다 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 당신은 이를 자체 호스팅하고, 수정하고, 조직의 내부 사용을 위해 실행할 수 있습니다. 라이선스가 허용하지 않는 유일한 사항은, glossia.ai 에서 호스팅된 서비스와 경쟁하는 호스팅이나 SaaS 제품 형태로 제 3 자에게 이를 제공하는 것입니다.

이 가이드는 빈 Kubernetes 클러스터를 실행 중인 Glossia 인스턴스로 가져옵니다.

## 시작하기 전

필요한 사항:

- Helm 차트를 설치할 수 있는 Kubernetes 클러스터 (v1.28 이상)
- `helm` 및 `kubectl` 로컬로
- 클러스터 Ingress 를 가리킬 수 있는 도메인
- 인증용 OpenID Connect 제공자 또는 SMTP 리레이 (Glossia 는 둘 다 지원함)

Helm 차트는 Postgres 를 ( [CloudNativePG](https://cloudnative-pg.io/)) 와 ClickHouse 를 ( [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)) 때문에 외부 데이터베이스가 필요 없습니다. 대신 본인이 사용하려는 베이스를 둘 다 비활성화할 수 있습니다 `values.yaml`.

## 오퍼레이터 설치

활성화하려는 컴포넌트에 맞는 오퍼레이터만 설치하세요. 최소한:

- [CloudNativePG 오퍼레이터](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 앱 데이터베이스용
- [ClickHouse Kubernetes 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- Ingress 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 자동 TLS 를 원하신다면

## Glossia 차트 설치

저장소를 복제하고 차트를 설치하세요:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## 앱 시크릿 입력

이름 지정된 Kubernetes Secret 생성 `glossia-app-env` 다음 키 중 최소 한 개 이상:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증을 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 pod 에 공유되는 Erlang 배포 쿠키 |
| `GLOSSIA_SMTP_*` | 외부 이메일 설정 |

이들을 직접 프로비저닝하고 사용 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 차트를 secret manager 와 연결하기 위해 [External Secrets Operator](https://external-secrets.io/) 차트 README 에 설명된 연동입니다.

## 차트 내부 구성

- Glossia 웹 애플리케이션
- 애플리케이션 데이터를 위한 Postgres (선택 사항, 기본값으로 활성화됨)
- 애널리틱스를 위한 ClickHouse (선택 사항, 기본값으로 활성화됨)
- 번역 작업을 위한 백그라운드 워커입니다. Kubernetes Jobs 로 실행되어 롤링 배포보다 더 오랫동안 지속됩니다.

## 다음으로 이동

- 해당 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 전체 참조를 비롯하여 백업, 객체 저장소, 관측 가능성에 대한 설명을 제공합니다.
- [모델 제공자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역 작업이 LLM 을 호출할 수 있도록 합니다.
- 문제를 제보하거나 개선 사항을 제안할 수 있는 곳에서 [GitHub 저장소](https://github.com/glossia/glossia).