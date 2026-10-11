# 구현 계획: 마이페이지 구현

**Git-flow 유형**: `feature`

**브랜치**: `feature/my-page`

**날짜**: 2026-09-04(재계획) | **명세**: [spec.md](./spec.md)

**입력**: `/specs/026-my-page/spec.md`의 기능 명세

## 요약

`/speckit-implement` 착수 중 Figma 참조 노드(`4393:6038`)를 재조회해 "마이" 탭이 화면
하나가 아니라 **프로필 화면(신규) + 설정 화면(기존 `SettingsFeature` 재사용) + 설정
하위 선택/확인 화면 3개**로 구성됨을 확인했다(spec.md 명확화 참고). 이에 따라 계획을
다음과 같이 재작성한다.

- `Feature/Settings/` 흐름에 `Router/`(신규)와 `Profile/`(신규)를 추가하고, 기존
  `Settings/Settings/SettingsFeature.swift`는 그대로 재사용하되 화면을 신규 구현한다.
  [TCA Navigation 컨벤션 §2.3](../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)의
  **순차 흐름** 패턴에 따라, Router의 State가 `profile: ProfileFeature.State`와
  `settings: SettingsFeature.State`를 항상 함께 보유하고, 활성 화면 값(`ActiveScreen`)이
  `.profile`과 `.settings(SettingsStep)`(list/positionSelection/careerLevelSelection/
  accountDeletion) 사이를 전환한다.
- 프로필 화면의 통계 카드(이번 주/이번 달/연속 학습)는 서버 `GET /api/v1/members/me`가
  이미 제공하지만(swagger 확인), Domain `LearningStatistics`와 Composition
  `MemberRepositoryAdapter`가 이 필드들을 잘못 매핑하고 있어(요일 라벨을 날짜로 파싱
  시도 → 항상 빈 배열) 이번 기능에서 Domain·Composition을 함께 교정한다.
- 개발 분야·개발 수준 선택 화면은 온보딩의 `SelectionCardList` 패턴(카드형, 아이콘+제목+
  설명, 선택 시 파란 테두리)을 참고해 설정 흐름 전용으로 새로 구현한다.
- "세트 생성 완료 알림"(알림 설정)은 이번 범위에서 제외한다(spec.md FR-014).

## 기술 맥락

**언어/버전**: Swift 5 language mode, Swift tools 6.0

**주요 의존성**: SwiftUI, The Composable Architecture, Tuist, `DomainMember`,
`DesignSystem`, `UIComponent`

**저장소**: 신규 저장소 없음. Router와 화면 Feature의 State가 Store 수명 동안만 프로필과
설정 상태를 보존

**테스트**: Swift Testing, TCA `TestStore`, UIComponent 계약 테스트, SwiftUI Preview,
Tuist 공유 scheme의 build-for-testing·test-without-building, 패키지 의존 방향 정적 검사

**대상 플랫폼**: iPhone/iPad, iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 모바일 앱

**성능 목표**: 프로필 화면 최초 표시당 프로필(통계 포함) 조회 1회, 설정 화면 최초 표시당
프로필 조회 1회(화면 독립 조회 — 기존 Home/Settings 관행과 동일), 재시도당 조회 최대 1회,
stale 응답 반영 0회

**제약 조건**: 생성자 주입, Feature는 Domain·UI만 의존, UIComponent에 Domain·TCA 타입
노출 금지, `SettingsFeature`의 기존 State/Action/Reducer는 변경하지 않고 재사용, 서버에
이미 존재하는 필드(`thisWeekSolvedCount`/`thisMonthSolvedCount`/`streakDays`/
`weeklyChart`)를 올바르게 노출하는 것 외의 새 서버 계약·API 추가 없음, "세트 생성 완료
알림" 관련 구현 없음(FR-014)

**규모/범위**: Domain·Composition·Feature·UI 4개 패키지(App은 기존 배선을 그대로 재사용
— 변경 없음), 화면 5개(프로필, 설정, 개발 분야 선택, 개발 수준 선택, 계정 삭제 확인),
신규 Feature 1개(`ProfileFeature`), 신규 Router 1개(`SettingsRouterFeature`)

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 다시 점검한다.*

- **브랜치**: 현재 브랜치 `feature/my-page`는 허용된 Git-flow namespace(`feature/`)와
  명세 metadata에 일치한다. **PASS**
- **수정 경계**: 이 단계에서는 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 수정한다. 구현 파일은 계획에만 명시한다. **PASS**
- **모듈 경계**: Domain은 서버 실측 필드에 맞춘 순수 모델만 소유(외부 API 이름을 그대로
  노출하지 않고 도메인 어휘로 표현), Composition은 DTO↔Domain 변환만 소유,
  Feature(Router·Profile·Settings)는 Domain·UI만 의존, UI는 표시 값·콜백만 노출하는
  기존 컴포넌트(`SelectionCardList`, `SettingRow`, `AccountActionRow` 등)를 재사용한다.
  의존 방향 `Feature → Domain, UI`, `Composition → Domain, Data, Infrastructure`를
  지킨다. **PASS**
- **상태·데이터 안전성**: Router의 `ActiveScreen`은 되돌아갈 화면의 child state를 항상
  보유해 뒤로가기 시 입력값을 새로 만들지 않는다(Navigation 컨벤션 §2.3). 기존
  `SettingsFeature.State`의 배타적 `enum` 상태를 그대로 사용한다. **PASS**
- **생성자 주입**: 신규 `ProfileFeature`, `SettingsRouterFeature`는 필요한 UseCase를
  생성자로만 받는다. production `@Dependency`, dependency key, Service Locator를
  추가하지 않는다. **PASS**
- **검증 가능성**: `LearningStatistics` 매핑 교정, Router의 화면 전환, `MemberProfile` →
  표시 모델 변환을 자동화 테스트로 검증하고 Figma 대조·Dynamic Type은 실행 가능한
  Preview와 Simulator 수동 항목으로 남긴다. **PASS**
- **책임 기반 네이밍**: `ProfileFeature`, `ProfileScreen`, `SettingsRouter`,
  `SettingsRouterFeature`, `SettingsStep`은 소유 책임을 드러내며 기존
  `SettingsFeature`·`MainShellTab`(탭 이름 "마이")과 일관된 어휘를 유지한다. **PASS**
- **세션 지식 기록**: `LearningStatistics` 매핑 버그(요일 라벨을 날짜로 파싱해 주간
  데이터가 항상 빈 배열이 되는 문제)는 다른 세션에서도 재사용 가능한 원인·복구
  절차이므로 `/speckit-implement` 완료 후 `$speckit-troubleshooting` 기록 대상 여부를
  검토한다(계획 산출물로 만들지 않음).

**게이트 결과**: 위반과 미해결 명확화 항목 없음. 복잡성 추적 표를 작성하지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/026-my-page/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── settings-router-contract.md
│   └── profile-screen-contract.md
└── tasks.md                    # /speckit-tasks 산출물
```

### 소스 코드(계획된 구현 경로)

```text
sources/Projects/
├── Domain/
│   └── Member/Models/MemberProfile/
│       ├── LearningStatistics.swift        # 필드 교정: thisWeekSolvedCount 등
│       └── WeeklyLearningCount.swift        # 필드 교정: dayLabel/count
├── Composition/
│   └── Adapter/Adapters/MemberRepositoryAdapter.swift  # 매핑 교정, 버그 있는 날짜 파싱 제거
├── UI/
│   └── Component/                       # 필요 시에만: Figma 재대조 결과 기존 컴포넌트로
│       부족한 시각 요소 발견 시 추가(조건부, tasks.md에서 확정)
└── Feature/
    ├── Settings/
    │   ├── Router/
    │   │   ├── SettingsRouter.swift              # 신규 View
    │   │   ├── SettingsRouterFeature.swift        # 신규 Reducer, ActiveScreen 소유
    │   │   └── Previews/
    │   ├── Profile/
    │   │   ├── ProfileScreen.swift                 # 신규 View
    │   │   ├── ProfileFeature.swift                 # 신규 Reducer
    │   │   ├── SubViews/
    │   │   ├── ViewModels/ProfileDisplay.swift
    │   │   └── Previews/
    │   └── Settings/
    │       ├── SettingsFeature.swift                # 기존 파일, 변경 없음
    │       ├── SettingsScreen.swift                 # 신규 View(목록)
    │       ├── SubViews/
    │       │   ├── SettingsScreen+PositionSelectionView.swift
    │       │   ├── SettingsScreen+CareerLevelSelectionView.swift
    │       │   └── SettingsScreen+AccountDeletionView.swift
    │       └── Previews/
    ├── MainShell/
    │   └── Router/
    │       └── MainShellRouter.swift            # case .settings의 PlaceholderView 교체
    └── Tests/
        └── Settings/
            ├── Router/
            ├── Profile/
            └── Settings/
```

**구조 결정**: [디렉터리·파일 컨벤션 §4.3](../../docs/conventions/directory-file.md#43-feature-패키지의-흐름-배치)에
따라 기존 `Settings` 흐름 폴더를 유지하고 그 아래 `Router/`·`Profile/`을 새 1뎁스
단위로 추가한다. `Settings/`(기존 화면 폴더)에는 여러 단계(목록/개발 분야 선택/개발
수준 선택/계정 삭제 확인)를 갖는 화면 하나가 있으므로 [TCA Navigation 컨벤션
§2.3](../../docs/conventions/tca/navigation.md#23-router-feature와-화면-전환-소유)의
"하나의 화면 Feature가 여러 단계를 가짐" 패턴에 따라 `SettingsFeature`는 그대로 두고
`SettingsRouterFeature.ActiveScreen`이 `.settings(SettingsStep)`으로 세부 단계를
연관값으로 갖는다. `MainShell`은 자신의 화면 없이 `Router/`만 갖는 기존 구조를
유지하며 `MainShellRouter.swift`가 `SettingsRouter(store:)`를 참조하도록 한 줄만
바꾼다. Feature target의 소스 glob은 패키지 루트 전체를 이미 포함하므로 Tuist
manifest 변경은 필요하지 않다.

## 패키지 구현 경계와 순서

아키텍처 표의 `Feature → Domain, UI`, `Composition → Domain, Data, Infrastructure`를
적용해 `Domain → Composition, UI → Feature` 순서로 진행한다(Composition과 UI는 서로
의존하지 않으므로 상대 순서는 이 문서가 정하며, Domain 교정을 다른 모든 패키지가
참조하므로 가장 먼저 진행한다). Data, Infrastructure, App은 기존 계약과 배선을 변경
없이 재사용하므로 건너뛴다.

1. **Domain**: `LearningStatistics`(`thisWeekSolvedCount`/`thisMonthSolvedCount`/
   `streakDays`/`weeklyCounts`)와 `WeeklyLearningCount`(`dayLabel`/`count`)를 서버 실측
   응답에 맞게 교정한다. 기존 호출부(`AppRootView`, `HomeScreenPreviews`, Domain
   테스트)를 새 필드명으로 갱신한다.
2. **Composition**: `MemberRepositoryAdapter.fetchProfile()`이 DTO의
   `thisWeekSolvedCount`/`thisMonthSolvedCount`/`streakDays`/`weeklyChart`를 그대로
   전달하도록 수정하고, 요일 라벨을 날짜로 파싱하려던 버그 코드(`dayFormatter`,
   `weeklyCount(from:)`)를 제거한다. 기존 adapter 테스트를 새 필드 검증으로 갱신한다.
3. **UI** (조건부): 구현 단계에서 Figma 노드를 다시 조회해 기존 컴포넌트
   (`ScreenHeader`, `SettingRow`, `SelectionCardList`, `AccountActionRow`,
   `EmptyState`)로 표현할 수 없는 요소를 발견하면 표시 값과 콜백만 받는 신규
   UIComponent를 추가한다. 없으면 이 단계는 생략한다.
4. **Feature**: `SettingsRouterFeature`(Router, `ActiveScreen` 소유)를 신규 구현하고,
   `ProfileFeature`(신규, 프로필+통계 조회)와 기존 `SettingsFeature`(변경 없음)를
   Router의 항상-존재 child state로 조합한다. 설정 화면 안에서 개발 분야/개발 수준
   선택·계정 삭제 확인은 `SettingsRouterFeature.ActiveScreen.settings(SettingsStep)`이
   전환하는 서브뷰로 구현하고, `SettingsFeature`의 기존 Action(`positionSelected` 등)을
   그대로 사용한다. `MainShellRouter`의 `case .settings`가 `SettingsRouter(store:)`를
   반환하도록 한 줄을 바꾼다.

각 단계는 독립적으로 컴파일·테스트·되돌리기가 가능하다. Domain 필드 교정과 이를
소비하는 Composition 매핑은 같은 커밋에서 compile되어야 하는 관계가 아니라(Composition은
Domain 교정 완료 후 순차적으로 컴파일 가능) 별도 단위로 유지하되, Domain 완료 전에는
Composition을 시작하지 않는다. UI 확장이 필요하면 `UI → Feature` 위상 순서를 지킨다.
전체 `build → compile-unit → test-unit`은 Feature 단계 후 `[no-write]` 최종 검증으로
실행하고, 실행 전후 Git 상태를 비교한다.

## 설계 후 헌법 재점검

- `research.md`의 재사용 컴포넌트·Router 패턴·Domain 교정 근거가 `data-model.md`의
  엔터티, `contracts/**`의 화면 계약과 일치한다.
- `ProfileDisplay`(신규)는 순수 변환 함수이며 TCA `State`를 복제하거나 자체 mutable
  상태를 갖지 않는다.
- UIComponent는 Domain 타입(`MemberProfile`, `MemberPosition`, `CareerLevel`)이나 TCA
  `Action`을 직접 받지 않고 표시 값과 콜백만 받는다 — 변환은 Feature가 소유한다.
- Router의 `ActiveScreen`은 "완료"를 뜻하는 case를 두지 않으며, 로그아웃·계정 삭제
  완료처럼 흐름을 벗어나야 하는 경우는 `SettingsFeature.Action.Delegate`를 그대로
  `MainShellRouterFeature`까지 전달한다(기존 배선 유지).
- 직군·연차 변경 실패는 `SettingsFeature`가 이미 `positionMutation`/
  `careerLevelMutation`을 `.failed`로 전이시키고 `profile`을 낙관적으로 갱신하지
  않으므로, 화면은 실패 시 이전 값을 그대로 표시하며 별도 롤백 로직을 구현하지 않는다.
- Domain `LearningStatistics` 필드 교정은 새 서버 계약이 아니라 이미 존재하는 서버
  응답 필드를 올바르게 노출하는 수정이므로 Data 패키지의 DTO(`MemberProfileResponseDTO`,
  `WeeklyChartItemDTO`)는 변경하지 않는다.
- FR-014(알림 설정 제외)에 따라 이번 범위의 어떤 화면·Action도 알림 설정을 구현하지
  않는다.
- 신규 외부 의존성, Tuist target, Data/Infrastructure 계약, 아키텍처 문서 변경은
  필요하지 않다.

**재점검 결과**: 위반 없음. **PASS**
