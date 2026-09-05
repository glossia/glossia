%{
  title: "명령어",
  summary: "모든 Glossia 명령줄 명령어 및 플래그에 대한 참조.",
  category: "참조",
  subcategory: "명령줄",
  order: 1
}
---
## `glossia init`

현재 저장소에서 시작 템플릿 `GLOSSIA.md` 설정 파일 만듭니다.

```bash
glossia init
```

이미 existir `GLOSSIA.md` 존재할 경우 실패합니다.

## 번역은 서버 측에서 처리됩니다.

번역은 명령행 인터페이스가 아닌 Glossia 서버에서 실행됩니다. 커밋이 제출될 때,
Glossia 는 귀하의 `GLOSSIA.md` 오류를 바로 번역합니다.
위에 구성 모델
결과를 기반으로 강한 번역 세션 페이지에서 파일 을 보 كن.

모델은 문서별로 선택되며: `GLOSSIA.md` `model:` 귀하의
 계정 모델 처리 핸들러

명령행 인터페이스는 의도적으로 계획, 번역, 무효
검사하거나 삭제
 번역 잠금 파일을

## `glossia revisit`

미래의
인터페이스는

```bash
glossia revisit
```

## 전역 플래그

| Flag | Description |
|---|---|
| `--path <PATH>` | Override the project root directory |
| `--no-color` | Disable colored output |