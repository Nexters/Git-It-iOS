# 데이터 모델: 홈 화면과 MainShell 4탭 통합

## 1. 범위

이 기능은 Domain 모델이나 저장 스키마를 추가하지 않는다. 기존 `MemberProfile`,
`LearningProjectPage`, `LearningProjectSummary`를 source of truth로 사용하고 Home의
TCA presentation State, 파생 표시 값, navigation intent만 설계한다.

## 2. 기존 Domain 입력

### `MemberProfile`

| 필드 | 사용 | 규칙 |
|---|---|---|
| `name: String` | 프로필 주 표시 | 임의 대체 이름을 만들지 않음 |
| `position: MemberPosition?` | 선택적 보조 표시 | nil은 문구를 만들지 않음 |
| `careerLevel: CareerLevel?` | 선택적 보조 표시 | nil은 문구를 만들지 않음 |
| `email`, `statistics` | Home에서 표시하지 않음 | State에 있는 Domain payload의 일부로만 보존 |

### `LearningProjectPage`

| 필드 | 사용 | 규칙 |
|---|---|---|
| `items` | Home 카드 목록 | 순서를 변경하지 않고 전부 표시 |
| `hasNext` | 응답 payload로 보존 가능 | 추가 조회를 시작하지 않음 |

### `LearningProjectSummary`

| 필드 | 표시·동작 변환 |
|---|---|
| `projectID` | 카드 식별과 ProjectDetail intent |
| `repositoryName` | 카드 title |
| `techStack` | 순서를 유지해 사용자 구분자로 조합 |
| `currentSetLabel` | 파싱 없이 카드 set label로 사용 |
| `currentSetTitle` | 카드 set title |
| `overallProgressPercent` | `Double(percent) / 100` 표시 값. 최종 범위는 UIComponent가 clamp |
| `nextSetID`, `nextQuestionID` | 둘 다 non-nil일 때만 학습 intent 활성 |

## 3. `HomeFeature.State`

```text
HomeFeature.State
├── profileLoad: ProfileLoad
├── projectLoad: ProjectLoad
├── profileRequestID: Int
└── projectRequestID: Int
```

State는 Use Case, closure, scroll offset, 카드 각도, 표시 문자열 wrapper를 저장하지
않는다. 표시 값은 Domain payload에서 계산하고 스크롤 표현은 View 좌표에서 계산한다.

### `ProfileLoad`

```swift
enum ProfileLoad: Equatable, Sendable {
    case idle
    case loading
    case loaded(MemberProfile)
    case failed(MemberError)
}
```

### `ProjectLoad`

```swift
enum ProjectLoad: Equatable, Sendable {
    case idle
    case loading
    case loaded(LearningProjectPage)
    case failed(LearningProjectError)
}
```

`loaded([])`와 `failed`는 State로 구분된다. 단, HomeScreen의 프로젝트 영역은 두 상태를
동일한 빈 상태로 변환한다.

## 4. 상태 전이

### 최초 Home 표시

```text
profileLoad == idle  ─┐
                      ├─ task → loading → loaded(profile) | failed(error)
projectLoad == idle  ─┘           → loading → loaded(page)    | failed(error)
```

- 두 operation은 독립 Effect로 시작한다.
- 동일 `.task`가 다시 들어와도 `.idle`이 아닌 영역은 요청하지 않는다.
- 한 영역의 완료는 다른 영역의 State를 변경하지 않는다.

### 프로필 재시도

```text
failed(error) ── retryTapped → loading → loaded(profile) | failed(error)
```

- retry는 `profileRequestID`만 증가시킨다.
- 이전 프로필 Effect를 취소하고 늦은 응답을 request ID로 거부한다.
- `projectLoad`와 `projectRequestID`는 변경하지 않는다.

### 실패 표시

| 프로필 | 프로젝트 | 표시 |
|---|---|---|
| failed | loaded(non-empty) | 헤더 오류·재시도 + 카드 보존 |
| loaded | failed | 프로필 보존 + 빈 프로젝트 표현 |
| failed | failed | 헤더 오류·재시도 + 빈 프로젝트 표현 |

## 5. 파생 표시 모델

별도 저장 State로 두지 않고 `HomeScreen.Display`의 순수 변환으로 생성한다.

### 프로필 보조 문구

| `position` | `careerLevel` | 결과 |
|---|---|---|
| value | value | `positionTitle · careerTitle` |
| value | nil | `positionTitle` |
| nil | value | `careerTitle` |
| nil | nil | nil; 이름만 표시 |

`MemberPosition`과 `CareerLevel`의 한국어 표시 용어는 기존 Onboarding 표시와 일치시킨다.

### 카드 표시

```text
index + LearningProjectSummary
├── title = repositoryName
├── technologies = techStack.joined(separator: 확정된 UI 구분자)
├── progress = Double(overallProgressPercent) / 100
├── currentSetLabel = currentSetLabel
├── setTitle = currentSetTitle
├── variant = HomeProjectCard.Variant(index: index)
└── isLearningEnabled = nextSetID != nil && nextQuestionID != nil
```

## 6. Navigation intent

```swift
enum HomeFeature.Delegate: Equatable, Sendable {
    case projectRegistrationRequested
    case projectDetailRequested(projectID: String)
    case learningRequested(
        projectID: String,
        nextSetID: String,
        nextQuestionID: String
    )
}
```

- `projectRegistrationRequested`는 빈 상태와 프로젝트 있음 상태의 동일 CTA가 발생시킨다.
- `projectDetailRequested`는 재생 control 밖의 카드 본문이 발생시킨다.
- `learningRequested`는 세 ID가 모두 Domain에 존재할 때만 생성한다.
- `showAllProjectsTapped`는 MainShell 내부 탭 전이로 해석하므로 App delegate가 아니다.

## 7. `HomeCardScrollLayout`

```text
입력: p0CenterX, cardStride, cardCenterX
앵커: P0 = p0CenterX, P1 = P0 + stride, P2 = P1 + stride
각도: A0 = 0, A1 = 16, A2 = -12
출력: cardCenterX에 대한 Double 각도
```

불변식:

1. `angle(P0) == 0`, `angle(P1) == 16`, `angle(P2) == -12`.
2. `[P0, P1]`, `[P1, P2]`에서 연속인 선형 함수다.
3. `x < P0`는 `0`, `x > P2`는 `-12`로 clamp한다.
4. 프로젝트 index와 variant는 입력이 아니다.
5. `cardStride > 0`은 layout이 보장하며, 순수 함수는 0 이하의 값에 대해
   안전한 단일 각도를 반환하거나 precondition을 명시한다.

## 8. MainShell 상태 변경

```text
MainShellFeature.State
├── selectedTab = .home
├── home = HomeFeature.State()
├── projectList = ProjectListFeature.State()
├── saved = SavedFeature.State()
└── settings = SettingsFeature.State()
```

탭 전환은 child State를 재생성하지 않는다. 로그아웃·계정 삭제에서는 네 child State와
`selectedTab`을 새 `MainShellFeature.State()`로 함께 초기화한다.
