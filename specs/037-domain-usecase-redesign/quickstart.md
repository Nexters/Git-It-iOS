# 빠른 검증: 관심사별 Domain UseCase 재설계

## 준비

```sh
make tuist
```

workspace를 다시 생성합니다. 새 Domain 타깃과 scheme이 반영되어야 합니다.

## 1. 구조 검증 (SC-001, SC-002, SC-004, SC-007)

```sh
./tools/package-dependencies/bin/run.sh
```

기대 결과: 위반 0건. `source-roots`와 매니페스트 타깃이 일치한다.

```sh
grep -rhn "^public protocol .*UseCase" sources/Projects/Domain --include="*.swift" | grep -v "/Tests/"
```

기대 결과: `AccountUseCase`, `UserInfoUseCase`, `AppSettingUseCase`, `ExternalRepositoryUseCase`, `QuizDetailUseCase`,
`ProjectUseCase`, `ProjectGenerationUseCase` 7줄.

```sh
grep -rn "^import Domain" sources/Projects/Domain --include="*.swift" | grep -v "/Tests/" | grep -v "import DomainIdentifier"
```

기대 결과: 0줄(관심사 타깃 간 import 없음).

```sh
grep -rnE "public (struct|enum|protocol|actor|final class|typealias|func) [A-Za-z]*(Session|Token)" sources/Projects/Domain --include="*.swift" | grep -v "DeviceToken" | grep -v "/Tests/"
grep -rnE "func (load|save|fetch)[A-Z(]" sources/Projects/Domain --include="*.swift" | grep -v "/Tests/"
```

기대 결과: 둘 다 0줄.

```sh
grep -rnE "RefreshSession|TrackGeneration|FetchLearningProjects|LearningLibrary|MemberAccount|CreateLearningProject|RequestGenerationReminder|ScheduleGenerationReminder|SetQuestionBookmark|SubmitChoiceAnswer|SubmitEssayAnswer|FetchExternalRepository|DeleteMemberAccount|ResolveSessionAvailability|RestoreSession|VerifyAuthorization|PolicyConsentUseCase|DomainAuthentication|DomainLearningProject|DomainMember" sources/Projects sources/Tuist --include="*.swift" | grep -v "/Derived/"
```

기대 결과: 0줄.

## 2. 단위 테스트 (SC-005)

프로젝트 실행기로 테스트를 실행합니다(사용자 환경에서 실행).

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" compile
"$project_build_runner" test
```

시나리오별 대표 테스트 위치:

| 시나리오 | 테스트 |
| --- | --- |
| 2 목록 공유 | `sources/Projects/Domain/Tests/Project/UseCases/ProjectTests.swift`, `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`(퀴즈 닫기) |
| 3 생성 단계·알림 | `sources/Projects/Domain/Tests/ProjectGeneration/UseCases/ProjectGenerationTests.swift` |
| 4 로그인 무효 | `sources/Projects/Data/Tests/Authentication/Stores/RequestCredentialProviderTests.swift`, `sources/Projects/Domain/Tests/Account/UseCases/AccountTests.swift`, `sources/Projects/Data/Tests/LearningProject/Remotes/LearningProjectRequestExecutorTests.swift` |
| 5 회귀 | 각 관심사 `Domain/Tests/<관심사>/UseCases/*Tests.swift`, Feature 테스트 |

## 3. 빌드 (SC-006)

```sh
"$project_build_runner" build
```

기대 결과: 모든 공유 scheme 빌드 성공.

## 4. 수동 확인 (시뮬레이터)

1. 로그인 → Home과 프로젝트 목록 탭이 같은 목록을 보인다.
2. 프로젝트 생성 요청 → Home 배너가 켜지고 목록에 새 프로젝트가 없다 → 생성 완료 후 300초가 지나면 배너가 꺼지고 목록에 나타난다.
3. 퀴즈를 풀고 닫기 → Home 카드 진행률과 "이어 학습" 대상 세트가 갱신된다.
4. 설정에서 로그아웃 → 다시 로그인했을 때 이전 생성 배너가 남아 있지 않다.
