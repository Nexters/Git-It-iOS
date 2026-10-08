# 조사: UI 패키지 컨벤션 리팩터링

## 조사 범위

- `sources/Projects/UI/Component/Components/**` production Swift 파일과 공개 생성 경로
- DesignSystem 토큰 및 적용 API
- UIComponent unit/UI tests와 `UIComponentLayoutHarness`
- UI·Feature Tuist target, shared scheme와 App 의존 그래프
- Figma page `86:761`의 `사용한 컴포넌트`, `Design system`, `최종 UXUI` 역할

모든 기술적 불확실성을 아래 결정으로 해소했으며 미해결 명확화 표식은 남아 있지 않다.

## 결정 1: 직접 입력 공개 계약

**결정**: UIComponent의 표시 wrapper가 있는 22개 production View에서 `ViewModel`을
제거하고 읽기 값은 init 인자, 외부 변경 값은 `Binding`, 일회성 입력은 콜백으로 받는다.
`Item`, `Style`, `Size`, `Variant`, `Asset`, `Control`, `User`처럼 표현 의미나 시각 규칙을
소유하는 중첩 타입은 유지한다.

**근거**: 현재 25개 Leaf·Composite 파일 중 22개가 `ViewModel`을 공개하며 Feature 사용처는
없다. UIComponent·View 컨벤션은 wrapper를 금지하고 직접 계약을 정본으로 규정한다.

**검토한 대안**: wrapper 이름만 `Configuration`으로 바꾸는 방식은 동일한 표시 상태 묶음을
남기므로 기각했다. 모든 중첩 타입을 평탄화하는 방식은 시각 규칙과 식별 가능한 item의
소유권까지 잃으므로 기각했다.

## 결정 2: ActionButton 분류와 상태

**결정**: `ActionButton`은 기존 Leaf 경로를 유지하되 `StyledText` 컴포넌트를 렌더링하지
않고 DesignSystem의 `Text.designSystemStyled` 계열 API를 사용한다. 직접 입력으로 기존
문자열과 typography 표시 값을 보존하고 `primary`, `secondary`, `destructive`, `text`
팩토리를 유지한다. 누름은 내부 `ButtonStyle`의 `configuration.isPressed`, 비활성은
`isEnabled`, 오류는 `destructive`가 소유한다.

**근거**: Figma `Button`의 `Pressing`은 일시적 상호작용이고 공개 State가 아니다. View
컨벤션은 자기 문자열을 직접 그리는 `ActionButton`을 Leaf 예로 들며 DesignSystem text
적용 API 사용을 요구한다.

**검토한 대안**: 현재 `StyledText` 자식 관계를 기준으로 Composite로 이동하는 방식은
불필요한 컴포넌트 의존을 고착하므로 기각했다. Figma 상태 enum을 공개하는 방식도 외부가
일시적 누름 상태를 소유하게 하므로 기각했다.

## 결정 3: 선택 상태의 단일 정본

**결정**: `SelectionCardList`는 안정적인 `Item.ID`에 대한 `Binding<Item.ID?>`을 받고,
항목 탭으로 binding을 갱신하며 카드 선택 표현을 ID 비교로 파생한다. `TabShell`도
`Binding<Item>`을 받아 현재 `.constant` 선택 복제를 제거한다.

**근거**: Figma의 `Default`·`1`…`5`는 샘플 목록 위치를 표현할 뿐 공개 도메인 값이 아니다.
ID binding은 항목 재정렬과 가변 개수에서도 선택 의미를 보존한다.

**검토한 대안**: `Binding<Int?>`와 위치 enum은 재정렬에 취약해 기각했다. 각 카드에
독립 `Bool`을 전달하면 다중 선택 불일치가 생길 수 있어 기각했다.

## 결정 4: 접근성 제거와 UI test selector의 경계

**결정**: production 및 Review View의 accessibility label·value·trait·element modifier,
접근성 전용 공개 입력과 관련 assertion을 제거한다. 접근성 Dynamic Type 시나리오도
제거한다. 다만 `UIComponentLayoutHarness`에만 있는 `.accessibilityIdentifier`는 제품
접근성 의미가 아닌 XCUI 비제품 selector로 제한하고 label·value·trait를 검증하지 않는다.
상호작용 결과는 화면에 보이는 상태 marker와 pixel/geometry로 검증한다.

**근거**: 사용자는 접근성 구현과 검증 제거를 명시했고, XCTest UI 자동화는 안정적인
요소 식별자가 필요하다. selector를 harness에 격리하면 production 접근성 계약을 만들지
않으면서 실제 탭과 layout을 검증할 수 있다.

**검토한 대안**: 모든 identifier까지 제거하고 좌표만 사용하는 방식은 스크롤·기기 크기에
취약해 회귀 판별력이 낮다. 기존 label/value를 selector와 assertion에 계속 쓰는 방식은
접근성 검증 제거 요구를 위반해 기각했다.

## 결정 5: 테스트 책임 분리

**결정**: Swift Testing은 직접 init/factory 생성, 값 정규화, 시각 상태 결정과 Binding
파생 규칙을 검증한다. XCTest UI 자동화는 실제 탭, callback/Binding 전달, disabled 입력
차단과 현재 geometry/pixel을 검증한다. harness는 `--contract-scenario` launch argument로
작은 결정적 장면을 선택하고 알 수 없는 값은 catalog로 수렴한다.

**근거**: 누름 순간 pixel capture 같은 일시 상태는 순수 표현 결정 테스트가 더 결정적이고,
실제 사용자 입력 전달은 host app에서만 검증할 수 있다. 현재 긴 catalog를 매번 스크롤하는
방식보다 scenario별 장면이 실패 범위를 줄인다.

**검토한 대안**: 모든 계약을 UI test에 두면 느리고 selector 의존이 커진다. 모든 계약을
단위 테스트에 두면 실제 SwiftUI tap과 Binding 전달을 검증하지 못한다.

## 결정 6: DesignSystem 토큰

**결정**: 기존 `SemanticColorToken`, `LayoutToken`, `CornerRadiusToken`,
`ControlSizeToken`, `TextStyleToken`과 적용 API를 재사용한다. 한 View에만 의미가 있는 수치는
중첩 `private Constant`로 옮기며 새 공용 토큰은 선제 추가하지 않는다.

**근거**: 현재 screen/card/raised background, brand accent, progress track/fill 등 공통
역할과 layout·radius·control-size 토큰이 이미 존재한다. 조사에서 새 공유 역할의 독립
근거가 확인되지 않았다.

**검토한 대안**: 모든 숫자를 공용 토큰으로 승격하는 방식은 단일 컴포넌트 의미를 전역
어휘로 오인하게 하므로 기각했다.

## 결정 7: Figma와 현재 layout 우선순위

**결정**: `사용한 컴포넌트`는 지원 변형·상태 의미, `Design system`은 토큰,
`최종 UXUI`는 조립 결과 대조에 사용한다. 크기·간격·배치가 다르면 현재 layout test와
harness geometry를 우선한다.

**근거**: 명확화에서 사용자가 현재 layout 보존을 최종 결정했다. Figma `Button`과
`SelectCardList`는 공개 상태 매핑을 결정하는 근거로 사용하되 geometry 변경 근거로 쓰지
않는다.

**검토한 대안**: Figma geometry로 layout test를 갱신하는 방식은 의도된 시각 변경을
도입하므로 기각했다.

## 결정 8: Review target과 패키지 진행

**결정**: target 이름은 `FeatureReview`, sourceDirectory는 `Review`로 한다. 기존 Feature
shared scheme의 Build Action에 추가하되 App과 기존 `Feature` target은 의존하지 않는다.
UI 단계에서 기존 Review 파일 3개를 제거하고 검증·보고·승인한 뒤 Feature 단계에서 같은
책임을 직접 입력 계약으로 생성한다.

**근거**: target 이름에는 패키지 문맥이 필요하지만 패키지 내부 폴더에는 접두어를 반복하지
않는 네이밍 컨벤션을 따른다. 단일 `git mv`는 Constitution의 UI→Feature 승인 경계를
건너므로 삭제와 추가를 단계별로 나눠야 한다.

**검토한 대안**: 별도 scheme은 패키지당 shared scheme 하나라는 테스트 컨벤션과 충돌한다.
빈 test target은 실제 테스트가 있는 target만 scheme에 연결한다는 규칙과 충돌한다.
Review를 App에 연결하는 방식은 제품 실행 경로 제외 요구를 위반한다.

## 결정 9: 적용·제외 패키지

**결정**: 구현 패키지는 `UI → Feature`다. `Domain`, `Data`, `Infrastructure`,
`Composition`, `App`은 제외한다. `ProjectName.swift`의 Feature scheme branch 변경은 이를
최초로 필요로 하는 Feature 단계에 배정한다.

**근거**: UI 공개 계약과 검증, Review 소유 target만 바뀐다. 비즈니스·데이터·기술 조립과
제품 앱 실행 경로에는 새 책임이나 의존이 없다.

**검토한 대안**: 공용 구성 변경을 준비 단계에 두는 방식은 패키지 소유권과 승인 순서를
흐리므로 기각했다.
