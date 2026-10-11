# 데이터 모델: Domain UseCase 분해 기준 확정과 통합

이 명세는 Domain 모델 타입과 오류 타입을 바꾸지 않는다. 바뀌는 것은 동작을 담는 계약의
경계와 그 계약이 소유하는 상태다.

## 1. 분해 기준

| 입력 | 값 |
| --- | --- |
| 저장소 호출 외 판단·조율·보상·동시성 제어 수행 | 예 / 아니오 |
| 조합하는 계약 수 | 1 / 2 이상 |

둘 중 하나라도 "예" 또는 "2 이상"이면 독립 타입으로 둔다. 둘 다 아니면 소유 모듈의 능력
단위 계약으로 통합한다.

## 2. 현재 UseCase 판정 결과

### 2.1 독립 유지 (18개)

| 모듈 | UseCase | 충족 근거 |
| --- | --- | --- |
| Authentication | `SignIn` | 인증 저장소와 세션 저장소 조율, 실패 시 보상 |
| Authentication | `SignOut` | 두 저장소 조율, 실패 시 보상 |
| Authentication | `RestoreSession` | 두 저장소 조율, 복원 결과 판정 |
| Authentication | `RefreshSession` | 단일 비행 동시성 제어 |
| Authentication | `VerifyAuthorization` | 두 계약 조합, 재인증 필요 시 세션 정리 |
| Authentication | `PolicyConsent` | 저장 기록과 필요 문서를 비교해 유효성 판정 |
| Authentication | `ResolveSessionAvailability` | 마커·저장 세션 두 계약 조합, 만료 판단 |
| LearningProject | `FetchLearningProjects` | 조회 결과에 따라 생성 추적을 갱신하는 조건부 효과 |
| LearningProject | `CreateLearningProject` | 등록과 생성 추적 시작의 상태 수명 관리 |
| LearningProject | `FetchExternalRepository` | URL 파싱 사전 검증 후 조회 |
| LearningProject | `SubmitChoiceAnswer` | 제출 전 사전 검증 |
| LearningProject | `SubmitEssayAnswer` | 제출 전 사전 검증 |
| LearningProject | `SetQuestionBookmark` | 같은 문제에 대한 동시 변경 직렬화 |
| LearningProject | `TrackGeneration` | 생성 상태 수명과 관측자 관리 |
| LearningProject | `RequestGenerationReminder` | 권한 상태에 따라 등록 여부 판정 |
| LearningProject | `ScheduleGenerationReminder` | 대상 집합 관리, 완료 판정, 예약 시각 계산 |
| Member | `DeleteMemberAccount` | 탈퇴와 로컬 상태 정리 조율 |
| Member | `RegisterCurrentDevice` | deviceID 계약·회원 저장소·토큰 제공자 조합 |

### 2.2 통합 대상 (8개 → 2개)

| 모듈 | 기존 UseCase | 통합 후 |
| --- | --- | --- |
| LearningProject | `FetchLearningProjectDetail` | `LearningLibrary.project(id:)` |
| LearningProject | `DeleteLearningProject` | `LearningLibrary.deleteProject(id:)` |
| LearningProject | `FetchLearningSet` | `LearningLibrary.learningSet(projectID:setID:)` |
| LearningProject | `FetchBookmarkedQuestions` | `LearningLibrary.bookmarkedQuestions(projectID:)` |
| Member | `FetchMemberProfile` | `MemberAccount.profile()` |
| Member | `UpdateMemberPosition` | `MemberAccount.updatePosition(_:)` |
| Member | `UpdateMemberCareerLevel` | `MemberAccount.updateCareerLevel(_:)` |
| Member | `CompleteCuration` | `MemberAccount.completeCuration(position:careerLevel:)` |

### 2.3 제거 대상 (2개)

| 모듈 | UseCase | 근거 |
| --- | --- | --- |
| Authentication | `VerifyAccessToken` | 프로덕션 소비자 없음 |
| Member | `RegisterMemberDevice` | 유일 소비자 `RegisterCurrentDevice`가 저장소를 직접 받음 |

## 3. 계약이 소유하는 상태

### 3.1 `MemberAccount`

| 상태 | 설명 |
| --- | --- |
| 진행 중 변경 | 키 → 진행 중 작업. 같은 키의 다음 호출은 앞 호출이 끝난 뒤 시작한다 |

키 값은 통합 전과 같다: `"position"`, `"careerLevel"`, `"curation"`.

### 3.2 `SetQuestionBookmark`

| 상태 | 설명 |
| --- | --- |
| 진행 중 변경 | `questionID` → 진행 중 작업. 같은 문제의 다음 호출은 앞 호출이 끝난 뒤 시작한다 |

키 값은 통합 전과 같은 `questionID`다.

## 4. 순서 보장 규칙

1. 같은 키의 두 호출은 시작 순서대로 처리한다.
2. 앞 호출이 실패해도 뒤 호출은 실행한다. 실패는 각 호출자에게 그대로 전달한다.
3. 다른 키의 호출은 서로 기다리지 않는다.
4. 호출이 끝나 더 이상 대기가 없으면 그 키의 추적 항목을 제거한다.

네 규칙은 통합 전 `MemberMutationSerializer`와 `QuestionMutationSerializer`가 제공하던
보장과 같다.
