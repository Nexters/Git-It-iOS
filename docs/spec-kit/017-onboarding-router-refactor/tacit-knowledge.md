# 017-onboarding-router-refactor 암묵지 기록

**대상 기능**: `017-onboarding-router-refactor`

**기록 원칙**: 복수 근거에서 해석한 지식을 상태와 범위와 함께 append-only로 보존한다.

## TK-20260829-001: `tuist generate`는 workspace가 없을 때뿐 아니라 소스 파일을 이동·추가·삭제한 직후에도 빌드 전에 다시 실행해야 한다

**기록일**: 2026-08-29
**상태**: 검증됨
**확신도**: 높음
**적용 범위**: `sources/Projects/` 아래 Swift 소스 파일을 이동·추가·삭제하는 모든 기능
세션의 빌드·테스트 실행 절차
**관련 항목**: TS-20260829-001

### 해석

AGENTS.md는 `tuist generate`를 "workspace가 없을 때 먼저 실행"하는 절차로만 명시하지만,
실제로는 이미 생성된 workspace라도 소스 파일을 이동·추가·삭제한 뒤에는 빌드하기 전에
`tuist generate`를 다시 실행해야 한다는 것이 여러 세션에서 반복 관찰된 암묵적 요구사항이다.
Tuist가 생성한 `.xcodeproj`는 target의 `sourceDirectory` glob을 생성 시점에 한 번
평가해 개별 파일 참조로 고정하므로, 파일 시스템을 바꾼 뒤 재생성하지 않으면 생성된
프로젝트가 실제 디스크 상태와 어긋난다.

### 근거

- `AGENTS.md:52`: "workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행합니다."
  — 이미 존재하는 workspace가 파일 이동으로 stale해지는 경우는 다루지 않는다.
- `docs/spec-kit/001-apple-social-login/trouble-shooting.md:220-224`: "`tuist generate
  --no-open`으로 workspace와 project graph를 갱신한 뒤 다시 실행해 구현 타입 부재에 따른
  예상 컴파일 실패를 확인했다"— 별도 세션에서 동일 필요성이 관찰됨.
- `docs/spec-kit/012-github-public-repository-data/trouble-shooting.md:373,387`: "확정
  원인은 소스 파일 추가·삭제 후 `tuist generate`를 다시 실행하지 않아 생성 Xcode project가
  이전 파일 목록을 참조한 것이다" / "target source root 안의 파일을 추가하거나 삭제한 뒤
  Xcode build 전에 `tuist generate`를 실행해 생성 project의 입력 목록을 최신화한다" — 또
  다른 독립 세션에서 같은 원인·재발 방지가 명시적으로 기록됨.
- `docs/spec-kit/017-onboarding-router-refactor/trouble-shooting.md`
  TS-20260829-001: 이번 세션에서 `PolicyConsentUseCase.swift`를 이동한 뒤 `tuist
  generate` 없이 빌드해 "Build input file cannot be found" 오류로 6개 scheme이 실패했고,
  `tuist generate --no-open` 재실행만으로 10개 scheme 전부 성공으로 전환됨을 직접
  재현·검증했다.

### 적용과 제외

- 적용: 이 저장소에서 `sources/Projects/` 아래 Swift 소스 파일의 경로·존재 여부를 바꾼
  뒤(이동, 신규 생성, 삭제, 폴더 이름 변경), 같은 세션에서 빌드나 테스트를 실행하기 전.
- 제외: 파일 경로를 바꾸지 않고 기존 파일의 내용만 수정한 경우, 직전에 이미 `tuist
  generate`를 실행해 그 상태가 아직 유효한 경우.

### 반례와 불확실성

- `tuist generate` 재실행 비용(이번 세션 관측 4~5초 내외)이 대규모 변경이나 느린 환경에서
  얼마나 커질 수 있는지는 확인하지 않았다.
- Tuist에 파일 시스템 변경을 감지해 자동 재생성하는 watch 모드가 있는지는 조사 범위
  밖이다.

### 검증 또는 승격 조건

AGENTS.md 셋업 또는 빌드·테스트 절차에 "소스 파일을 이동·추가·삭제한 뒤에는 빌드 전에
`tuist generate`를 다시 실행한다"는 문장이 명시적으로 추가되면, 이 해석은 규범 문서로
승격된 것으로 보고 이 항목을 참조하는 후속 항목에서 상태 변화를 기록한다.

### 연결

[[TS-20260829-001]]
