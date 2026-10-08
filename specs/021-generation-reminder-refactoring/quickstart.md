# 빠른 시작: 생성 리마인드 명명·경계 리팩터링 검증

**기능 브랜치**: `feature/generation-reminder-refactoring`

**명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

이 문서는 리팩터링 결과를 검증하는 실행 절차를 기록한다. 구현 코드는 포함하지 않으며
계약 세부는 [contracts/](./contracts/)를, 타입 변경 목록은
[data-model.md](./data-model.md)를 참조한다.

## 사전 조건

```bash
make init
```

workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행한다. 이 기능은 Tuist manifest를
바꾸므로(테스트 target 신설, 형태 폴더 이동) **manifest 변경 후에는 반드시 재생성**한다.

```bash
make tuist
```

## 검증 명령

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" compile
```

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test
```

세 명령은 순차 실행을 전제로 `sources/DerivedData/PreCommit`을 공유한다. 기본 테스트
destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 `GIT_IT_TEST_DESTINATION`으로
덮어쓴다.

## 기준선 고정 (선행)

리팩터링 전에 **변경 전 테스트 통과 목록**을 저장한다. FR-018과 SC-003이 "변경 전 통과하던
테스트가 변경 후에도 100% 통과"를 요구하므로 비교 대상이 필요하다.

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test 2>&1 | tee /tmp/gitit-baseline-tests.log
```

## 시나리오별 검증

### 시나리오 1 — Infrastructure 경계 (SC-001)

서비스 고유 용어와 사용자 표시 문구가 남지 않아야 한다.

```bash
grep -rniE "세트|학습|generation-completed|생성 완료" sources/Projects/Infrastructure/PushMessaging --include="*.swift"
```

**기대 결과**: 출력 0줄.

파일 하나에 파일 밖 참조 타입이 하나인지 확인한다.

```bash
grep -rnE "^public (protocol|struct|enum|final class|actor) " sources/Projects/Infrastructure/PushMessaging --include="*.swift" | awk -F: '{print $1}' | uniq -c | awk '$1 > 1'
```

**기대 결과**: 출력 0줄.

### 시나리오 2 — 어휘 통일 (SC-002)

생성 결과 관련 공개 타입이 단일 어휘를 쓰는지, 옛 어휘가 남지 않았는지 확인한다.

```bash
grep -rnE "LearningProjectGenerationOutcome|ProjectGenerationOutcomeDTO|ProjectGenerationOutcomeRemote|LearningProjectOutcomes|GenerationCompletionReminder" sources/Projects --include="*.swift"
```

**기대 결과**: 출력 0줄.

이름 길이 상한(40자)을 확인한다.

```bash
grep -rhoE "\bGenerationOutcome[A-Za-z]*\b|\bObserveGenerationOutcomes[A-Za-z]*\b" sources/Projects --include="*.swift" | sort -u | awk '{ print length($0), $0 }' | sort -rn | head -5
```

**기대 결과**: 최댓값이 40 이하 (예상 최장 `GenerationOutcomeRepositoryAdapter` = 34).

### 시나리오 3 — 조립과 실행 분리 (SC-004)

`AppComposition.live(...)`가 부작용 없이 반환하는지는
`Composition/Tests/Adapter/Assemblies/AppCompositionPublicSurfaceTests.swift`가 검증한다.
`start()`를 호출하지 않은 인스턴스에서 기기 등록 호출이 관측되지 않아야 한다.

Composition 공개 API에 Infrastructure 구체 타입이 나타나지 않는지 확인한다.

```bash
grep -rnE "public (typealias|let|var|func).*(Firebase|UNUserNotification)" sources/Projects/Composition --include="*.swift"
```

**기대 결과**: 출력 0줄.

production 공개 API에 테스트 전용 연산이 남지 않았는지 확인한다.

```bash
grep -rn "waitUntilObservationFinished\|ForTesting" sources/Projects/Composition/Adapter --include="*.swift"
```

**기대 결과**: 출력 0줄.

### 시나리오 4 — 죽은 코드 제거 (SC-005)

```bash
grep -rn "notificationOptionSelected\|bellIconSize\|CancelID.submission\|GenerationReminderRegistryAdapter" sources/Projects --include="*.swift"
```

**기대 결과**: 출력 0줄.

삭제한 UI 컴포넌트가 남지 않았는지 확인한다.

```bash
ls sources/Projects/UI/Component/Controls/TextField.swift sources/Projects/UI/Tests/Component/Unit/Controls/TextFieldTests.swift 2>&1
```

**기대 결과**: 두 경로 모두 `No such file or directory`.

프로젝트 소유 enum에 미지 케이스 분기가 남지 않았는지 확인한다(이 기능이 만지는 파일 한정).

```bash
grep -rn "@unknown default" sources/Projects/Composition/Adapter/Adapters/GenerationOutcomeRepositoryAdapter.swift sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift 2>/dev/null
```

**기대 결과**: 출력 0줄.

### 시나리오 5 — 검증 공백 (SC-006, SC-007)

테스트 target이 등록되었는지 확인한다.

```bash
grep -n "InfrastructurePushMessagingTests" sources/Tuist/ProjectDescriptionHelpers/ProjectName.swift sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift
```

**기대 결과**: 두 파일 모두에서 최소 1줄씩 출력.

테스트 실행에 포함되어 통과하는지 확인한다.

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test 2>&1 | grep -i "InfrastructurePushMessagingTests"
```

**기대 결과**: 해당 target의 테스트 실행 기록이 나타나고 실패가 없다.

**SC-007 확인 방법**: 권한 결과 매핑 테스트가 실제로 분기를 잡는지 검증하려면
`NotificationAuthorizationGatewayAdapter`의 매핑 한 줄을 의도적으로 뒤바꾼 뒤 테스트를 실행해
실패를 확인하고, 원상복구한다. 이 확인은 커밋하지 않는다.

## 최종 검증 (SC-003, SC-009)

변경 전후 테스트 결과를 비교한다.

```bash
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" test 2>&1 | tee /tmp/gitit-after-tests.log
```

**기대 결과**: `/tmp/gitit-baseline-tests.log`에서 통과했던 테스트가 모두 통과한다. 이름이
바뀐 테스트는 대응 관계를 PR에 기록한다. 새로 실패하는 테스트가 0건이어야 한다.

셸 스크립트를 바꾸지 않았더라도 pre-commit이 실행하는 검증을 미리 확인한다.

```bash
./tools/script-verification/bin/run.sh
```

**주의**: 훅을 우회하지 않는다(`--no-verify` 금지). staged 파일과 포맷 결과가 다르면
pre-commit이 커밋을 막으므로, 포맷 후 변경 파일을 다시 stage한다.

## 실패 시 확인 순서

1. **manifest 오류** — `make tuist`를 다시 실행했는지 확인한다. 형태 폴더 이동과 테스트 target
   신설은 재생성 없이는 반영되지 않는다.
2. **이름 변경 누락으로 인한 컴파일 오류** — 어휘 통일은 Domain·Data·Composition·Feature·App을
   한 커밋 단위로 함께 바꿔야 한다([plan.md](./plan.md)의 실행 단위 U2·U3 참조).
3. **테스트 destination 오류** — `GIT_IT_TEST_DESTINATION`으로 사용 가능한 Simulator를 지정한다.
