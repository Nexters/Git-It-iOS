# Spec Kit 세션 기록

Spec Kit 작업 중 실제로 발생한 문제 해결 과정과 여러 세션에서 확인한 암묵지를 기능별로
보존합니다.

```text
docs/spec-kit/<feature>/
├── trouble-shooting.md
└── tacit-knowledge.md
```

- `<feature>`는 `specs/<feature>/`의 활성 기능 디렉터리 이름과 정확히 같아야 합니다.
- `trouble-shooting.md`는 `speckit-troubleshooting`만 생성하거나 끝에 추가합니다.
- `tacit-knowledge.md`는 `speckit-tacit-knowledge`만 생성하거나 끝에 추가합니다.
- 두 기록은 append-only이며 구현 작업이나 다른 Spec Kit 산출물의 쓰기 범위에 포함되지
  않습니다.
- 기록 루트는 `GIT_IT_DOCS_ROOT`의 공개 경로 판독 결과 아래 `spec-kit/`입니다.
