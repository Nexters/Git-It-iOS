# 조사: Domain UseCase 분해 기준 확정과 통합

[명세](./spec.md)가 남긴 판단 지점과 계획 수립 중 확인이 필요했던 항목의 결정을 기록한다.

## 1. `VerifyAccessToken`을 통합 계약에 넣지 않고 제거한다

**결정**: `DomainAuthentication`에는 능력 단위 통합 계약을 만들지 않는다.
`VerifyAccessTokenUseCase`와 `VerifyAccessToken`을 제거하고, 그 동작이 필요해지면
`LoginSessionRepository.verifyAccessToken()`을 호출하는 쪽이 직접 쓴다.

**근거**: 프로덕션 소스에서 이 UseCase를 호출하는 곳이 없다. `AuthenticationAssembly`가
만들고 `AppComposition`이 공개하지만 Feature도 App도 쓰지 않는다. 소비자가 없는 계약을
이름만 바꿔 유지하면 통합의 목적인 "저장소 계약을 한 번 더 복제하지 않는다"에 어긋난다.

**검토한 대안**: 메서드 하나짜리 `DomainAuthentication` 능력 계약을 만드는 안. 근거 문서
FR-2가 "토큰 검증"을 통합 대상으로 지목하지만, 통합할 다른 동작이 없어 이름만 바뀐다.

## 2. `RegisterMemberDevice`를 `RegisterCurrentDevice` 안으로 흡수한다

**결정**: `RegisterMemberDeviceUseCase`와 `RegisterMemberDevice`를 제거하고,
`RegisterCurrentDevice`가 `MemberRepository`를 직접 받아 기기 등록을 수행한다.

**근거**: 이 UseCase의 유일한 프로덕션 소비자는 같은 Domain 모듈의 `RegisterCurrentDevice`다.
`RegisterCurrentDevice`는 deviceID 계약과 기기 등록을 조합하므로 기준을 충족해 독립
유지 대상이지만, 그 안에서 한 번 더 UseCase를 거칠 이유가 없다. `AppComposition`이
`registerMemberDevice`를 공개하는 것도 소비자가 없는 표면이다.

**검토한 대안**: `MemberAccount` 통합 계약에 기기 등록 메서드를 넣는 안. 기기 등록은 화면이
호출하는 회원 정보 조작이 아니라 기동 절차의 일부이므로 성격이 다르다.

## 3. `DomainLearningProject` 통합 계약은 `LearningLibrary`로 둔다

**결정**: `DeleteLearningProject`, `FetchLearningProjectDetail`, `FetchLearningSet`,
`FetchBookmarkedQuestions` 넷을 `LearningLibraryUseCase` 하나로 통합한다.

```text
func project(id: String) async throws -> LearningProjectDetail
func deleteProject(id: String) async throws
func learningSet(projectID: String, setID: String) async throws -> LearningSet
func bookmarkedQuestions(...) async throws -> ...
```

**근거**: 넷 모두 저장소 호출을 그대로 돌려주며 판단·조율·보상·동시성 제어가 없고 계약을
하나씩만 쓴다. 넷이 다루는 대상은 "이미 만들어진 학습 자료를 꺼내고 치우는 일"로 하나의
도메인 능력이다. `LearningLibrary`는 공급자·저장 기술 용어를 쓰지 않고 그 능력을 가리킨다.

**검토한 대안**: 조회 계약과 삭제 계약을 나누는 안. 삭제 하나만 담은 계약이 다시 위임
전용이 되어 같은 문제가 반복된다.

## 4. `DomainMember` 통합 계약은 `MemberAccount`로 두고 조회와 변경을 함께 담는다

**결정**: `FetchMemberProfile`, `UpdateMemberPosition`, `UpdateMemberCareerLevel`,
`CompleteCuration` 넷을 `MemberAccountUseCase` 하나로 통합한다.

```text
func profile() async throws -> MemberProfile
func updatePosition(_ position: MemberPosition) async throws
func updateCareerLevel(_ careerLevel: CareerLevel) async throws
func completeCuration(position: MemberPosition, careerLevel: CareerLevel) async throws
```

**근거**: 넷 모두 같은 `MemberRepository` 하나만 쓰고 판단이 없다. 변경 세 연산은 명세
FR-005가 요구하는 대로 한 계약으로 묶여야 하고, 조회를 같은 계약에 두면 화면이 회원 정보를
다루는 진입점이 하나가 된다.

**검토한 대안**: 조회 계약과 변경 계약을 나누는 안. 조회가 다시 메서드 하나짜리 위임 전용
계약이 되고, 주입 표면도 하나 더 늘어난다.

## 5. 직렬화는 별도 타입 대신 구현 actor의 내부 상태로 옮긴다

**결정**: `MemberAccount`와 `SetQuestionBookmark`를 `actor`로 구현하고, 진행 중 작업을
키별로 추적하는 상태를 그 actor의 private 프로퍼티로 둔다. `MemberMutationSerializer`와
`QuestionMutationSerializer`를 제거한다.

**근거**: 직렬화는 그 계약이 지켜야 할 보장이지 호출자가 챙길 준비물이 아니다. actor 내부
상태로 두면 계약을 쓰는 쪽이 아무것도 하지 않아도 보장이 성립하고, 새 변경 연산을 추가할
때 별도 타입을 함께 쓰는 것을 잊어 보장이 조용히 깨지는 경로가 사라진다.

**검토한 대안**: 직렬화 타입을 유지하고 구현이 기본값으로 갖게 하는 현재 방식. 지금이 그
방식이고, 보장이 계약 밖에 남는다는 문제가 그대로다.

## 6. 명세 032가 추가한 세 UseCase는 모두 독립 유지한다

| UseCase | 기준 충족 근거 |
| --- | --- |
| `ResolveSessionAvailability` | 마커 계약과 저장 세션 계약 둘을 조합하고, 만료 시각 비교라는 판단을 수행한다 |
| `RegisterCurrentDevice` | deviceID 계약, 회원 저장소, 푸시 토큰 제공자를 조합한다 |
| `ScheduleGenerationReminder` | 대상 집합 관리, 완료 판정, 권한 확인, 예약 시각 계산을 수행하고 두 계약을 조합한다 |

**근거**: 셋 다 저장소 호출 외의 판단 또는 둘 이상의 계약 조합이라는 기준을 충족한다.

## 7. 다중 메서드 계약은 기준 위반이 아니다

**결정**: `PolicyConsentUseCase`(메서드 5개)와 `RequestGenerationReminderUseCase`(3개)를
위반으로 보지 않고 능력 단위 계약의 선례로 인정한다.

**근거**: 확정하는 기준은 "1 UseCase = 1 동작"이 아니라 "판단·조율·보상·동시성 제어를
수행하는가 또는 둘 이상의 계약을 조합하는가"다. `PolicyConsent`는 저장된 동의 기록과 필요
문서를 비교해 유효성을 판정하고, `RequestGenerationReminder`는 권한 상태에 따라 예약
등록 여부를 가른다. 둘 다 판단을 수행한다. 이 명세가 만드는 `LearningLibrary`와
`MemberAccount`도 같은 형태다.

## 8. 통합 계약은 조립과 상위 Router까지만 쓰고 하위 Feature에는 필요한 동작만 전달한다

**결정**: `AppComposition`과 Router Feature는 통합 계약을 그대로 받는다. Router가 하위
Feature에 넘길 때는 하위가 실제로 쓰는 동작만 지금과 같은 형태로 전달한다.

**근거**: [Feature 패키지 규칙](../../docs/package-rules/feature.md)은 하위가 사용하는 최소
범위만 전달하도록 요구한다. 네 개 동작을 담은 계약을 한 동작만 쓰는 하위 화면에 통째로
넘기면 이 제약을 우회하게 된다. 명세 FR-010이 이를 명시한다.

**영향**: 주입 표면 축소는 `AppComposition`과 Router 초기화 인자에서 일어나고, 말단 화면
Feature의 의존성 개수는 거의 그대로다. 명세의 "수치 목표 조정" 절이 이 결과를 전제한다.

**검토한 대안**: 하위 Feature도 통합 계약을 받게 하는 안. 초기화 인자는 더 줄지만 Feature
규칙을 어기고, 화면이 쓰지 않는 능력에 접근할 수 있게 된다.

## 9. 도달 가능한 수치

| 항목 | 현재 | 이 계획 적용 후 | 명세 목표 |
| --- | --- | --- | --- |
| UseCase 프로토콜 | 28 | 20 | 22 이하 |
| 프로덕션 UseCase 파일 | 60 | 42 | 46 이하 |
| `MainShellRouterFeature` Domain 의존성 | 14 | 10 | 11 이하 |
| `AppComposition` Domain 의존성 | 25 | 17 | 19 이하 |

제거 10개(`VerifyAccessToken`, `RegisterMemberDevice`, LearningProject 위임 4개, Member
조회·변경 4개), 신설 2개(`LearningLibrary`, `MemberAccount`), 직렬화 타입 2개 제거다.
