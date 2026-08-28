# 빠른 시작: Onboarding Router 리팩토링 검증

이 문서는 구현이 끝난 뒤 명세의 시나리오가 실제로 성립하는지 확인하는 절차다. 세부
필드·전이는 [data-model.md](./data-model.md)와
[contracts/onboarding-router-flow.md](./contracts/onboarding-router-flow.md)를 따른다.

## 사전 준비

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
```

workspace가 없다면 `sources`에서 `tuist generate`를 먼저 실행한다(`AGENTS.md` 참고).

## 시나리오 1 — 책임 분리 검증 (spec.md 시나리오 1)

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test --only-testing:Feature-Tests/AppEntryFeatureTests
"$project_build_runner" test --only-testing:Feature-Tests/OnboardingGuideFeatureTests
"$project_build_runner" test --only-testing:Feature-Tests/CurationFeatureTests
```

**기대 결과**: 세 테스트 target 모두 다른 화면 Feature나 `AppRootFeature`의 타입을
import하지 않고 독립적으로 컴파일·통과한다(SC-002).

## 시나리오 2 — App Root 진입 판단과 Router 흐름 검증 (spec.md 시나리오 2)

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test --only-testing:App-Tests/AppRootFeatureTests
"$project_build_runner" test --only-testing:Feature-Tests/OnboardingRouterFeatureTests
```

**기대 결과**: `AppRootFeatureTests`가 대표 진입 판단 4가지(미인증, 인증+프로필
미완료, 인증+프로필 완료, 복원 가능한 실패 재시도)를 모두 검증한다(SC-003).
`OnboardingRouterFeatureTests`가 대표 여정(정상 완료, 로그인 실패, 포지션 선택 뒤로
가기)에서 최종적으로 `delegate(.mainShellRequested)`가 발생함을 검증한다.

## 시나리오 3 — 화면 이동 이벤트 추적 검증 (spec.md 시나리오 3)

`OnboardingRouterFeatureTests` 안에서 다음을 확인한다.

1. `store.send(.guide(...))`로 튜토리얼 → 약관 동의 전환을 유발한다.
2. `store.state.transitionLog`(또는 동등한 조회 API)에서 마지막 이벤트의 `from`/`to`가
   같은 최상위 단위(`온보딩 안내`)의 서로 다른 연관값(튜토리얼/약관 동의)임을
   확인한다.
3. 정상 완료 여정 전체를 실행한 뒤 `transitionLog.count`와 실제 발생한 전환 횟수가
   정확히 일치하는지 확인한다(SC-004).
4. 포지션 선택 화면에서 값만 바뀌는 액션(예: `positionSelected`)을 보낸 뒤
   `transitionLog`에 새 이벤트가 추가되지 않았는지 확인한다(FR-007).

## 수동 확인 — 사용자 흐름 무변경 (SC-005)

1. iOS Simulator에서 앱을 실행한다.
2. 로그아웃 상태로 실행 → 스플래시 → 튜토리얼 1페이지 → 약관 동의 → Apple 로그인 →
   (필요 시) 포지션 → 경력 선택 → MainShell까지 리팩토링 전과 동일한 순서로
   진행되는지 확인한다.
3. 포지션 선택 화면에서 뒤로 가기 → 튜토리얼 3페이지로 돌아가는지 확인한다.
4. 이미 온보딩을 마친 계정으로 재실행 → 스플래시 이후 바로 MainShell로 진입하는지
   확인한다.

## 문서 검증 (FR-011)

```bash
grep -n "Router" docs/conventions/tca.md
```

**기대 결과**: `docs/conventions/tca.md`에 Router-Feature가 하위 Screen Feature를
조합하는 방식과 화면 이동 이벤트를 다루는 정식 섹션이 존재한다.
