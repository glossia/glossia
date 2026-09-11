%{
  title: " 자체 호스팅 Glossia",
  summary: "제공된 Helm 차트를 사용하여 자체 Kubernetes 클러스터에 Glossia 를 설치하여 팀이 자체 인프라에서 언어 OS 를 구동하게 하세요.",
  category: "가이드",
  order: 2
}
---
Glossia 는 해당 라이선스 하에 오픈 소스입니다 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 귀 조직의 내부용으로 자체 호스팅, 수정 및 실행이 가능합니다. 이 라이선스가 허용하지 않는 유일한 사항은 호스팅된 또는 SaaS 제품으로 제 3 자에게 제공하는 것이며, glossia.ai 의 호스팅 서비스를 경쟁하는 것입니다.

이 가이드는 빈 Kubernetes 클러스터에서 실행 중인 Glossia 인스턴스로 안내합니다.

## 시작 전

다음은 필요합니다:

- Helm 차트를 설치할 수 있는 Kubernetes 클러스터 (v1.28 이상)
- `helm` 그리고 `kubectl` 로컬로
- 클러스터 Ingress 에 연결할 수 있는 도메인입니다
- 인증용 OpenID Connect 제공자 또는 SMTP 릴레이입니다(Glossia 는 두 가지 모두 지원합니다)

Helm 차트는 Postgres(를 통해 [CloudNativePG](https://cloudnative-pg.io/)) 와 ClickHouse(를 통해 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)) 따라서 외부 데이터베이스가 필요 없습니다. 대신 자체 데이터베이스를 가져오기를 원하더라도 둘 다에서 비활성화할 수 있습니다. `values.yaml`.

## 오퍼레이터 설치

활성화하려는 컴포넌트와 일치하는 오퍼레이터를 설치하세요. 최소한:

- [CloudNativePG 오퍼레이터](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 애플리케이션 데이터베이스용
- [ClickHouse Kubernetes 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- 인그레스 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) TLS 자동화를 원할 경우

## Glossia 차트를 설치하세요

저장소를 복제한 후 차트를 설치하세요:

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

이름을 지정하여 Kubernetes Secret 을 생성 `glossia-app-env` 이러한 키 중 최소한 포함:

| 키 | 용도 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증을 위한 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 각 Pod 에 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 아웃바운드 이메일 설정 |

이를 직접 프로비전하여 사용할 수 있습니다. [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 차트를 귀하의 비밀 관리자를 통해 연결하세요 [External Secrets Operator](https://external-secrets.io/) 차트 README 에서 설명된 연동입니다.

## 차트에는 무엇이 있습니까?

- Glossia 웹 애플리케이션
- 애플리케이션 데이터용 Postgres(선택 사항, 기본값 ON)
- 분석용 ClickHouse(선택 사항, 기본값 ON)
- 번역 작업용 백그라운드 워커로, Kubernetes Jobs 로 실행되어 롤링 배포 후에도 계속 작동합니다.

## 다음으로 이동

- 해당 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 전체 참조 정보와 백업, 객체 저장소 및 관측성에 대한 설명을 포함합니다.
- [모델 제공자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역이 LLM 을 호출할 수 있도록 합니다.
- 문제 보고나 개선 제안은 이곳에서 [GitHub 저장소](https://github.com/glossia/glossia).