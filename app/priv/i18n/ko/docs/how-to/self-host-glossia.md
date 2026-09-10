%{
  title: "Glossia 자체 호스팅",
  summary:
    "제공된 Helm 차트를 사용하여 자체 Kubernetes 클러스터에 Glossia 를 설치하면, 팀이 자체 인프라에서 언어 OS 를 실행할 수 있습니다.",
  category: "가이드",
  order: 2
}
---
Glossia 는 다음 라이선스 하에 오픈 소스입니다 [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). 자체 호스팅과 수정이 가능하며, 조직의 내부 사용을 위해 실행할 수 있습니다. 라이선스가 허용하지 않는 유일한 사항은 호스팅 서비스인 glossia.ai 와 경쟁하는 호스팅 또는 SaaS 제품으로 제 3 자자에게 제공하는 것입니다.

이 가이드는 빈 Kubernetes 클러스터에서 실행 중인 Glossia 인스턴스로 안내합니다.

## 시작하기 전에

다음 항목이 필요합니다:

- Helm 차트를 설치할 수 있는 Kubernetes 클러스터 (v1.28 이나 그 이후 버전)
- `helm` 및 `kubectl` 로컬로 설정withstanding도영역
- 클러스터 인그레스로 지시할 수 있는 도메인입니다.
- 인증에 사용되는 OpenID Connect 공급업체 또는 SMTP 릴레이입니다 (Glossia 는 둘 다 지원합니다).

Helm 차트는 PostgreSQL 을 (를 [CloudNativePG](https://cloudnative-pg.io/)) 와 ClickHouse (을 통해 [공식 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator)) 로 외부 데이터베이스가 필요하지 않습니다. 대신 자체 기반을 가져오려면, 둘 다 비활성화할 수 있습니다. `values.yaml`.

## 오퍼레이터 설치

활성화하려는 컴포넌트에 맞는 오퍼레이터를 설치하세요. 최소ﺎ�:”

- [CloudNativePG 오퍼레이터](https://cloudnative-pg.io/documentation/current/installation_upgrade/) 앱 데이터베이스용
- [ClickHouse Kubernetes 오퍼레이터](https://github.com/ClickHouse/clickhouse-operator) 분석 데이터베이스용
- Ingress 컨트롤러 (예를 들어 [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) 자동 TLS 를 원하시면

## Glossia 차트를 설치하세요

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

## 앱 시크릿을 제공하세요

지정된 이름으로 Kubernetes Secret 생성 `glossia-app-env` 최소 다음 키들을 포함:

| 키 | 목적 |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix 세션 서명 키 |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer 토큰 보호 | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | 기본 인증용 `/ops` 대시보드 |
| `RELEASE_COOKIE` | 모든 포드에서 공유되는 Erlang 분산 쿠키 |
| `GLOSSIA_SMTP_*` | 외부 이메일 설정 |

이들을 직접 프로비저닝하고, 사용 [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), 또는 시크릿 매니저에 차트를 연결하기 위한 [External Secrets Operator](https://external-secrets.io/) 차트 README 에서 설명된 통합입니다.

## 차트 내의 항목

- Glossia 웹 애플리케이션
- 애플리케이션 데이터를 위한 Postgres (선택 사항, 기본값으로 활성화됨)
- 분석을 위한 ClickHouse (선택 사항, 기본값으로 활성화됨)
- 번역 작업용 백그라운드 워커는 Kubernetes Jobs 로 실행되어 롤링 배포보다 오래 지속됩니다.

## 다음으로 이동

- 해당 [Helm 차트 README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) 모든 값에 대한 전체 참조 및 백업, 오브젝트 스토리지, 관측 가능성에 대한 정보를 제공합니다.
- [모델 제공자 설정](/docs/how-to/configure-a-model-provider) 인스턴스가 실행되면 번역이 LLM 을 호출할 수 있습니다.
- 문제 보고 또는 개선 제안은 다음 곳에서 [GitHub 저장소](https://github.com/glossia/glossia).