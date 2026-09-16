# 작업 목록: Domain UseCase 분해 기준 확정과 통합

**입력**: `/specs/033-usecase-consolidation/`의 설계 문서

**선행 조건**: [plan.md](./plan.md)(필수), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/README.md](./contracts/README.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를 실행 기준선으로 고정한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 필요한 경우에만 만든다.

**테스트**: 명세 [spec.md](./spec.md)의 SC-007·SC-008·SC-009·SC-010이 자동화 테스트 증명을 요구하므로 테스트 작업을 포함한다. 특히 순서 보장은 통합 계약 기준으로 다시 확인한다.

**구성**: [plan.md](./plan.md)의 실행 단위 U1, I1, I2, I3, I4, U2를 최상위 구조로 사용하고, 변경 시나리오는 각 단위 안에서 `[S1]`~`[S4]` 라벨로 추적한다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- `[P]` — 같은 실행 단위 안에서 서로 다른 파일을 다루고 미완료 작업에 의존하지 않는 작업
- `[S1]` 분해 기준 문서화 / `[S2]` 변경 연산 순서 보장 내재화 / `[S3]` 주입 배관 축소 / `[S4]` 잔여 정리
- `[no-write]` — 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후 Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다

## 실행 단위 소유권 규칙

- 파일 변경 작업은 책임 패키지 단계에 배치한다.
- 위상 순서의 근거는 [아키텍처 3.1](../../docs/architecture.md)의 패키지 의존성 표다. `Domain`이 가장 아래, `Composition`이 그 뒤, `Feature`와 `App`이 마지막이다.
- I1·I2·I4는 다중 패키지 integration unit이다. 근거는 [plan.md](./plan.md)의 각 "I{N}을 다중 패키지 단위로 두는 근거"에 있다. I3은 단일 패키지 단위다.
- U1은 나머지 모든 판정의 근거이므로 코드 단위보다 먼저 둔다. U2는 결과를 기록하므로 모든 코드 단위 뒤에 둔다.

## 사용자 소유 변경과의 충돌

I2와 I4는 아래 두 파일을 함께 고쳐야 한다. 두 파일에는 이 명세와 무관한 사용자 작업 중
변경이 있다.

- `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`
- `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`

`/speckit-implement`는 이 두 경로에 도달하면 stage하지 않고 중단해 보고한다. 자세한 조건은
아래 "승인이 필요한 지점"에 있다.

---

## 작업 단위 1 (U1): 문서 — 분해 기준 확정과 기록

**목표**: UseCase를 독립 타입으로 둘 기준을 규칙 문서에 고정해, I1~I4의 판정이 흔들리지 않게 한다.

**관련 변경 시나리오**: S1

**독립 테스트**: `docs/package-rules/domain.md`만 읽고 현재 UseCase 각각의 독립 유지 여부를 [data-model.md](./data-model.md) 2절과 같은 결론으로 판정할 수 있는지 확인한다.

### 준비

- [X] T001 [no-write] [S1] 적용 전 지표를 측정한다 — [quickstart.md](./quickstart.md)의 "기준선 측정" 네 명령을 실행하고 값을 이 파일의 "기준선 기록" 절에 적는다

### 구현

- [X] T002 [S1] `docs/package-rules/domain.md`에 UseCase 분해 기준을 추가한다. 독립 타입으로 둘 두 조건(저장소 호출 외 판단·조율·보상·동시성 제어 수행, 둘 이상의 계약 조합)과 둘 다 아닐 때 모듈 능력 단위 계약으로 통합한다는 규칙, 그리고 통합 계약이 직렬화 같은 보장을 구현 내부에 둔다는 규칙을 검증 가능한 문장으로 적는다

### 단위 검증

- [X] T003 [no-write] [S1] [data-model.md](./data-model.md) 2절의 판정 28건을 T002의 기준에 하나씩 대입해 같은 결론이 나오는지 확인하고, 다른 결론이 나오는 항목이 있으면 이 파일의 "판정 기록" 절에 적는다

**진행 점검**: T001~T003의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 1 (I1): Domain + Composition — 소비자 없는 UseCase 제거

**분리 불가 근거**: `VerifyAccessTokenUseCase`를 제거하면 그것을 만들고 공개하는 `AuthenticationAssembly`와 `AppComposition`이 같은 순간 컴파일 실패한다. `RegisterMemberDeviceUseCase`도 `MemberAssembly`, `AppComposition`, 같은 Domain 모듈의 `RegisterCurrentDevice`가 함께 바뀌어야 한다.

**소유 경로**: `sources/Projects/Domain/Authentication/UseCases/VerifyAccessToken/**`, `sources/Projects/Domain/Member/UseCases/{RegisterMemberDevice,RegisterCurrentDevice}/**`, `sources/Projects/Composition/Adapter/Assemblies/{AuthenticationAssembly,MemberAssembly}.swift`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, 대응 테스트

**관련 변경 시나리오**: S4

**독립 테스트**: 두 UseCase 이름으로 프로덕션 소스를 검색해 결과가 없고, 기기 등록이 통합 전과 같은 정보를 담는지 Domain 테스트로 확인한다.

**통합 검증**: `Domain`과 `Composition` 테스트 scheme을 함께 실행한다.

### 구현

- [ ] T004 [S4] `sources/Projects/Domain/Member/UseCases/RegisterCurrentDevice/RegisterCurrentDevice.swift`가 `RegisterMemberDeviceUseCase` 대신 `MemberRepository`를 받아 `registerDevice(_:)`를 직접 호출하도록 바꾼다
- [ ] T005 [S4] `sources/Projects/Domain/Tests/Member/UseCases/RegisterCurrentDevice/RegisterCurrentDeviceTests.swift`의 test double을 `MemberRepository` 스텁으로 바꾸고 기존 두 검증(주입한 앱·OS 버전과 토큰이 등록 정보에 담긴다, 토큰 실패 시 등록하지 않는다)을 유지한다
- [ ] T006 [S4] `sources/Projects/Composition/Adapter/Assemblies/MemberAssembly.swift`에서 `registerMemberDevice` 공개 프로퍼티를 제거하고, 필요하면 `memberRepository`를 조립이 넘길 수 있게 공개한다
- [ ] T007 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 `RegisterCurrentDevice` 조립을 T004의 서명에 맞추고 `registerMemberDevice` 공개 프로퍼티를 제거한다
- [ ] T008 [S4] `sources/Projects/Composition/Adapter/Assemblies/AuthenticationAssembly.swift`에서 `verifyAccessToken` 공개 프로퍼티와 `VerifyAccessToken` 생성을 제거한다
- [ ] T009 [S4] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`에서 `verifyAccessToken` 공개 프로퍼티를 제거한다
- [ ] T010 [S4] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 기대 목록에서 `verifyAccessToken`과 `registerMemberDevice`를 제거한다

### 정리

- [ ] T011 [S4] `sources/Projects/Domain/Authentication/UseCases/VerifyAccessToken/VerifyAccessTokenUseCase.swift`, `sources/Projects/Domain/Authentication/UseCases/VerifyAccessToken/VerifyAccessToken.swift`, `sources/Projects/Domain/Tests/Authentication/UseCases/VerifyAccessTokenTests.swift`를 제거하고, 이 파일의 "이관 기록"에 보장 항목의 이관처 또는 제거 근거를 적는다
- [ ] T012 [S4] `sources/Projects/Domain/Member/UseCases/RegisterMemberDevice/RegisterMemberDeviceUseCase.swift`, `sources/Projects/Domain/Member/UseCases/RegisterMemberDevice/RegisterMemberDevice.swift`, `sources/Projects/Domain/Tests/Member/UseCases/RegisterMemberDeviceTests.swift`를 제거하고 같은 절에 이관처를 적는다

### 단위 검증

- [ ] T013 [no-write] [S4] `grep -rn "VerifyAccessTokenUseCase\|RegisterMemberDeviceUseCase" sources/Projects --include='*.swift'` 결과가 비어 있는지 확인한다
- [ ] T014 [no-write] [S4] `Domain`과 `Composition` 테스트 scheme을 실행해 I1을 검증한다

**진행 점검**: T004~T014의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 2 (I2): Domain + Composition + Feature + App — 회원 능력 계약 통합

**분리 불가 근거**: `FetchMemberProfileUseCase`, `UpdateMemberPositionUseCase`, `UpdateMemberCareerLevelUseCase`, `CompleteCurationUseCase` 넷을 `MemberAccountUseCase` 하나로 바꾸면 그 넷을 받는 `MemberAssembly`, `AppComposition`, `MainShellRouterFeature`, `SettingsRouterFeature`, `OnboardingRouterFeature`, `AppRootFeature`, `AppRootView`가 같은 순간 컴파일 실패한다. `MemberMutationSerializer` 제거도 통합 계약이 직렬화를 내부로 가져가는 순간 유일 소비자가 사라지므로 같은 단위에 둔다.

**소유 경로**: `sources/Projects/Domain/Member/**`, `sources/Projects/Composition/Adapter/Assemblies/MemberAssembly.swift`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/Feature/{MainShell,Settings,Onboarding}/Router/**`, `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`, `sources/Projects/App/GitIt/Screens/AppRootView.swift`, 대응 테스트

**관련 변경 시나리오**: S2 S3

**독립 테스트**: 같은 회원 정보를 동시에 두 번 바꾸는 호출이 통합 계약 하나만 써도 순서대로 처리되는지, 그리고 `MemberMutationSerializer`가 사라졌는지 확인한다.

**통합 검증**: `Domain`·`Composition`·`Feature` 테스트 scheme과 `AppTests`, `App` scheme 빌드를 함께 실행한다.

### 테스트

- [ ] T015 [S2] `sources/Projects/Domain/Tests/Member/UseCases/MemberAccountTests.swift`를 만들어 통합 계약의 네 동작과 순서 보장을 검증한다. 이관 대상은 `CompleteCurationTests`, `FetchMemberProfileTests`, `UpdateMemberCareerLevelTests`, `UpdateMemberPositionTests`의 보장 전부이며, 여기에 [data-model.md](./data-model.md) 4절의 순서 보장 규칙 네 가지를 더한다

### 구현 — Domain

- [ ] T016 [S2] [S3] `sources/Projects/Domain/Member/UseCases/MemberAccount/MemberAccountUseCase.swift`에 [contracts/README.md](./contracts/README.md) 1.2의 계약을 정의한다
- [ ] T017 [S2] `sources/Projects/Domain/Member/UseCases/MemberAccount/MemberAccount.swift`에 `actor` 구현을 둔다. `MemberRepository` 하나를 받고, 변경 세 메서드는 키별로 직렬 처리한다. 키는 `"position"`, `"careerLevel"`, `"curation"`으로 통합 전과 같게 둔다

### 구현 — Composition

- [ ] T018 [S3] `sources/Projects/Composition/Adapter/Assemblies/MemberAssembly.swift`의 공개 프로퍼티 `fetchMemberProfile`, `updateMemberPosition`, `updateMemberCareerLevel`, `completeCuration`을 `memberAccount: any MemberAccountUseCase` 하나로 바꾼다
- [ ] T019 [S3] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 같은 네 공개 프로퍼티를 `memberAccount` 하나로 바꾼다
- [ ] T020 [S3] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 기대 목록을 T019의 결과에 맞춘다
- [ ] T021 [S3] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionTests.swift`의 `completeCuration` 사용을 `memberAccount.completeCuration(...)`으로 바꾼다

### 구현 — Feature

- [ ] T022 [S3] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`가 `fetchMemberProfile`·`updateMemberPosition`·`updateMemberCareerLevel` 대신 `memberAccount`를 받고, 하위 Feature에는 각각이 쓰는 동작만 전달하도록 바꾼다
- [ ] T023 [S3] `sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift`를 같은 방식으로 바꾼다
- [ ] T024 [S3] `sources/Projects/Feature/Onboarding/Router/OnboardingRouterFeature.swift`가 `completeCuration` 대신 `memberAccount`를 받고 하위에는 필요한 동작만 전달하도록 바꾼다
- [ ] T025 [S3] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Settings/Router/SettingsRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Onboarding/Router/OnboardingRouterFeatureTests.swift`의 Router 생성 인자를 T022~T024에 맞춘다
- [ ] T026 [S3] `sources/Projects/Feature/Tests/Onboarding/TestDoubles/OnboardingTestSupport.swift`에 `MemberAccountUseCase` test double을 추가하고 Router 생성에 쓰이도록 바꾼다

### 구현 — App

- [ ] T027 [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`가 회원 관련 네 의존성 대신 `memberAccount`를 받고 하위에 전달하도록 바꾼다
- [ ] T028 [S3] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 Noop 조립을 T027에 맞춘다
- [ ] T029 [S3] `sources/Projects/App/GitIt/GitItApp.swift`가 `composition.memberAccount`를 넘기도록 바꾼다
- [ ] T030 [S3] **승인 필요**: `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`와 `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`의 회원 관련 test double을 `MemberAccountUseCase` 하나로 바꾼다. 두 파일에는 사용자 작업 중 변경이 있으므로 아래 "승인이 필요한 지점"의 절차를 따른다

### 정리

- [ ] T031 [S2] `sources/Projects/Domain/Member/UseCases/MemberMutationSerializer.swift`를 제거한다
- [ ] T032 [S4] `sources/Projects/Domain/Member/UseCases/{FetchMemberProfile,UpdateMemberPosition,UpdateMemberCareerLevel,CompleteCuration}/` 네 폴더와 그 안의 프로토콜·구현 파일을 제거한다
- [ ] T033 [S4] `sources/Projects/Domain/Tests/Member/UseCases/{FetchMemberProfileTests,UpdateMemberPositionTests,UpdateMemberCareerLevelTests,CompleteCurationTests}.swift`를 제거하고 이 파일의 "이관 기록"에 각 보장의 이관처를 적는다
- [ ] T034 [S4] `sources/Projects/App/Tests/GitIt/TestDoubles/{NoopFetchMemberProfileUseCase,NoopUpdateMemberPositionUseCase,NoopCompleteCurationUseCase}.swift`와 `sources/Projects/Feature/Tests/Settings/TestDoubles/UpdateMemberPositionUseCaseMock.swift`, `sources/Projects/Feature/Tests/AppEntry/TestDoubles/FetchMemberProfileUseCaseMock.swift`, `sources/Projects/Feature/Tests/Home/TestDoubles/HomeMemberProfileUseCaseMock.swift`, `sources/Projects/Feature/Tests/Onboarding/TestDoubles/CompleteCurationUseCaseMock.swift` 중 말단 Feature가 계속 쓰는 것은 남기고 Router·App만 쓰던 것을 제거한다. 남기고 제거한 근거를 "이관 기록"에 적는다

### 단위 검증

- [ ] T035 [no-write] [S2] `grep -rn "MemberMutationSerializer" sources/Projects --include='*.swift'` 결과가 비어 있는지 확인한다
- [ ] T036 [no-write] [S2] [S3] `Domain`·`Composition`·`Feature` 테스트 scheme과 `AppTests`를 실행하고 `App` scheme 빌드를 확인해 I2를 검증한다

**진행 점검**: T015~T036의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 실행 단위 3 (I3): Domain — 북마크 변경 직렬화 내재화

**단일 패키지 근거**: `SetQuestionBookmarkUseCase` 프로토콜의 메서드 서명은 바뀌지 않는다. 생성자에서 기본값이 있던 `serializer` 인자가 사라질 뿐이고 호출부는 그 인자를 넘기지 않으므로 Domain 밖이 바뀌지 않는다.

**소유 경로**: `sources/Projects/Domain/LearningProject/UseCases/SetQuestionBookmark/**`, `sources/Projects/Domain/Tests/LearningProject/UseCases/SetQuestionBookmarkTests.swift`

**관련 변경 시나리오**: S2

**독립 테스트**: 같은 문제의 북마크 변경을 동시에 두 번 호출했을 때 직렬 처리되는지 Domain 테스트로 확인한다.

**통합 검증**: `Domain` 테스트 scheme을 실행한다.

### 테스트

- [ ] T037 [S2] `sources/Projects/Domain/Tests/LearningProject/UseCases/SetQuestionBookmarkTests.swift`에 [data-model.md](./data-model.md) 4절의 순서 보장 규칙 네 가지를 `questionID` 기준으로 검증하는 테스트를 더한다

### 구현

- [ ] T038 [S2] `sources/Projects/Domain/LearningProject/UseCases/SetQuestionBookmark/SetQuestionBookmark.swift`를 `actor`로 바꾸고 `questionID`별 진행 중 작업 추적을 내부 상태로 둔다. 생성자에서 `serializer` 인자를 제거한다

### 정리

- [ ] T039 [S2] `sources/Projects/Domain/LearningProject/UseCases/SetQuestionBookmark/QuestionMutationSerializer.swift`를 제거한다

### 단위 검증

- [ ] T040 [no-write] [S2] `grep -rn "QuestionMutationSerializer" sources/Projects --include='*.swift'` 결과가 비어 있는지 확인한다
- [ ] T041 [no-write] [S2] `Domain` 테스트 scheme을 실행해 I3을 검증한다

**진행 점검**: T037~T041의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 통합 단위 4 (I4): Domain + Composition + Feature + App — 학습 자료 능력 계약 통합

**분리 불가 근거**: `FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase`, `FetchLearningSetUseCase`, `FetchBookmarkedQuestionsUseCase` 넷을 `LearningLibraryUseCase` 하나로 바꾸면 `LearningProjectAssembly`, `AppComposition`, `MainShellRouterFeature`, `ProjectDetailRouterFeature`, `QuizRouterFeature`, `AppRootFeature`, `AppRootView`가 같은 순간 컴파일 실패한다.

**소유 경로**: `sources/Projects/Domain/LearningProject/UseCases/**`, `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`, `sources/Projects/Composition/App/Assemblies/AppComposition.swift`, `sources/Projects/Feature/{MainShell,ProjectDetail,Quiz}/Router/**`, `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`, `sources/Projects/App/GitIt/Screens/AppRootView.swift`, 대응 테스트

**관련 변경 시나리오**: S3 S4

**독립 테스트**: 통합 계약의 네 동작이 통합 전 각 UseCase와 같은 저장소 호출을 만드는지 Domain 테스트로 확인하고, Router 초기화 인자 개수를 센다.

**통합 검증**: `Domain`·`Composition`·`Feature` 테스트 scheme과 `AppTests`, `App` scheme 빌드를 함께 실행한다.

### 테스트

- [ ] T042 [S3] `sources/Projects/Domain/Tests/LearningProject/UseCases/LearningLibraryTests.swift`를 만들어 네 동작이 각각 대응하는 저장소 메서드를 같은 인자로 호출하고 결과를 그대로 돌려주는지 검증한다. 이관 대상은 `DeleteLearningProjectTests`, `FetchBookmarkedQuestionsTests`, `FetchLearningProjectDetailTests`, `FetchLearningSetTests`의 보장 전부다

### 구현 — Domain

- [ ] T043 [S3] `sources/Projects/Domain/LearningProject/UseCases/LearningLibrary/LearningLibraryUseCase.swift`에 [contracts/README.md](./contracts/README.md) 1.1의 계약을 정의한다
- [ ] T044 [S3] `sources/Projects/Domain/LearningProject/UseCases/LearningLibrary/LearningLibrary.swift`에 구현을 둔다. `LearningProjectRepository`, `LearningSetRepository`, `BookmarkRepository` 셋을 받고 각 메서드는 대응 저장소 메서드를 그대로 호출한다

### 구현 — Composition

- [ ] T045 [S3] `sources/Projects/Composition/Adapter/Assemblies/LearningProjectAssembly.swift`의 공개 프로퍼티 `fetchLearningProjectDetail`, `deleteLearningProject`, `fetchLearningSet`, `fetchBookmarkedQuestions`를 `learningLibrary: any LearningLibraryUseCase` 하나로 바꾼다
- [ ] T046 [S3] `sources/Projects/Composition/App/Assemblies/AppComposition.swift`의 같은 네 공개 프로퍼티를 `learningLibrary` 하나로 바꾼다
- [ ] T047 [S3] `sources/Projects/Composition/Tests/App/Assemblies/AppCompositionPublicSurfaceTests.swift`의 기대 목록을 T046의 결과에 맞추고, `sources/Projects/Composition/Tests/Adapter/Assemblies/LearningProjectAssemblyTests.swift`의 참조를 T045에 맞춘다

### 구현 — Feature

- [ ] T048 [S3] `sources/Projects/Feature/MainShell/Router/MainShellRouterFeature.swift`가 `deleteLearningProject`·`fetchBookmarkedQuestions`·`fetchLearningSet` 대신 `learningLibrary`를 받고, 하위에는 각각이 쓰는 동작만 전달하도록 바꾼다
- [ ] T049 [S3] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift`를 같은 방식으로 바꾼다
- [ ] T050 [S3] `sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift`를 같은 방식으로 바꾼다
- [ ] T051 [S3] `sources/Projects/Feature/Tests/MainShell/Router/MainShellRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/ProjectDetail/Router/ProjectDetailRouterFeatureTests.swift`, `sources/Projects/Feature/Tests/Quiz/Router/QuizRouterFeatureTests.swift`의 Router 생성 인자를 T048~T050에 맞춘다

### 구현 — App

- [ ] T052 [S3] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`가 학습 자료 관련 네 의존성 대신 `learningLibrary`를 받고 하위에 전달하도록 바꾼다
- [ ] T053 [S3] `sources/Projects/App/GitIt/Screens/AppRootView.swift`의 프리뷰 Noop 조립을 T052에 맞추고, `sources/Projects/App/GitIt/GitItApp.swift`가 `composition.learningLibrary`를 넘기도록 바꾼다
- [ ] T054 [S3] **승인 필요**: `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`와 `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`의 학습 자료 관련 test double을 `LearningLibraryUseCase` 하나로 바꾼다. 아래 "승인이 필요한 지점"의 절차를 따른다

### 정리

- [ ] T055 [S4] `sources/Projects/Domain/LearningProject/UseCases/{FetchLearningProjectDetail,DeleteLearningProject,FetchLearningSet,FetchBookmarkedQuestions}/` 네 폴더와 그 안의 프로토콜·구현 파일을 제거한다
- [ ] T056 [S4] `sources/Projects/Domain/Tests/LearningProject/UseCases/{DeleteLearningProjectTests,FetchBookmarkedQuestionsTests,FetchLearningProjectDetailTests,FetchLearningSetTests}.swift`를 제거하고 이 파일의 "이관 기록"에 각 보장의 이관처를 적는다
- [ ] T057 [S4] `sources/Projects/App/Tests/GitIt/TestDoubles/NoopDeleteLearningProjectUseCase.swift`와 `sources/Projects/Feature/Tests/{ProjectDetail/TestDoubles/StubDeleteLearningProjectUseCase,Quiz/TestDoubles/StubFetchLearningSetUseCase}.swift` 중 말단 Feature가 계속 쓰는 것은 남기고 Router·App만 쓰던 것을 제거한다. 근거를 "이관 기록"에 적는다

### 단위 검증

- [ ] T058 [no-write] [S4] [quickstart.md](./quickstart.md) 시나리오 4의 grep 두 개가 모두 비어 있는지 확인한다
- [ ] T059 [no-write] [S3] `Domain`·`Composition`·`Feature` 테스트 scheme과 `AppTests`를 실행하고 `App` scheme 빌드를 확인해 I4를 검증한다

**진행 점검**: T042~T059의 변경 파일과 검증 결과를 보고하고 다음 실행 단위로 계속한다.

---

## 작업 단위 2 (U2): 문서 — 통합 결과와 남은 UseCase 기록

**목표**: 통합 후 남은 UseCase 목록과 각 항목의 존치 근거를 규칙 문서에 남겨, 다음에 UseCase가 늘 때 어디에서 늘었는지 대조할 수 있게 한다.

**선행 조건**: I1~I4의 파일 변경 작업을 모두 완료했다.

**관련 변경 시나리오**: S1 S4

**독립 테스트**: `docs/package-rules/domain.md`에서 시작해 링크만 따라가 각 UseCase의 존치 근거에 도달할 수 있는지 확인한다.

### 구현

- [ ] T060 [S1] [S4] `docs/package-rules/domain.md`에 통합 후 남은 UseCase 목록과 각 항목이 T002의 어느 조건을 충족하는지, 그리고 두 통합 계약(`LearningLibrary`, `MemberAccount`)이 무엇을 담는지 적는다

### 단위 검증

- [ ] T061 [no-write] `docs/package-rules/domain.md`의 목록이 실제 소스의 UseCase 프로토콜 목록과 일치하는지 확인한다

**진행 점검**: T060~T061의 변경 파일과 검증 결과를 보고한다.

---

## 전체 완료 검증

**선행 조건**: U1, I1~I4, U2의 파일 변경 작업을 모두 완료했다.

**커밋 경계**: 아래 `[no-write]` 작업은 U2의 마지막 커밋 단위에 배정한다.

- [ ] T062 [no-write] `make tuist`로 workspace를 갱신하고 실행 전후 Git 상태를 비교해 추적 파일 변경이 없는지 확인한다
- [ ] T063 [no-write] 전체 `build` → `compile` → `test`를 실행하고 결과를 기록한다. `Feature`와 `AppTests`의 기존 실패 목록이 늘지 않았는지로 판정한다
- [ ] T064 [no-write] [S1] [S2] [S3] [S4] [quickstart.md](./quickstart.md)의 시나리오별 검증과 기준선 재측정을 모두 확인하고 값을 이 파일의 "기준선 기록" 절에 적는다
- [ ] T065 [no-write] 이 파일의 "이관 기록"이 제거된 모든 테스트 파일의 이관처 또는 제거 근거를 담고 있는지 확인한다
- [ ] T066 [no-write] [quickstart.md](./quickstart.md)의 수동 회귀 5종(프로젝트 상세와 삭제, 학습 세트 풀이, 북마크 토글, 회원 정보 변경, 온보딩 큐레이션)을 확인하고 결과를 보고한다

---

## 기준선 기록

> T001, T064에서 채운다.

| 항목 | 적용 전 | 적용 후 | 명세 목표 |
| --- | --- | --- | --- |
| 프로덕션 UseCase 파일 수 | 60 | (T064에서 기록) | 46 이하 |
| UseCase 프로토콜 수 | 28 | (T064에서 기록) | 22 이하 |
| `MainShellRouterFeature` Domain 의존성 | 14 | (T064에서 기록) | 11 이하 |
| `AppComposition` Domain 의존성 | 25 | (T064에서 기록) | 19 이하 |

---

## 판정 기록

> T003에서 채운다. [data-model.md](./data-model.md) 2절의 판정과 `docs/package-rules/domain.md`의 기준이 다른 결론을 내는 항목만 적는다.

| 항목 | 문서 기준 판정 | data-model 판정 | 처리 |
| --- | --- | --- | --- |
| 없음 | — | — | 28건 전부 `docs/package-rules/domain.md`의 기준과 data-model 2절이 같은 결론이다 |

---

## 이관 기록

> T011, T012, T033, T034, T056, T057에서 채운다. 제거한 테스트가 보장하던 항목을 왼쪽에, 그 보장을 이어받은 테스트를 오른쪽에 적는다. 이어받을 곳이 없으면 제거 근거를 적는다.

| 옮긴 보장 | 이관처 또는 제거 근거 |
| --- | --- |
| (T011에서 시작) | |

---

## 의존성과 실행 순서

```text
U1 (문서)   분해 기준 확정
  └─> I1 (Domain + Composition)   소비자 없는 UseCase 제거
        └─> I2 (Domain + Composition + Feature + App)   회원 능력 계약 + 직렬화 내재화
              └─> I3 (Domain)   북마크 직렬화 내재화
                    └─> I4 (Domain + Composition + Feature + App)   학습 자료 능력 계약
                          └─> U2 (문서)
                                └─> 전체 완료 검증
```

- U1을 먼저 두는 이유: FR-001의 기준이 I1~I4의 모든 판정 근거다. 기준을 먼저 고정해야 구현 중 판정이 흔들리지 않는다.
- I1을 먼저 두는 이유: 범위가 가장 작고 Feature와 App을 건드리지 않는다. I2와 I4가 만드는 파일에 의존하지 않는다.
- I2를 I3보다 먼저 두는 이유: 직렬화 내재화 방식을 회원 계약에서 먼저 확정하고 검증해야 I3이 같은 방식을 북마크에 적용할 수 있다.
- I4를 마지막 코드 단위로 두는 이유: 영향 범위가 가장 넓다. I1~I3으로 방식이 검증된 뒤에 적용한다.
- U2를 마지막에 두는 이유: 남은 UseCase 목록과 존치 근거는 I1~I4가 끝나야 확정된다.

## 병렬 실행 기회

같은 실행 단위 안에서 서로 다른 파일을 다루는 `[P]` 작업만 병렬로 실행한다. 이 명세의 작업은
대부분 같은 조립·Router 파일을 순차로 고쳐야 해서 `[P]` 표시가 없다. 실행 순서를 바꿔도
되는 조합은 다음과 같다.

- I2: T022, T023, T024는 서로 다른 Router 파일이므로 순서를 바꿔도 된다. 다만 T019 완료 후에만 시작한다.
- I4: T048, T049, T050도 같은 이유로 순서를 바꿔도 된다. T046 완료 후에만 시작한다.

서로 다른 실행 단위와 모든 Git index·commit 작업은 직렬로 실행한다.

## 승인이 필요한 지점

- **T030과 T054**: 두 작업이 고쳐야 하는 `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`와 `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에는 이 명세와 무관한 사용자 작업 중 변경이 있다. 두 파일을 stage하면 그 변경을 함께 소비하게 된다. `/speckit-implement`는 이 두 작업에 도달하면 파일을 고치지 않고 중단해, 사용자에게 (가) 해당 WIP를 먼저 커밋하거나 (나) 두 파일을 이번 단위에 포함해도 좋다는 명시적 승인을 요청한다. 승인 없이 진행하지 않는다.
- **T066의 수동 회귀**: 기기 상태를 쓰는 검증이므로 실행 주체를 확인한 뒤 진행한다.
- **`docs/architecture.md`나 다른 패키지 규칙 문서를 고쳐야 한다고 판단되는 경우**: 이 명세가 수정할 수 있는 문서는 `docs/package-rules/domain.md` 하나다. 다른 규칙 변경은 이 명세의 범위 밖이다.
