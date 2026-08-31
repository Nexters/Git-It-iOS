# 구현 계획: 홈 화면과 MainShell 4탭 통합

**Git-flow 유형**: `feature`

**브랜치**: `feature/home-screen`

**날짜**: 2026-08-30 | **명세**: [spec.md](./spec.md)

**입력**: `/specs/018-home-screen/spec.md`의 기능 명세

## 요약

MainShell의 기본 탭을 Home으로 바꾸고 Home·Project·Saved·My 네 탭을 제공한다.
Home은 기존 `FetchMemberProfileUseCase`와 `FetchLearningProjectsUseCase`를 생성자로 주입받아
프로필과 프로젝트를 독립적으로 한 번씩 조회하고, 빈 상태·실패·재시도와 상위
navigation intent를 TCA 상태와 delegate로 관리한다. 카드 색은 Domain 조회 순서로
고정하고, 회전은 SwiftUI의 현재 표시 좌표를 `P0(0°)`·`P1(+16°)`·`P2(-12°)`
사이에서 선형 보간한다. `viewAligned` 스냅으로 감속 후 가장 가까운 카드를
`P0`에 정렬하며, 좌표·스크롤 위상은 View 수명의 표현 상태로만 둔다.

## 기술 맥락

**언어/버전**: Swift 5 language mode, Swift tools 6.0

**주요 의존성**: SwiftUI, The Composable Architecture 1.26.0, Tuist,
`DomainLearningProject`, `DomainMember`, `DesignSystem`, `UIComponent`

**저장소**: 신규 저장소 없음. 기존 Domain Use Case가 반환하는 서버 정보를
`HomeFeature.State`의 현재 수명 동안만 보존

**테스트**: Swift Testing, TCA `TestStore`, UIComponent 계약 테스트, SwiftUI Preview,
Tuist shared scheme의 build-for-testing·test-without-building, source 경계 정적 검사,
Simulator Figma·VoiceOver·`DynamicTypeSize` 12단계 비교

**대상 플랫폼**: iPhone/iPad, iOS 26.0 이상

**프로젝트 유형**: Tuist 기반 멀티 패키지 iOS 모바일 앱

**성능 목표**: Home 최초 표시당 프로필·프로젝트 조회 각 1회, 재시도당 프로필
조회 최대 1회, stale 응답 반영 0회, 카드 정지 중 앵커 각도 오차 `±0.5°`,
`P0` 정렬 오차 `±1pt`

**제약 조건**: 생성자 주입, Feature의 Domain/UI만 의존, UIComponent에 Domain·TCA
타입 노출 금지, 추가 페이지 조회 금지, 실제 등록·상세·학습 navigation 구현 제외,
기존 authentication·onboarding·splash 진입 조건 보존

**규모/범위**: UI·Feature·App 3개 패키지, MainShell 4탭, Home child Feature 1개,
독립 조회 상태 2개, 카드 앵커 3개, 상위 intent 3종(등록·상세·학습),
재현 가능한 홈 표시 상태 5종 이상

## 헌법 점검

*게이트: 0단계 조사 전에 통과했으며 1단계 설계 후 다시 점검했다.*

- **브랜치**: 현재 브랜치 `feature/home-screen`은 허용된 Git-flow namespace와
  명세 metadata에 일치한다. **PASS**
- **수정 경계**: 이 단계에서는 `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, `contracts/**`만 수정한다. 구현 파일은 계획에만 명시한다. **PASS**
- **모듈 경계**: UI는 카드의 표시 값과 독립적 콜백, Feature는 Domain 모델에서
  표시 값으로의 변환·TCA 상태·스크롤 표현, App은 delegate 해석 경계만 소유한다.
  의존 방향 `App → Feature`, `Feature → Domain, UI`를 지킨다. **PASS**
- **상태·데이터 안전성**: 프로필과 프로젝트를 각각 배타적 `enum` 상태와
  request ID로 표현하고 Effect를 독립 취소한다. 스크롤 좌표는 제품 상태가 아니므로
  SwiftUI 표현 수명에만 둔다. **PASS**
- **생성자 주입**: Home은 두 Use Case를 initializer로만 받고 production `@Dependency`,
  dependency key, Service Locator를 추가하지 않는다. **PASS**
- **검증 가능성**: 순수 좌표→각도 함수, reducer 상태 전이, MainShell/App delegate,
  UIComponent 콜백 분리를 자동화 테스트로 검증하고 Figma·VoiceOver·Dynamic Type은
  실행 가능한 Preview와 Simulator 수동 항목으로 남긴다. **PASS**
- **책임 기반 네이밍**: `HomeFeature`, `HomeScreen`, `HomeCardScrollLayout`,
  `ProfileLoad`, `ProjectLoad`는 소유 책임과 상태 의미를 드러낸다. **PASS**
- **세션 지식 기록**: 이 계획은 명세, 공용 문서와 현재 소스에 이미 명시된
  규칙을 적용한 것이며 새로운 암묵 규칙을 추론하지 않았다. **전용 기록 스킬 대상 아님**

**게이트 결과**: 위반과 미해결 명확화 항목 없음. 복잡성 추적 표를
작성하지 않는다.

## 프로젝트 구조

### 문서(이 기능)

```text
specs/018-home-screen/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── home-feature-contract.md
│   ├── home-card-scroll-contract.md
│   └── main-shell-integration-contract.md
└── tasks.md                    # /speckit-tasks 산출물
```

### 소스 코드(계획된 구현 경로)

```text
sources/Projects/
├── UI/
│   ├── Component/CollectionItems/HomeProjectCard/
│   │   ├── HomeProjectCard.swift
│   │   └── HomeProjectCard+Variant.swift
│   └── Tests/Component/Unit/CollectionItems/HomeProjectCardTests.swift
├── Feature/
│   ├── Home/
│   │   ├── Models/HomeCardScrollLayout.swift
│   │   ├── Reducers/HomeFeature.swift
│   │   ├── Screens/HomeScreen.swift
│   │   └── Previews/
│   ├── MainShell/
│   │   ├── Models/MainShellTab.swift
│   │   ├── Reducers/MainShellFeature.swift
│   │   └── Screens/MainShellScreen.swift
│   └── Tests/
│       ├── Home/{Models,Reducers,Screens,TestDoubles}/
│       └── MainShell/Reducers/MainShellFeatureTests.swift
└── App/
    ├── GitIt/Reducers/AppRootFeature.swift
    └── Tests/GitIt/Reducers/AppRootFeatureTests.swift
```

**구조 결정**: 기존 Tuist 타겟과 폴더 규칙을 유지한다. Feature target의 `.`
소스 glob은 `Tests/**`를 제외하고 이미 Home 폴더를 자동 포함하므로 manifest 변경은
필요하지 않다. `HomeProjectCard`는 단일 목록 항목의 표시·동작 계약을 계속 소유하고,
목록 좌표·정렬·Domain 변환은 Home Feature가 소유한다.

## 패키지 구현 경계와 순서

아키텍처 표의 `App → Feature`, `Feature → UI, Domain`을 적용해 `UI → Feature → App`
순서로 진행한다. Domain과 Composition은 기존 계약을 변경 없이 재사용하므로 건너뛴다.

1. **UI**: `HomeProjectCard.Variant`에서 회전값 책임을 제거하고 카드 본문과
   학습 버튼의 독립 콜백·접근성 계약을 추가한다. 표시 값만 받는 공개 API와
   variant 색 순환을 UIComponent 계약 테스트로 검증한다.
2. **Feature**: `HomeFeature`의 독립 조회 상태·request identity·delegate를 구현하고,
   `HomeScreen`이 Domain 모델을 표시 값으로 변환한다. `HomeCardScrollLayout`은
   앵커 좌표와 선형 보간을 순수 함수로 제공한다. MainShell은 Home child와 네 탭,
   `전체 보기`의 탭 변경, Home delegate 전달, 로그아웃·계정 삭제 초기화를 소유한다.
3. **App**: 등록·상세·학습 intent를 명시적으로 수신하되 이 기능에서 destination을
   생성하지 않는다. App route가 유지되고 MainShell 초기화 후 Home이 선택되는지
   App reducer 테스트로 검증한다.

각 단계는 단일 패키지로 독립 컴파일과 되돌리기가 가능하므로 다중 패키지
integration unit을 두지 않는다. 전체 `build → compile-unit → test-unit`은 App 단계 후
`[no-write]` 최종 검증으로 실행하고, 실행 전후 Git 상태를 비교한다.

## 설계 후 헌법 재점검

- `research.md`의 의존 성능·Figma·SwiftUI 근거가 `data-model.md`의 상태와
  `contracts/**`의 경계에 일치한다.
- 프로필·프로젝트 Effect는 취소 ID와 request ID를 각각 갖고, 실패 시 다른 영역의
  정보를 폐기하지 않는다.
- UIComponent는 Domain ID·TCA Action·스크롤 목록 상태를 받지 않고 표시 값과
  `onSelect`·`onStart` 콜백만 받는다.
- `HomeCardScrollLayout`은 순수 표현 계산이며 TCA State나 Domain model을 복제하지
  않는다. SwiftUI 스크롤은 main actor의 레이아웃 프레임 안에서만 계산된다.
- Home의 세 intent는 Feature → MainShell → App 방향으로만 전달되며 App이
  이번 범위에서 실제 destination을 추가하지 않는다.
- Preview는 `Home/Previews/`에 분리하며 Figma 상태 이름에 node ID를 포함해
  기존 View 컨벤션과 FR-032를 모두 충족한다.
- Figma 차이는 수정하거나 사용자가 명시적으로 승인하고 검증 결과·PR에
  차이·근거·영향·미검증 범위를 남긴 예외로 분류하며, 미승인 차이는 검증 실패다.
- `DynamicTypeSize` 검증은 iOS 26의 `xSmall`~`accessibility5` 전체 12단계를 대상으로 한다.
- 최종 정적 검사는 Home production Feature source의 Data·Infrastructure·Composition import,
  `@Dependency` 기반 Use Case 조회와 새 Avatar Backend·Domain 계약이 0건임을 독립적으로 확인한다.
- 신규 외부 의존성, Tuist target, Domain/Data/Composition 계약, 아키텍처 문서 변경은
  필요하지 않다.

**재점검 결과**: 위반 없음. **PASS**
