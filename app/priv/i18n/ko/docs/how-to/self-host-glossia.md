%{
  title: "Glossia 자체 호스팅",
  summary:
    "제공된 Helm 차트를 사용하여 자체 Kubernetes 클러스터에 Glossia 를 설치하면, 팀은 자체 인프라에서 언어 OS 를 실행할 수 있습니다.",
  category: "사용 가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 하에 오픈 소스입니다 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 귀 조직의 내부 사용을 위해 자체 호스팅하고, 수정하며, 운영할 수 있습니다. 라이선스가 허용하지 않는 유일한 사항은 호스팅 서비스나 SaaS 제품으로 타사에 제공하여 glossia.ai 의 호스팅 서비스와 경쟁하는 것입니다.

이 가이드는 빈 Kubernetes 클러스터에서 실행 중인 Glossia 인스턴스로 설정하는 방법을 안내합니다.

## 시작하기 전에

다음은 필요합니다:

- Helm 차트 설치가 가능한 Kubernetes 클러스터 (v1.28 이전)
- `helm` 그리고 `kubectl` 로컬에서
- 클러스터 인그레스를 연결할 수 있는 도메인
- 인증용 OpenID Connect 제공자 또는 SMTP 릴레이 (Glossia 는 양쪽 모두 지원합니다)

Helm 차트는 Postgres 를 포함합니다 (via [CloudNativePG](https://cloudnative-pg.io/)) 및 ClickHouse(를 통한 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)) 따라서 외부 데이터베이스가 필요 없습니다. 대신 직접 제공하는 경우, 둘 다 비활성화 가능합니다. `values.yaml`.

## 오퍼레이터 설치

활성화하려는 컴포넌트와 일치하는 오퍼레이터만 설치하세요. 최소:

- [CloudNativePG 오퍼레이터](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 앱 데이터베이스용
- [ClickHouse 쿠버네티스 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- 엔그레스 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 자동 TLS 를 원하시면

## Glossia 차트를 설치하세요

리포지토리를 클론한 후 차트를 설치하세요:

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

이름을 지정하여 Kubernetes Secret 생성 `glossia-app-env` 최소한 다음과 같은 키:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증을 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 pod 에서 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 아웃바운드 이메일 설정 |

이 항목들은 직접 프로비저닝하여 사용할 수 있습니다 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 차트를 비밀 관리자와 연결하기 위해 해당 [External Secrets Operator](https://external-secrets.io/) 차트 README 에 기술된 통합.

## 차트에 무엇이 포함되어 있는지

- Glossia 웹 애플리케이션
- 애플리케이션 데이터용 Postgres (선택적, 기본 활성화)
- 애널리틱스용 ClickHouse (선택적, 기본 활성화)
- 번역 작업용 백그라운드 워커, Kubernetes Jobs 로 실행되어 롤링 배포에도 지속됩니다.

## 다음으로 이동하세요

- 이 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 전체 참조 정보를 제공하며, 백업, 객체 저장소, 및 관찰 가능성에 대한 설명도 포함됩니다.
- [모델 공급자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역이 LLM 을 호출할 수 있도록 합니다.
- 문제를 신고하거나 개선안을 제안하는 곳 [GitHub 저장소](https://github.com/glossia/glossia).