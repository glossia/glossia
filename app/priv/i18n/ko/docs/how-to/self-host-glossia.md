%{
  title: "Glossia 자체 호스팅",
  summary:
    "포함된 Helm 차트를 사용하여自身の Kubernetes 클러스터에 Glossia 를 설치하세요. 이를 통해 팀은 자체 인프라에서 언어 OS 를 실행할 수 있습니다.",
  category: "가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 하에 [O'Saasy 라이선스](https://github.com/glossia/glossia/blob/main/LICENSE.md). 이를 자체 호스팅하고 수정하여 조직의 내부 사용을 위해 실행할 수 있습니다. 라이선스가 허용하지 않는 유일한 사항은 제 3 자에게 호스팅되거나 SaaS 제품으로 제공하여 glossia.ai 의 호스팅 서비스와 경쟁하는 것입니다.

이 가이드는 빈 Kubernetes 클러스터를 실행 중인 Glossia 인스턴스로 안내합니다.

## 시작 전

다음 항목이 필요합니다:

- Helm 차트를 설치할 수 있는 Kubernetes 클러스터 (v1.28 또는 그 이상)
- `helm` 및 `kubectl` 로컬
- 클러스터 인그레스를 가리킬 수 있는 도메인
- 인증용 OpenID Connect 제공자 또는 SMTP 릴레이 (Glossia 는 둘 다 지원함)

Helm 차트는 Postgres 를 포함합니다 (를 통해 [CloudNativePG](https://cloudnative-pg.io/)) 및 ClickHouse (를 통해 [공식 연산자](https://github.com/ClickHouse/clickhouse-operator)) 외부 데이터베이스도 필요없습니다. 만약 자체 DB 를 가져오신다면, 둘 다 에서 비활성화할 수 있습니다 `values.yaml`.

## 오퍼레이터 설치

활성화하려는 구성 요소와 일치하는 오퍼레이터만 설치하세요. 최소한:

- [CloudNativePG 오퍼레이터](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 애플리케이션 데이터베이스를 위해
- [ClickHouse Kubernetes 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스를 위해
- Ingress 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS 자동화가 필요하다면

## Glossia 차트를 설치하세요

리포지토리를 클론하고 차트를 설치하세요:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## 앱 시크릿을 제공하세요

이름을 가진 Kubernetes Secret 을 생성하세요 `glossia-app-env` 최소 다음과 같은 키가 필요합니다:

| 키 | 용도 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth 를 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 pod 에 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 발송 이메일 설정 |

이들을 직접 프로비저닝할 수 있으며, 사용 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 차트를 기밀 관리자를 통해 연결하십시오 [External Secrets Operator](https://external-secrets.io/) 차트 README 에 설명된 통합입니다.

## 차트에 포함된 것

- Glossia 웹 애플리케이션
- 애플리케이션 데이터용 Postgres (선택 사항, 기본 활성화)
- 애널리틱스용 ClickHouse (선택 사항, 기본 활성화)
- 번역 작업용 백그라운드 워커는 Kubernetes Jobs 로 실행되어 롤링 배포를 견딤니다

## 다음으로 이동하기

- 그 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 완전한 참조를 제공하며 백업, 객체 스토리지 및 관찰 가능성에 대한 주석을 포함합니다.
- [모델 제공자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역이 LLM 을 호출할 수 있도록 합니다.
- 문제를 보고하거나 개선 제안을 제안하는 곳입니다. [GitHub 저장소](https://github.com/glossia/glossia).