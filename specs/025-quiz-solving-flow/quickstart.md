# 빠른 시작: Task 3 문제 풀이 흐름 검증

**기능 브랜치**: `feature/quiz-solving-flow`

**날짜**: 2026-09-03

이 문서는 구현 결과를 검증하는 실행 가이드다. 계약 내용은 [contracts/](./contracts)와
[data-model.md](./data-model.md)를 참조하고 여기서 반복하지 않는다.

## 사전 준비

workspace가 없으면 생성한다. Tuist manifest는 이 기능에서 바뀌지 않으므로 이미 있으면 생략한다.

```sh
make tuist
```

빌드·테스트 진입점을 읽는다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

기본 destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 `GIT_IT_TEST_DESTINATION`으로
덮어쓴다. 세 명령은 `sources/DerivedData/PreCommit`을 공유하므로 **순차 실행**한다.

작업 트리에 이전 기능의 미커밋 변경 100건이 있다(R-19). 검증 전 `git status --porcelain`으로 이
기능이 바꾼 파일만 stage되어 있는지 확인한다.

## 0. 변경 전 기준선 (SC-008)

구현 시작 전에 한 번 실행해 기준선이 통과하는지 남긴다.

```sh
"$project_build_runner" build && "$project_build_runner" compile && "$project_build_runner" test
```

## 1. 실행 단위별 검증

| 단위 | 명령 | 통과 기준 |
| --- | --- | --- |
| 1 데이터 정합(Domain+Composition) | `"$project_build_runner" compile && "$project_build_runner" test` | `DomainLearningProjectTests`·`CompositionAdapterTests` 통과. `LearningSetRepositoryAdapterTests`가 `description`·복수 출처·`previousAnswer`를, `LearningProjectRepositoryAdapterTests`가 DTO 값 그대로의 문제 수·완료 수를 검증 |
| 2 UI 컴포넌트 정합 | 위와 동일 | `UIComponentTests` 통과. `LearningSetRowTests`·`ChoiceResultRowTests`·`AccessibilityContractTests` 갱신본 통과 |
| 3 Quiz Reducer군 | 위와 동일 | `FeatureTests`의 `Tests/Quiz/Reducers/*` 통과 |
| 4 ProjectDetail Reducer | 위와 동일 | `Tests/ProjectDetail/Reducers/ProjectDetailFeatureTests` 통과 |
| 5 화면 조립 | `"$project_build_runner" build` | `Feature` scheme 빌드 성공, 프리뷰 컴파일 |
| 6 App 조립 | `build && compile && test` | `GitItTests`의 `AppRootFeatureTests` 통과 |
| 7 전체 [no-write] | §2 전체 | — |

## 2. 전체 검증 (SC-008)

```sh
"$project_build_runner" build
```

```sh
"$project_build_runner" compile
```

```sh
"$project_build_runner" test
```

셸 스크립트는 바꾸지 않으므로 `tools/script-tests`·`tools/script-verification`은 pre-commit이 실행하는
것으로 충분하다.

## 3. 성공 기준별 확인

### SC-002 · SC-006 — 화면 8종 상태 전이 테스트, 독립 실행

[data-model.md §7](./data-model.md#7-상태-전이와-검증-테스트-sc-002--sc-006--sc-010)의 표에 적힌 테스트
파일이 모두 존재하고 통과한다. 각 화면 Feature 테스트 파일이 다른 화면 Feature의 `State`를 생성하지
않는지 확인한다.

```sh
grep -L "QuizRouterFeature" sources/Projects/Feature/Tests/Quiz/Reducers/*FeatureTests.swift
```

`QuizRouterFeatureTests.swift`를 제외한 모든 파일이 출력되어야 한다(Router를 참조하지 않음).

### SC-003 — 정답 판정은 서버 값만

```sh
grep -rn "answerIndex ==\|== .*answerIndex\|correct =\|isCorrect" sources/Projects/Feature/Quiz sources/Projects/Feature/ProjectDetail
```

`ChoiceAnswerResult.correct`·`answerIndex`·`PreviousAnswer.correct`를 **읽는** 곳만 있어야 하며, 선택 index를
비교해 정오를 **계산**하는 식이 없어야 한다(`judgement(at:)`은 서버 `answerIndex`와의 동일성 비교만
허용).

### SC-004 — 세트 진행 표시가 서버 값

`LearningProjectRepositoryAdapterTests`가 통과하고, 다음 명령이 결과를 내지 않는다.

```sh
grep -n "problemCount: 0\|completedCount: 0" sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift
```

### SC-005 — Data 패키지 변경 0건

기준 커밋을 `develop`으로 두고 확인한다. 출력이 비어 있어야 한다.

```sh
git diff --name-only develop...HEAD -- sources/Projects/Data
```

### SC-007 — Reducer 생성자 인자가 계약과 일치

[contracts/feature-reducers.md §1](./contracts/feature-reducers.md#1-reducer별-주입-usecase와-사용-지점-fr-027)
표와 각 Reducer의 `public init` 인자를 대조한다.

```sh
grep -n -A8 "public init(" sources/Projects/Feature/Quiz/Reducers/*.swift sources/Projects/Feature/ProjectDetail/Reducers/*.swift | grep "UseCase\|openExternalLink"
```

### SC-009 — 제출 실패 시 입력 유지

`ChoiceQuestionFeatureTests`·`EssayQuestionFeatureTests`의 "제출 실패는 선택/입력을 유지한다" 테스트가 통과한다.

### SC-010 — 완료 카운터

`QuizSessionFeatureTests`에 혼합 세트(객관식 2·서술형 1, 정답 1)와 서술형만 세트에 대한 `setCompleted`
요약 테스트가 있고 통과한다. 전자는 `choiceQuestionCount == 2, correctChoiceCount == 1`, 후자는
`hasCounter == false`.

### SC-001 — 시뮬레이터 수동 확인

자동화 대상이 아니다. iPhone 17 Pro 시뮬레이터에서 다음 두 경로를 끝까지 진행하고 결과를 PR에
기록한다.

1. 홈 → 프로젝트 상세 → 세트 행 → 세트 시작 → 문제 전부 풀이 → 학습 완료 → `다음` → 프로젝트 상세의
   진행률·세트 세그먼트가 갱신됨.
2. 홈 이어 풀기 → 지정 문제부터 → 학습 완료 → `X` → 프로젝트 상세로 이동.

추가로 확인: 바로 시작이 세트 시작 화면을 건너뜀 · 상단 메뉴 버튼 없음 · 서술형 400자에서 입력 차단 ·
출처 없는 문제에 출처 버튼 없음 · 출처 링크가 외부 브라우저를 엶 · 뒤로가기가 확인 없이 즉시 동작.

## 4. 실패 시 대조 순서

1. 컴파일 오류 — [contracts/domain-model-changes.md](./contracts/domain-model-changes.md) §1의 시그니처와
   R-18 호출부 목록.
2. Router 전환 테스트 실패 — [contracts/screen-flow.md](./contracts/screen-flow.md) §2·§3의 해석표와
   활성 화면 순서.
3. UI 테스트 실패 — [contracts/ui-component-api.md](./contracts/ui-component-api.md) §1.
