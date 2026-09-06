# 데이터 모델: 마이페이지 구현

**입력**: [spec.md](./spec.md)의 핵심 엔터티, [research.md](./research.md)의 결정

## 1. Domain 모델 교정 (Domain 패키지)

### LearningStatistics (필드 교정)

위치: `sources/Projects/Domain/Member/Models/MemberProfile/LearningStatistics.swift`

| 필드(교정 후) | 타입 | 이전 필드 | 설명 |
|---|---|---|---|
| `thisWeekSolvedCount` | `Int` | `totalAnsweredCount` | 이번 주 문제 수 |
| `thisMonthSolvedCount` | `Int` | `totalCorrectCount` | 이번 달 문제 수 |
| `streakDays` | `Int` | (없음, 신규) | 연속 학습일 |
| `weeklyCounts` | `[WeeklyLearningCount]` | `weeklyCounts`(타입 교정) | 요일별 풀이 추이 |

### WeeklyLearningCount (필드 교정)

위치: `sources/Projects/Domain/Member/Models/MemberProfile/WeeklyLearningCount.swift`

| 필드(교정 후) | 타입 | 이전 필드 | 설명 |
|---|---|---|---|
| `dayLabel` | `String` | `weekStartDate: Date` | 요일 라벨(예: "월") — 서버가 날짜가 아닌 요일 라벨을 보낸다 |
| `count` | `Int` | `count`(유지) | 해당 요일 풀이 수 |

### MemberProfile (변경 없음)

`name`, `email`, `position: MemberPosition?`, `careerLevel: CareerLevel?`,
`statistics: LearningStatistics`. (참고: [MemberProfile.swift](../../sources/Projects/Domain/Member/Models/MemberProfile/MemberProfile.swift))

### 서버 계약 (참고, 변경 없음)

`GET /api/v1/members/me`(swagger: `Member/getMemberProfile`) 응답 예시:

```json
{
  "name": "겁없는 SegFault", "email": "tester@example.com",
  "position": "BACKEND", "careerLevel": "JUNIOR",
  "thisWeekSolvedCount": 4, "thisMonthSolvedCount": 5, "streakDays": 3,
  "weeklyChart": [{ "dayLabel": "월", "count": 0 }, ...]
}
```

Data 계층의 `MemberProfileResponseDTO`/`WeeklyChartItemDTO`는 이미 이 형태를 올바르게
디코딩하므로 변경하지 않는다. Composition의 `MemberRepositoryAdapter.fetchProfile()`만
아래처럼 그대로 전달하도록 교정한다(§2).

## 2. Composition 매핑 교정

`sources/Projects/Composition/Adapter/Adapters/MemberRepositoryAdapter.swift`의
`fetchProfile()`이

```swift
statistics: LearningStatistics(
    thisWeekSolvedCount: response.thisWeekSolvedCount,
    thisMonthSolvedCount: response.thisMonthSolvedCount,
    streakDays: response.streakDays,
    weeklyCounts: response.weeklyChart.map {
        WeeklyLearningCount(dayLabel: $0.dayLabel, count: $0.count)
    },
)
```

를 반환하도록 교정한다. 날짜 파싱 시도(`dayFormatter`, private `weeklyCount(from:)`)는
제거한다(더 이상 필요 없음 — 요일 라벨은 문자열 그대로 옮긴다).

## 3. Router 상태 (Feature 패키지, 신규)

### SettingsRouterFeature.State / ActiveScreen

위치: `sources/Projects/Feature/Settings/Router/SettingsRouterFeature.swift`

```swift
struct State {
    var profile = ProfileFeature.State()
    var settings = SettingsFeature.State()
    var activeScreen: ActiveScreen = .profile
}

enum ActiveScreen: Equatable {
    case profile
    case settings(SettingsStep)
}

enum SettingsStep: Equatable {
    case list
    case positionSelection
    case careerLevelSelection
    case accountDeletion
}
```

[TCA Navigation 컨벤션 §2.3](../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)에
따라 `profile`·`settings` child state는 항상 함께 보유하며(뒤로가기 시 재생성하지
않음), `activeScreen`만 전환한다. `ActiveScreen`에 "완료"를 뜻하는 case를 두지 않는다
— 로그아웃/계정 삭제 완료는 `SettingsFeature.Action.Delegate`를 Router가 그대로 상위로
전달한다(기존 배선 유지).

## 4. 신규 표시 모델 (Feature 패키지)

### ProfileDisplay

위치: `sources/Projects/Feature/Settings/Profile/ViewModels/ProfileDisplay.swift`

`ProfileFeature.State`의 프로필 로드 상태를 입력으로 받는 화면 전용 struct
(`HomeProfileDisplay` 패턴 재사용).

| 필드 | 타입 | 파생 규칙 |
|---|---|---|
| `name` | `String?` | 로드 완료 시 `profile.name`, 그 외 `nil` |
| `email` | `String?` | 로드 완료 시 `profile.email`, 그 외 `nil` |
| `positionBadgeText` | `String?` | `position`이 있으면 "iOS"/"Android"/"Back-end"/"Front-end", 없으면 `nil`(배지 숨김) |
| `careerLevelBadgeText` | `String?` | `careerLevel`이 있으면 "입문"/"주니어"/"미들"/"시니어", 없으면 `nil` |
| `thisWeekSolvedCount` | `Int` | 로드 완료 시 `statistics.thisWeekSolvedCount`, 그 외 `0` |
| `thisMonthSolvedCount` | `Int` | 로드 완료 시 `statistics.thisMonthSolvedCount`, 그 외 `0` |
| `streakDays` | `Int` | 로드 완료 시 `statistics.streakDays`, 그 외 `0` |
| `weeklyCounts` | `[WeeklyLearningCount]` | 로드 완료 시 `statistics.weeklyCounts`, 그 외 `[]` |
| `isLoading` / `isFailed` | `Bool` | 로딩/실패 상태 |

### SettingsScreen 표시 값 (설정 목록)

설정 화면은 별도 표시 모델 없이 `SettingsFeature.State.profile?.position`/`careerLevel`을
직접 문구로 변환한다(직군·연차 미설정 시 "선택 안 함" — FR-006a). 매핑 함수는
`SettingsScreen` 파일 안에 `private static func`로 둔다(온보딩·`HomeProfileDisplay`와
마찬가지로 화면별 독립 매핑 — [research.md §5](./research.md#5-직군연차-선택-화면--selectioncardlist-재사용) 참고).

### 개발 분야·개발 수준 선택 화면 표시 값

`MemberPosition.allCases`/`CareerLevel.allCases`를 순회하며
`SelectionCardList.Item`(`id`, `title`, `supportingText`(연차만), `isSelected`)을 화면이
직접 구성한다. 온보딩의 `PositionSelectionScreen.Display`/`CareerSelectionScreen.Display`와
동일한 문구·순서(`Front-end, Back-end, iOS, Android` / `입문, 주니어, 미들, 시니어`)를
설정 화면 전용 `Display` enum에 다시 정의한다(재사용하지 않고 각자 소유 — research.md §5).

## 5. 상태 전이 (SettingsFeature, 변경 없음)

| 상태 | 값 | 화면 표시 |
|---|---|---|
| `profileLoad` | `idle` → `loading` → `loaded(MemberProfile)` \| `failed(MemberError)` | 설정 목록의 개발 분야/수준 현재 값 표시에 사용 |
| `positionMutation`/`careerLevelMutation` | `idle` → `committing` → `idle` \| `failed(MemberError)` | 선택 화면에서 선택 시 committing, 실패 시 이전 값 유지 + 오류 표시 |
| `accountAction` | `idle` → `signingOut` \| `confirmingDeletion` → `deletingAccount` → (delegate) \| `failed(MemberError)` | `confirmingDeletion`이 계정 삭제 확인 화면의 표시 조건 |

## 6. FR-014 제외 범위

"세트 생성 완료 알림" 항목은 이번 데이터 모델에 포함하지 않는다. 필요한 Domain 계약은
후속 명세에서 별도로 설계한다.
