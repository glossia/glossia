%{
  title: "Glossia 자체 호스팅",
  summary: "제공된 Helm 차트를 사용하여 자사 Kubernetes 클러스터에 Glossia 를 설치하여 팀이 자체 인프라에서 언어 OS 를 실행할 수 있습니다.",
  category: "가이드",
  order: 2
}
---
Glossia 는 [O'Saasy 라이선스](https://github.com/glossia/glossia/blob/main/LICENSE.md). 귀하여 자체 호스팅, 수정 및 조직 내부 운영이 가능합니다. 또한 라이선스는

이 가이드는 빈 Kubernetes 클러스터에서 실행 중인 Glossia 인스턴스로 안내합니다.

## 시작 전

필요한 것:

- Helm 차트 (v1.28 이상) 를 설치할 수 있는 Kubernetes 클러스터
- `helm` 그리고 `kubectl` 로컬
- 클러스터 인그레스를 지목할 수 있는 도메인
- 인증용 OpenID Connect 제공자 또는 SMTP 릴레이 (Glossia 는 두 가지를 모두 지원합니다)

Helm 차트는 Postgres 를 (를 통해 [CloudNativePG](https://cloudnative-pg.io/)",") 와 ClickHouse (를 통해 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)",") so you don't need external databases. If you'd rather bring your own, both can be disabled in `values.yaml`.

## Operators 설치

활성화하려는 구성 요소와 일치하는 Operators 를 설치하세요. 최소한:

- [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 앱 데이터베이스용
- [ClickHouse Kubernetes operator](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- Ingress 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS 자동화를 원하신다면

## Glossia 차트 설치

리포지토리를 복제하고 차트를 설치:

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

이름을 지정하여 Kubernetes Secret 생성 `glossia-app-env` 최소 해당 키 포함:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증을 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 파드에서 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 외부 이메일 설정 |

이들을 직접 프로비전할 수 있으며, 이를 사용하세요 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 차트를 기밀 관리자 로 연동하기 위해 [External Secrets Operator](https://external-secrets.io/) 차트 README 에서 설명된 통합입니다.

## 차트에 무엇이 있나요?

- Glossia 웹 애플리케이션
- 애플리케이션 데이터용 Postgres (선택 사항, 기본값으로 활성화됨)
- 애널리틱스용 ClickHouse (선택 사항, 기본값으로 활성화됨)
- 번역 작업용 백그라운드 워커로, Kubernetes Jobs 로 실행되어 롤링 배포 후에도 지속됩니다.

## 다음으로 이동

- 해당 [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 전체 참조를 가지고 있으며, 백업, 객체 저장소 및 관측 가능성에 대한 주석이 포함되어 있습니다.
- [모델 제공자 구성](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역 작업이 LLM 을 호출할 수 있도록.
- 문제를 보고하거나 개선안을 제안하세요. [GitHub 저장소](https://github.com/glossia/glossia).