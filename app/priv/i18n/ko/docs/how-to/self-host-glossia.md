%{
  title: "Glossia 자체 호스팅",
  summary: "제공된 Helm 차트를 통해 자체 쿠버네티스 클러스터에 Glossia 를 설치하여 팀이 자체 인프라에서 언어 OS 를 운영할 수 있도록 하세요.",
  category: "가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 아래에 오픈소소입니다 [O'Saasy 라이선스](https://github.com/glossia/glossia/blob/main/LICENSE.md). 자체 호스팅, 수정 및 조직 내부 운영이 가능합니다. 라이선스가 허용하지 않는 유일한 것은, 호스팅 형식 또는 SaaS 제품으로서 제 3 자에게 제공하여 glossia.ai 의 호스팅 서비스에 경쟁하는 것입니다.

이 가이드 는 빈 Kubernetes 클러스터에서 실행 가능한 Glossia 인스턴스로 이동시켜 줍니다.

## 시작하기 전

다음 준비물이 필요합니다:

- Helm 차트를 설치할 수 있는 Kubernetes 클러스터 (v1.28 이상)
- `helm` 및 `kubectl` 로컬
- 클러스터 인그레스에 연결할 수 있는 도메인
- 인증용 OpenID Connect 제공자 또는 SMTP 릴레이 (Glossia 는 양쪽 모두 지원합니다)

Helm 차트는 Postgres 를 포함합니다 (을 통해 [CloudNativePG](https://cloudnative-pg.io/)) 와 ClickHouse (를 통한 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)) 따라서 외부 데이터베이스가 필요 없습니다. 대신 직접 가져오더라도, 둘 모두 해당 설정에서 비활성화할 수 있습니다 `values.yaml`.

## Operator 를 설치하세요

계획한 구성 요소와 일치하는 Operator 를 설치하세요. 최소:

- [CloudNativePG Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 애플리케이션 데이터베이스용
- [ClickHouse Kubernetes Operator](https://github.com/ClickHouse/clickhouse-operator) 애널리틱스 데이터베이스용
- 인그레스 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS 자동화를 원하신다면

## Glossia 차트 설치

저장소를 클론한 후 차트를 설치:

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

이름으로 지정된 Kubernetes Secret 을 생성하세요 `glossia-app-env` 최소 다음과 같은 키:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증을 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 파드에서 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 발신 이메일 설정 |

이들을 직접 구성할 수 있으며, 사용 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)", "또는 차트를 비밀 관리자를 통해 연결하세요 [External Secrets Operator](https://external-secrets.io/) 차트 README 에서 설명된 통합입니다.

## 차트에 무엇이 포함되어 있습니까?

- Glossia 웹 애플리케이션
- 애플리케이션 데이터 전용 Postgres (선택 사항, 기본값 켜짐)
- 분석 전용 ClickHouse (선택 사항, 기본값 켜짐)
- 번역 작업용 백그라운드 워커로, Kubernetes Jobs 로 실행되어 롤링 배포보다 오래 지속됩니다.

## 다음으로 이동할 곳

- 이 [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 각 값에 대한 전체 참조뿐만 아니라 백업, 객체 저장소 및 관측 가능성에 대한 정보를 제공합니다.
- [모델 공급자 구성](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역이 LLM 을 호출할 수 있습니다.
- 이슈 보고 또는 개선 제안은 이 곳에서 하세요. [GitHub 저장소](https://github.com/glossia/glossia).