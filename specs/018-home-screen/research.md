# 0단계 조사: 홈 화면과 MainShell 4탭 통합

## 1. 현재 구현과 변경 경계

### 결정

- `MainShellFeature` 안에 `HomeFeature` child State·Action·Scope를 추가한다.
- `MainShellTab`은 `.home`, `.projects`, `.saved`, `.settings` 순서를 정본으로 삼고
  기본값을 `.home`으로 바꾼다.
- `MainShellScreen`은 Home에서만 scoped `HomeScreen`을 그리고 나머지 세 탭은
  기존 제목 placeholder를 그린다. 기존 child reducer는 제거하지 않는다.
- `AppComposition`과 `AppRootFeature` initializer는 이미 Home에 필요한 두 Use Case를
  노출·전달하므로 Composition과 Domain 계약은 변경하지 않는다.

### 근거

`docs/architecture.md`의 허용 의존성은 `App → Feature, Composition, Domain`,
`Feature → Domain, UI`이다. 현재 App은 `MainShellFeature`를 생성할 때 두 Use Case를 이미
전달하고, MainShell은 동일 의존성을 ProjectList와 Settings에 나눠 전달한다.
Home은 이 조립 경로를 재사용할 수 있다.

### 검토한 대안

- **Home을 App child로 추가**: 탭 선택과 Home 수명이 MainShell에 속하므로 소유권이
  어긋난다.
- **ProjectList·Settings State 공유**: Home의 최초 1회 조회·재시도·실패 표현이
  기존 탭과 다르고 두 child의 수명을 결합한다. 명세의 독립 상태에 반한다.

## 2. Home 상태와 비동기 작업

### 결정

- `ProfileLoad`와 `ProjectLoad`를 서로 독립된 배타적 enum으로 둔다.
- 각 영역은 자신의 payload, error, request ID를 소유한다. 새 요청은 기존 Effect를
  취소하고 `EffectEvent`의 request ID가 현재 State와 일치할 때만 반영한다.
- Home의 `.task`는 각 영역이 `.idle`인 경우만 해당 조회를 시작한다. 두 조회는
  서로 대기하지 않고 merge된 독립 Effect로 실행한다.
- 프로필 재시도는 프로필만 새 request ID로 교체하며 프로젝트를 건드리지
  않는다. 프로젝트는 자동·수동 재시도 Action을 제공하지 않는다.
- 프로필의 예기치 않은 error는 기존 Settings와 동일하게 `.temporarilyUnavailable`,
  프로젝트의 예기치 않은 error는 `.unexpected`로 mapping한다.

### 근거

`docs/conventions/tca.md`는 동시에 진행할 수 있는 operation을 별도 상태로 두고,
교체 가능한 요청에 cancellation과 request identity를 함께 사용하도록 정한다.
또한 `.task` 반복 호출을 State 전이로 차단하면 탭 복귀 시 추가 조회를 막으면서
MainShell이 Home State를 계속 소유할 수 있다.

## 3. 프로젝트 카드 스크롤과 회전

### 결정

- `ScrollView(.horizontal)` 안의 `LazyHStack`에 `.scrollTargetLayout()`을 적용하고,
  ScrollView에 `.scrollTargetBehavior(.viewAligned(anchor: .leading))`을 적용한다.
- 카드 선행 엣지와 viewport 선행 엣지를 일치시켜 카드 중심이 `P0`에
  오도록 한다. 감속과 최종 target 선택은 SwiftUI 스크롤 시스템에 위임한다.
- `P0`, `P1`, `P2`는 최초 레이아웃에서 `cardWidth + spacing`의 간격으로 정의된
  viewport 내 카드 중심 좌표다. 배열 index나 현재 가시 순서를 저장하지 않는다.
- 각 카드의 `midX`는 `visualEffect` 내의 scroll-view 좌표계에서 읽고 좌표에 맞는
  `rotationEffect`를 즉시 적용한다. 회전은 layout을 바꾸지 않는 visual effect다.
- `[P0, P1]`과 `[P1, P2]` 구간은 양 끝의 각도를 선형 보간한다. `P0` 왼쪽과
  `P2` 오른쪽은 각각 가장 가까운 끝의 `0°`, `-12°`로 clamp한다.
- 1개 카드는 `P0/0°`, 2개는 `P0/0°`·`P1/+16°`에서 시작한다.
- 좌표와 scroll phase는 Use Case·navigation에 영향을 주지 않는 일시 표현이므로
  TCA State에 두지 않는다. 좌표→각도 수학만 `HomeCardScrollLayout`의 순수 함수로
  분리해 자동 테스트한다.
- 수평 pan이 시작되면 ScrollView가 접촉을 소유하고 카드 본문·재생 버튼의
  tap은 발생하지 않는다. 카드 내부는 본문 Button과 재생 Button을 중첩하지 않은
  형제 control로 구성해 두 콜백의 배타성을 유지한다.

### 근거

Apple은 `scrollTargetLayout()`으로 반복 view를 target으로 정의하고
`ViewAlignedScrollTargetBehavior`으로 개별 view 기하에 정렬하는 방식을 제공한다.
`visualEffect` 안의 `GeometryProxy`는 layout을 변경하지 않고 위치에 따른 회전을
적용할 수 있다. `onScrollPhaseChange` 또한 상호작·감속·idle을 구분할 수 있지만,
본 설계의 스냅은 내장 target behavior가 소유하므로 reducer 상태 갱신에 사용하지 않는다.

- [Apple: ViewAlignedScrollTargetBehavior](https://developer.apple.com/documentation/swiftui/viewalignedscrolltargetbehavior)
- [Apple: scrollTargetLayout(isEnabled:)](https://developer.apple.com/documentation/swiftui/view/scrolltargetlayout(isenabled:))
- [Apple: visualEffect(_:)](https://developer.apple.com/documentation/swiftui/view/visualeffect(_:))
- [Apple: onScrollPhaseChange(_:)](https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:))

### 검토한 대안

- **`scrollPosition` 값을 TCA State에 저장**: 탭 전환으로 View가 재생성될 때 상품
  의미를 가지는 선택값이 아니며, 고빈도 좌표 갱신이 reducer를 불필요하게 구동한다.
- **데이터 index로 회전 결정**: 스크롤 중 한 카드의 각도가 변하지 않아 명세와
  사용자 참조 영상에 반한다.
- **직접 drag offset과 관성을 구현**: 플랫폼의 스크롤·접근성·입력 중재를 재구현하며
  내장 `viewAligned` target으로 충족할 수 있는 요구를 불필요하게 확장한다.

카드 접촉의 drag 판정도 임의 거리 임계값을 추가하지 않고 SwiftUI `ScrollView`의
플랫폼 scroll gesture 인식 결과를 사용한다. scroll로 인식된 접촉에서는 카드 본문과
재생 control의 tap intent를 모두 억제한다.

## 4. `HomeProjectCard` 공개 계약

### 결정

- `Variant` 선택은 색·타이포 대비·progress 표현만 소유하고 rotation을 소유하지
  않는다. `Variant(index:)`의 modulo 3 색 순환은 유지한다.
- 카드는 표시 값과 `onSelect`, `onStart`를 받는다. Domain ID와 학습 가능 판단은
  Feature가 표시 값·활성 상태·콜백으로 변환한다.
- 카드 본문과 재생 control은 각각 최소 44pt 터치 영역과 독립 접근성 label을
  갖는다. 학습 ID가 부족하면 재생 control은 disabled 상태와 해당 접근성 의미를
  동일하게 노출한다.

### 근거

`docs/conventions/ui-component.md`는 CollectionItem이 항목 표시와 항목 단위 동작을 소유하되
목록 정렬·페이지네이션과 Feature 모델을 소유하지 않도록 정한다. 회전은 카드
자체의 색 variant가 아니라 Home 목록 좌표에 속하므로 Feature 표현의 책임이다.

## 5. 표시 상태와 항목 변환

### 결정

- 프로필은 `MemberProfile.name`을 항상 표시하고 `position`, `careerLevel`은 존재하는
  값만 기존 표시 용어로 변환해 조합한다. 둘 다 nil이면 보조 문구를 생성하지 않는다.
- 프로젝트는 `LearningProjectSummary` 배열을 순서 그대로 반복하고 `hasNext`를 추가
  요청으로 해석하지 않는다. progress는 percent를 0...1 표시 값으로 변환하되
  UIComponent가 최종 clamp를 보장한다.
- `currentSetLabel`은 임의 문자열이므로 `Set ` 접두어를 제거해 Int로 재구성하지
  않는다. 따라서 `HomeProjectCard`의 현재 `currentSet: Int`는 손실 없는
  `currentSetLabel: String` 표시 계약으로 교체한다.
- 프로젝트 `.failed`와 `.loaded([])`는 reducer State로는 구분하지만 동일한 빈 표현으로
  렌더링한다. 프로필 `.failed`는 헤더 내 error·재시도를 렌더링한다.

### 근거

서버가 제공하는 `currentSetLabel`은 Domain이 이미 표시 용도로 공개한 문자열이다.
이를 파싱하면 FR-010·FR-012의 Domain source-of-truth와 문자열에서 ID를 재구성하지
않는다는 정책을 약화시킨다.

## 6. MainShell과 App intent 연결

### 결정

- Home의 `showAllProjectsTapped`은 Home delegate로 올리지 않고 MainShell이 child Action을 해석해
  `selectedTab = .projects`로 변경한다.
- 등록·상세·학습은 Home delegate에서 MainShell delegate로 payload 손실 없이 전달한다.
- AppRoot는 새 MainShell delegate case를 명시적으로 받고 `.none`을 반환한다. 후속 기능이
  destination을 소유하기 전까지 route와 child State를 변경하지 않는다.
- 로그아웃·계정 삭제·App reset은 `MainShellFeature.State()`를 새로 만들어 Home 기본 탭과
  Home 조회 수명을 함께 초기화한다.

### 근거

TCA 컨벤션에서 Feature 밖 이동은 delegate intent이고 실제 앱 navigation은 App의 책임이다.
이번 명세는 intent까지만 요구하므로 App의 명시적 no-op은 누락이 아니라 범위 경계다.

## 7. Figma, Preview, 접근성 검증

### 결정

- 프로젝트 있음 `1465:19015`, 없음 `1542:19610`을 최종 화면 근거로 사용한다.
- `HomeProjectCard` 추정 매핑 `1617:25878`과 `TabShell` 추정 매핑 `1303:15398`은
  구현 시 Figma에서 직접 확인하고 확인된 차이만 수정한다.
- `Home/Previews/`에 project present, project absent, loading, project failure-as-empty,
  profile failure 상태를 독립 진입점으로 둔다. Figma 대응 Preview 이름에 node ID를
  포함한다.
- 자동 검증은 상태·표시 변환·앵커 계산을 담당하고, VoiceOver 선택 상태,
  수평 drag 우선순위, 긴 문자열·iOS 26 `DynamicTypeSize` 전체 12단계,
  `±1pt` 스냅은 Simulator에서 확인한다.
- Figma 비교에서 남은 차이는 수정하거나, 사용자의 명시적 승인과 검증 결과·PR의
  차이·근거·영향·미검증 범위 기록이 모두 있는 예외로 분류한다. 미승인 차이는
  완료로 판정하지 않는다.

### 근거

스냅 좌표·실제 접촉 중재·VoiceOver·Dynamic Type은 reducer 단위 테스트만으로 입증할
수 없다. 반대로 stale 응답·호출 횟수·payload·선형 보간은 결정론적 테스트가
가능하므로 수동 검증에만 의존하지 않는다.
