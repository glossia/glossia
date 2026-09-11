%{
  title: "Glossia 자체 호스팅",
  summary: "제공된 Helm 차트를 사용하여 자체 Kubernetes 클러스터에 Glossia 를 설치하여 팀이 자체 인프라에서 언어 OS 를 운영할 수 있습니다.",
  category: "가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 하에 [O'Saasy 라이선스](https://github.com/glossia/glossia/blob/main/LICENSE.md). 조직의 내부 사용 목적으로 자체 호스팅, 수정 및 실행이 가능합니다. 라이선스가 허용하지 않는 유일한 사항은 glossia.ai 의 호스팅 서비스와 경쟁하는 호스팅 또는 SaaS 형태로 제 3 자에게 제공하는 것입니다.

이 가이드는 비어있는 Kubernetes 클러스터로부터 실행 중인 Glossia 인스턴스까지 안내합니다.

## 시작하기 전

필요 사항:

- Helm 차트 설치가 가능한 Kubernetes 클러스터 (v1.28 이상)
- `helm` 및 `kubectl` 로컬
- 클러스터 Ingress 로 연결할 수 있는 도메인
- OpenID Connect 공급자 또는 인증용 SMTP 릴레이 (Glossia 는 양쪽 모두 지원)

Helm 차트는 Postgres 를 포함합니다 ( 통해 [CloudNativePG](https://cloudnative-pg.io/)) 와 ClickHouse (를 통해 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)따라서 외부 데이터베이스가 필요 없으며, 직접 가져오기를 원하신다면 둘 모두 비활성화할 수 있습니다 `values.yaml`.

## Operator 설치

활성화하려는 구성 요소와 일치하는 Operator 를 설치하세요. 최소한:

- [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 앱 데이터베이스용
- [ClickHouse Kubernetes operator](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- Ingress 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS 를 자동으로 사용하시려면

## Glossia 차트 설치

저장소를 복제하고 차트를 설치:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## 앱 시크릿 제공

이름으로 Kubernetes 시크릿 생성 `glossia-app-env` 최소 다음과 같은 키가 필요합니다:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증용 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 pod 에서 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 나가는 이메일 설정 |

이 항목들을 직접 구성하고 사용하세요 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), Secret Manager 와 차트를 연결하는 다음 통합 을 위해 [External Secrets Operator](https://external-secrets.io/) integration described in the chart README.

## 차트 안에 뭐가 있습니까?

- Glossia 웹 애플리케이션
- 애플리케이션 데이터를 위한 Postgres (선택 사항, 기본값으로 켜짐)
- 분석을 위한 ClickHouse (선택 사항, 기본값으로 켜짐)
- 번역 작업용 백그라운드 워커는 Kubernetes Jobs 로 실행되어 롤링 배포에도 견딥니다.

## 다음 단계

- 이 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 는 각 값에 대한 완전한 참조, 백업, 객체 저장소 및 관측성에 대한 참고 사항도 포함합니다.
- [모델 제공자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역 작업이 LLM 을 호출할 수 있도록 합니다.
- 문제를 보고하거나 개선안을 제안하려면 이곳에서. [GitHub 저장소](https://github.com/glossia/glossia).