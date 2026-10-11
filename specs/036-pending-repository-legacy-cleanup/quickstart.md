# 빠른 검증 가이드: 036-pending-repository-legacy-cleanup

구현이 끝난 뒤 명세의 성공 기준을 확인하는 절차다. 명령은 저장소 루트에서 실행한다. 빌드·컴파일·
테스트는 사용자가 직접 실행한다.

## 준비

```sh
make tuist
```

- workspace가 없거나 Tuist manifest(`DataModuleName.swift`, `CompositionModuleName.swift`)가 바뀐 뒤에 실행한다.
- 실행 전후 `git status --short`로 추적 파일 변경이 없는지 확인한다.

## 시나리오 1: 생성 대기 Repository (SC-001~SC-003)

1. 옛 계약과 우회 경로가 남지 않았는지 확인한다.

   ```sh
   git grep -nE 'GenerationStateRepository|PendingGenerationReminders\b|GenerationStateStore|LocalGenerationStateStore|PendingGenerationReminderCoding|makePendingReminderEnqueue' -- sources
   ```

   기대 결과: 0건.

2. 생성 요청·목록 조회가 Repository만으로 대기를 확인하는지 확인한다.

   ```sh
   git grep -n 'trackGeneration' -- sources/Projects/Domain/LearningProject/UseCases/CreateLearningProject sources/Projects/Domain/LearningProject/UseCases/FetchLearningProjects
   ```

   기대 결과: 0건.

3. 앱 전용 기본 저장소 대체 경로가 없는지 확인한다.

   ```sh
   git grep -nE '\?\? *\.standard' -- sources/Projects/Composition
   ```

   기대 결과: 0건.

4. 테스트로 동작을 확인한다. [contracts/pending-generation-repository.md](./contracts/pending-generation-repository.md)
   5장의 사례가 모두 존재하고 통과해야 한다.

## 시나리오 2: 이관 코드 제거 (SC-004)

```sh
git grep -nE 'GenerationStateMigration|SessionStorageMigration|LegacyGenerationProgressDTO|LegacyRepositoryCreationStateDTO|makeLegacy|migrateSessionKeychain' -- sources
```

기대 결과: 0건. `sources/Projects/Data/Authentication/Migrations/` 폴더가 없어야 한다.

## 시나리오 3: Data 기술 재구현 제거 (SC-005·SC-006)

```sh
git grep -nE 'enum HTTPMethod|enum Method\b|let method: String|func httpMethod' -- sources/Projects/Data ':!sources/Projects/Data/Tests'
```

기대 결과: 0건.

Remote 요청 기대값이 바뀌지 않았는지 확인한다.

```sh
git diff develop -- 'sources/Projects/Data/Tests/**/Remotes/*.swift' | grep -E '^[-+].*(path|method|queryItems|headers|"/api)'
```

기대 결과: 기대 문자열 값의 변경 없음. 더블 타입 이름이나 생성 인자 변경만 허용한다.

## 시나리오 4: Infrastructure 의존의 Data 한정 (SC-007~SC-011)

1. Data 밖 import와 manifest 의존이 없는지 확인한다.

   ```sh
   git grep -lE '^\s*(@testable\s+)?import\s+Infrastructure' -- sources/Projects ':!sources/Projects/Data' ':!sources/Projects/Infrastructure'
   git grep -n 'fromInfrastructure' -- sources/Tuist ':!sources/Tuist/ProjectDescriptionHelpers/Projects/DataModuleName.swift' ':!sources/Tuist/ProjectDescriptionHelpers/Projects/InfrastructureModuleName.swift'
   ```

   기대 결과: 두 명령 모두 0건.

2. 자동 검사를 실행한다.

   ```sh
   runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PACKAGE_DEPENDENCY_RUNNER)
   "$runner"
   ./tools/script-tests/bin/run.sh
   ```

   기대 결과: 둘 다 종료 코드 0. `script-tests`에는 Composition의 Infrastructure import를 위반으로 판정하는
   fixture 사례가 포함된다([contracts/dependency-rules.md](./contracts/dependency-rules.md) 2장).

3. Data 공개 선언에 기술 타입이 없는지 확인한다.

   ```sh
   git grep -nE '^\s*public\b.*\b(UserDefaults|UserDefaultsStore|KeychainStore|KeychainNamespace|HTTPClient|HTTPTransport|HTTPRequest|NotificationAuthorizationClient|PushMessagingClient|PushMessagingAppDelegate)\b' -- sources/Projects/Data ':!sources/Projects/Data/Tests'
   ```

   기대 결과: 0건.

4. 저장 좌표를 고정하는 테스트(`SessionStorageCoordinateTests`, `GenerationReminderStorageCoordinateTests` 또는
   `DataSharedTests`로 옮긴 후속 테스트)의 기대값 diff가 없는지 확인한다.

   ```sh
   git diff develop -- 'sources/Projects/Data/Tests/**/Layouts/*.swift' 'sources/Projects/Data/Tests/Shared/**' | grep -E '^-.*"com\.nexters'
   ```

   기대 결과: 삭제된 좌표 문자열 없음(파일 이동이면 같은 문자열이 추가 쪽에도 존재). Data 저장 타입 테스트가
   `InMemoryKeyValueStorage`·`InMemorySecureValueStorage` 더블을 주입하는지 확인한다(SC-011).

5. Composition 테스트가 Infrastructure 타입 없이 Data 역할 Protocol 더블로 주입하는지 확인한다(SC-010).

   ```sh
   git grep -nE '\b(KeychainStore|UserDefaultsStore|HTTPTransport|HTTPTransportResponse|HTTPClient|StandardJSONBodyCoding|NotificationAuthorizationClient|AppleAuthorizationProvider|AppleCredentialStateProvider)\b' -- sources/Projects/Composition/Tests
   ```

   기대 결과: 0건.

## 시나리오 5: Home 관찰 재개 (SC-012)

[contracts/home-generation-observation.md](./contracts/home-generation-observation.md) 3장의 테스트 3개가 존재하고
통과해야 한다.

```sh
git grep -n 'generationOutcomeObservation' -- sources/Projects/Feature
```

기대 결과: 0건.

수동 확인(선택): 앱에서 학습 프로젝트 생성을 요청하고 Home에서 다른 탭으로 이동한다. 생성 완료 푸시를 받은 뒤
Home으로 돌아오면 목록에 새 프로젝트가 보인다.

## 전체 검증 (SC-013)

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

셸 스크립트를 바꿨으므로 다음도 실행한다.

```sh
./tools/script-verification/bin/run.sh
```
