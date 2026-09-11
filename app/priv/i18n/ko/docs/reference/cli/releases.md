%{title: "릴리스", summary: "CLI 릴리스 이력.", category: "참조", subcategory: "CLI", order: 2}
---
## 0.14.1

*2026-02-14*

#### 버그 수정

- 릴리스 아카이브 내의 바이너리를 플랫폼별 이름에서 단순히 `glossia`.
- 패키징 전 바이너리에서 macOS 격리 xattr 속성을 제거합니다.

## 0.14.0

*2026-02-14*

#### 기능

- Add local release script and manually-maintained changelog workflow.

## 0.2.0

*2026-02-14*

#### Bug Fixes

- Make OAuth provider config optional in production. The app should boot even without GitHub/GitLab OAuth credentials set. Only configure providers when the env vars are present.
- Default to port 4000 for production and keep 4050 for development. The production proxy expects the app on port 4000. The `runtime.exs` default was 4050, which caused health checks to fail during deployment.

#### 기능

- OAuth 로그인을 포함한 Phoenix 앱 추가, 문서 개선 및 UI 개선.
- 둥근 로고를 favicon 으로 사용.
- CLI 를 Bun 으로 마이그레이션하고 CI 실행 가능 빌드를 업데이트.

## 0.1.0

*2026-02-12*

#### 버그 수정

- 모바일 환경에서 코드 스니펫 가로 넘침 방지.
- 모바일에서 코드 스니펫에 올바른 오른쪽 여백을 추가합니다.
- 가로 오버플로우를 방지하기 위해 모바일 반응형 레이아웃을 개선합니다.
- biome 포맷팅을 적용합니다.
- 릴리스 노트 템플릿에 그룹 제목을 추가합니다.
- 번역 워크플로우를 Bun에서 Rust로 업데이트합니다.
- 게시글 본문을 히어로 레이아웃과 정렬하고 블로그 콘텐츠를 개선합니다.
- 블로그 콘텐츠를 가로로 중앙 정렬합니다.
- 다중 바이트 UTF-8 도구 결과 절단 시 발생하는 패닉을 수정합니다.

#### 기능

- 제 1 파티 도구 및 웹사이트 섹션 추가.
- 도구 검증 단계 표시.
- 진척 출력 간소화.
- 진척 줄 색조 적용.
- 번역 및 검증 작업 표시.
- 도구 줄 서식화.
- 모바일 메뉴 및 다중 브레이크포인트 레이아웃을 갖춘 반응형 웹사이트 제작.
- Bun/TypeScript 로 CLI 재구현하기.
- CI 워크플로우 및 테스트 추가하기.
- Biome 를 이용한 형식 검사 추가하기.
- 홈페이지에 Progressive Refinement 섹션 추가하기.
- SEO 지원 및 첫 번째 블로그 게시글을 포함한 블로그 섹션 추가하기.
- CLI 출력을 오른쪽 정렬 동사 형식으로 통일하기.
- CLI 출력을 더 풍부한 메시지 포맷팅으로 색칠하기.
- 정사각형 OG 이미지 및 트위터 카드 메타 태그 추가하기.
- 도구 사용을 활용한 코디네이터 에이전트 기능 강화.
- 재구현 `glossia init` Agent Client Protocol (ACP) 를 통해.
- 제미니 지원, 자동 검증, 토큰 추적 및 신뢰성 개선 추가.

#### 리팩토링

- CI 를 별도의 형식, 타입 검사, 테스트, 빌드 작업으로 분리.
- TypeScript/Bun 에서 Rust 로 CLI 재구현.