# Home Feature 계약

## 1. 생성 경계

```swift
HomeFeature(
    fetchLearningProjects: any FetchLearningProjectsUseCase,
    fetchMemberProfile: any FetchMemberProfileUseCase
)
```

- production 의존성은 initializer로만 받는다.
- View는 Use Case를 직접 호출하지 않는다.
- Home은 Data·Infrastructure·Composition을 import하지 않는다.

## 2. Action 계약

### View Action

| Action | 전제 | 결과 |
|---|---|---|
| `task` | 화면 표시 | `.idle`인 조회만 각 1회 시작 |
| `profileRetryTapped` | `profileLoad == .failed` | 프로필 Effect만 교체 |
| `projectRegistrationTapped` | CTA 표시 | 등록 delegate 1회 |
| `showAllProjectsTapped` | 프로젝트 section 표시 | MainShell이 project 탭으로 전환 |
| `projectCardTapped(projectID:)` | 카드 본문 tap | 상세 delegate 1회 |
| `learningTapped(projectID:)` | 재생 control tap | ID 유효 시 학습 delegate 1회, 아니면 0회 |

### Effect Event

```swift
case profileLoadFinished(
    requestID: Int,
    result: Result<MemberProfile, MemberError>
)
case projectsLoadFinished(
    requestID: Int,
    result: Result<LearningProjectPage, LearningProjectError>
)
```

이벤트의 request ID가 현재 영역의 ID와 다르면 State와 delegate를 변경하지 않는다.

### Delegate

```swift
case projectRegistrationRequested
case projectDetailRequested(projectID: String)
case learningRequested(
    projectID: String,
    nextSetID: String,
    nextQuestionID: String
)
```

delegate는 의도만 전달하며 destination을 생성하거나 App route를 변경하지 않는다.

## 3. 조회 계약

1. Home의 최초 `task`는 profile/project Use Case를 각각 최대 1회 시작한다.
2. 다른 탭에서 복귀한 `task`는 loaded·failed 상태를 재조회하지 않는다.
3. 프로필 재시도 1회당 프로필 Use Case만 최대 1회 호출한다.
4. 프로젝트 실패는 자동·수동 추가 조회를 시작하지 않는다.
5. `hasNext == true`를 페이지네이션 신호로 사용하지 않는다.

## 4. 렌더링 계약

모든 정상·빈·실패 표현은 프로필 헤더, `Hello World`, `Let’s Git -it-!`,
프로젝트 등록 CTA, `학습 중인 레포지토리`, `전체 보기`를 공통으로 제공한다.
단, loading 중에는 성공 0개를 의미하는 빈 illustration과 문구를 표시하지 않는다.

| 영역 | State | 표시 |
|---|---|---|
| profile | idle/loading | 빈 프로필로 오인하지 않는 loading |
| profile | loaded | 기본 avatar, 이름, 존재하는 분야·경력만 표시 |
| profile | failed | 헤더 내 error와 프로필 전용 retry |
| project | idle/loading | 빈 상태 문구를 표시하지 않는 loading |
| project | loaded(non-empty) | Domain 순서의 모든 카드 |
| project | loaded(empty) | 빈 illustration·문구·등록 CTA |
| project | failed | loaded(empty)와 동일한 표시, error·retry 없음 |

## 5. 테스트 불변식

- 교차 실패에서 성공한 다른 영역 payload의 손실은 0건이다.
- stale 응답이 현재 State를 변경하는 건수는 0건이다.
- 무효한 학습 ID에서 임의 ID 생성과 delegate는 0건이다.
- 카드 본문·재생 선택은 한 번의 입력당 서로 다른 delegate를 각각 정확히
  1회만 발생시킨다.
