# 계약: Domain UseCase 분해 기준 확정과 통합

이 명세가 바꾸는 공개 계약이다. 저장소 계약(`Domain/*/Contracts/**`)과 Domain↔Data
Adapter는 바뀌지 않는다([명세](./../spec.md) FR-013).

## 1. 신설 계약

### 1.1 `LearningLibraryUseCase` — `DomainLearningProject`

```text
public protocol LearningLibraryUseCase: Sendable {
    func project(id: String) async throws -> LearningProjectDetail
    func deleteProject(id: String) async throws
    func learningSet(projectID: String, setID: String) async throws -> LearningSet
    func bookmarkedQuestions(projectID: String?) async throws -> BookmarkedQuestionCollection
}
```

구현 `LearningLibrary`는 `LearningProjectRepository`, `LearningSetRepository`,
`BookmarkRepository` 셋을 받는다. 각 메서드는 대응하는 저장소 메서드를 그대로 호출한다.

흡수하는 기존 계약: `FetchLearningProjectDetailUseCase`, `DeleteLearningProjectUseCase`,
`FetchLearningSetUseCase`, `FetchBookmarkedQuestionsUseCase`.

### 1.2 `MemberAccountUseCase` — `DomainMember`

```text
public protocol MemberAccountUseCase: Sendable {
    func profile() async throws -> MemberProfile
    func updatePosition(_ position: MemberPosition) async throws
    func updateCareerLevel(_ careerLevel: CareerLevel) async throws
    func completeCuration(position: MemberPosition, careerLevel: CareerLevel) async throws
}
```

구현 `MemberAccount`는 `actor`이며 `MemberRepository` 하나를 받는다. 변경 세 메서드는
키별로 직렬 처리한다. 키는 통합 전 `MemberMutationSerializer`가 쓰던 값과 같게
`"position"`, `"careerLevel"`, `"curation"`으로 둔다.

흡수하는 기존 계약: `FetchMemberProfileUseCase`, `UpdateMemberPositionUseCase`,
`UpdateMemberCareerLevelUseCase`, `CompleteCurationUseCase`.

## 2. 제거되는 계약

| 제거 대상 | 처리 |
| --- | --- |
| `VerifyAccessTokenUseCase`, `VerifyAccessToken` | 프로덕션 소비자가 없어 제거. `LoginSessionRepository.verifyAccessToken()`은 그대로 남는다 |
| `RegisterMemberDeviceUseCase`, `RegisterMemberDevice` | `RegisterCurrentDevice`가 `MemberRepository`를 직접 받아 흡수 |
| `FetchLearningProjectDetailUseCase` 외 LearningProject 위임 3개 | 1.1로 흡수 |
| `FetchMemberProfileUseCase` 외 Member 위임·변경 3개 | 1.2로 흡수 |
| `MemberMutationSerializer` | 1.2 구현의 내부 상태로 흡수 |
| `QuestionMutationSerializer` | `SetQuestionBookmark`의 내부 상태로 흡수 |

## 3. 서명이 바뀌는 기존 타입

### 3.1 `RegisterCurrentDevice` — `DomainMember`

```text
public init(
    memberRepository: any MemberRepository,          // registerMemberDevice: any RegisterMemberDeviceUseCase 대체
    deviceIdentifierRepository: any DeviceIdentifierRepository,
    appVersion: String,
    osVersion: String,
    deviceTokenProvider: @escaping @Sendable () async throws -> String,
)
```

### 3.2 `SetQuestionBookmark` — `DomainLearningProject`

```text
public actor SetQuestionBookmark: SetQuestionBookmarkUseCase {
    public init(repository: any BookmarkRepository)   // serializer 인자 제거
}
```

`SetQuestionBookmarkUseCase` 프로토콜의 메서드 서명은 바뀌지 않는다.

## 4. 조립 표면 변화

### 4.1 `LearningProjectAssembly` — Composition

공개 프로퍼티 `fetchLearningProjectDetail`, `deleteLearningProject`, `fetchLearningSet`,
`fetchBookmarkedQuestions` 넷이 `learningLibrary: any LearningLibraryUseCase` 하나로 바뀐다.

### 4.2 `MemberAssembly` — Composition

`fetchMemberProfile`, `updateMemberPosition`, `updateMemberCareerLevel`, `completeCuration`,
`registerMemberDevice` 다섯이 `memberAccount: any MemberAccountUseCase` 하나로 바뀐다.
`registerCurrentDevice` 조립은 `AppComposition`이 계속 소유하며 `MemberRepository`를 받는다.

### 4.3 `AuthenticationAssembly` — Composition

`verifyAccessToken` 공개 프로퍼티가 사라진다.

### 4.4 `AppComposition` — Composition

| 사라지는 공개 프로퍼티 | 새 공개 프로퍼티 |
| --- | --- |
| `fetchLearningProjectDetail`, `deleteLearningProject`, `fetchLearningSet`, `fetchBookmarkedQuestions` | `learningLibrary` |
| `fetchMemberProfile`, `updateMemberPosition`, `updateMemberCareerLevel`, `completeCuration` | `memberAccount` |
| `verifyAccessToken`, `registerMemberDevice` | (없음) |

Domain 의존성 공개 개수: 25 → 17.

## 5. Feature 초기화 인자 변화

상위 Router는 통합 계약을 받고, 하위 Feature에는 그 하위가 쓰는 동작만 전달한다
([research.md](./../research.md) 8절).

| Feature | 변화 |
| --- | --- |
| `MainShellRouterFeature` | Domain 의존성 14 → 10. `deleteLearningProject`·`fetchBookmarkedQuestions`·`fetchLearningSet`가 `learningLibrary`로, `fetchMemberProfile`·`updateMemberPosition`·`updateMemberCareerLevel`이 `memberAccount`로 합쳐진다 |
| `ProjectDetailRouterFeature` | `fetchLearningProjectDetail`·`deleteLearningProject`·`fetchLearningSet`·`fetchBookmarkedQuestions`가 `learningLibrary` 하나로 |
| `QuizRouterFeature` | `fetchLearningSet`·`fetchBookmarkedQuestions`가 `learningLibrary` 하나로 |
| `SettingsRouterFeature` | `fetchMemberProfile`·`updateMemberPosition`·`updateMemberCareerLevel`이 `memberAccount` 하나로 |
| `OnboardingRouterFeature` | `completeCuration`이 `memberAccount`로 |
| 말단 화면 Feature | 지금과 같은 동작 단위 의존성을 유지한다. Router가 통합 계약에서 필요한 동작만 뽑아 전달한다 |
