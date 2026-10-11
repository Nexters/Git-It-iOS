# 빠른 시작: 레포지토리 생성 상태관리 Repository 검증

## 사전 준비

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
```

workspace가 없다면 `sources`에서 `tuist generate`를 먼저 실행한다.

## 1. Domain 단위 테스트로 시나리오 검증

- 시나리오 1(중복 생성 차단)·시나리오 3(완료/실패 해제, 타임아웃)은
  `sources/Projects/Domain/Tests/LearningProject/UseCases/CreateLearningProjectTests.swift`의
  신규 테스트로 검증한다. in-memory 테스트 더블(`RepositoryCreationStateRepository` 프로토콜을
  구현한 스텁)을 사용해 서버 호출 없이 `beginCreation`/`endCreation` 호출 여부와 반환된
  `LearningProjectError.duplicateCreationInProgress`를 확인한다.
- 시나리오 2(목록 필터링)는
  `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningProjectsTests.swift`의
  신규 테스트로 검증한다. `activeProjectIDs()`가 특정 `projectID`를 반환하도록 스텁을 구성하고,
  `FetchLearningProjects.callAsFunction()`의 결과 `items`에 해당 `projectID`가 없는지 확인한다.

```sh
"$project_build_runner" compile
"$project_build_runner" test
```

(위 두 명령은 프로젝트 전체 test-without-building 파이프라인을 실행한다. 이 기능만 좁혀
확인하려면 Xcode에서 `DomainTests` scheme의 해당 테스트만 실행해도 된다.)

## 2. Composition adapter 테스트로 배선 검증

- `sources/Projects/Composition/Tests/Adapter/Adapters/RepositoryCreationStateRepositoryAdapterTests.swift`
  신규 테스트에서:
  - `beginCreation` → `attachProjectID` → `activeProjectIDs()`에 반영되는지, 같은 URL의
    `isCreating`이 `true`로 바뀌는지 확인한다.
  - 가짜 `ObserveGenerationOutcomesUseCase` 스트림에 `GenerationOutcome(projectID:, status: .completed)`를
    흘려보내면 `activeProjectIDs()`에서 해당 `projectID`가 사라지는지 확인한다.
  - `recordedAt`을 900초 이전으로 주입(테스트용 시계 추상화 또는 fixture)한 레코드가 다음
    조회에서 사라지는지 확인한다.

## 3. 회귀 확인

- 기존 `LearningProjectRepositoryAdapterTests`, `BookmarkRepositoryAdapterTests`가 이 변경과
  무관하게 그대로 통과하는지 확인한다(SC-004).
- `LearningProjectError`에 case를 추가했으므로, 이 enum을 `switch`하는 기존 Feature 계층
  코드가 컴파일되는지(`"$project_build_runner" build`) 확인한다. 컴파일 실패가 나면 해당
  `switch`에 새 case 처리를 추가해야 하며, 이는 이 기능의 정상적인 회귀 방지 신호다.

## 기대 결과

- 동일 `githubRepoURL`로 연속 생성 요청 시 두 번째 요청이 네트워크 호출 없이 즉시 실패한다.
- "생성 중" 레포지토리는 `FetchLearningProjects` 결과에 나타나지 않는다.
- 완료/실패 신호 또는 900초 경과 후에는 동일 레포지토리로 재요청이 다시 허용되고 목록에도
  정상적으로 나타난다(서버가 완료로 반환하는 경우).
