# 조사: UI 패키지 컨벤션 정본화

## 결정 1: 적용 패키지는 UI 하나로 제한

**결정**: source 변경 패키지는 `UI` 하나다. Feature와 App은 실제 `import UIComponent` 또는 component 생성 코드가 없으므로 변경하지 않고 최종 build에서 의존 경계의 컴파일 전이만 확인한다.

**근거**: 현재 Feature는 placeholder, App은 기본 SwiftUI 진입 화면이며 Feature/App source의 `UIComponent` 사용 검색 결과가 0건이다. UI target 내부 component, catalog와 tests가 실제 소비 지점이다.

**검토한 대안**: 명세의 잠재 소비 지점을 이유로 빈 Feature/App 마이그레이션 작업을 만드는 방식은 실제 파일 소유권과 Constitution의 패키지 게이트를 왜곡하므로 기각했다.

## 결정 2: ViewModel 제거는 22개 public View의 직접 계약 전환

**결정**: public View 23개 중 `ScreenEdgeScrim`을 제외한 22개의 component-scoped `ViewModel`을 제거한다. 각 필드는 읽기 값, UI 의미 타입, callback, 승인된 `Binding` 또는 content slot으로 분해한다.

**근거**: Leaf·Composite production source 전수 검색에서 22개 `public struct ViewModel`이 확인됐다. 이름만 바꾼 aggregate wrapper는 명세의 단일 컨벤션을 다시 훼손한다.

**검토한 대안**: deprecated ViewModel adapter 유지, `Configuration`/`Props` rename, 일부 component만 전환하는 대안은 legacy 계약과 혼합 상태를 남겨 기각했다.

## 결정 3: Preview 전용 타입을 별도 target source로 이동

**결정**: `LayoutReviewCatalogList`, `LayoutReviewChrome`, `LayoutReviewDetail`과 `TabShellPreviewItem`을 `ComponentPreview` 아래로 이동하고 production public API에서 제거한다. Preview 내부에서는 직접 입력 계약과 internal 접근 수준을 사용한다.

**근거**: 네 타입은 Preview/Review 책임이지만 현재 `Component/**` glob으로 UIComponent framework에 포함된다. 물리적 source root 분리가 generated source inclusion 검증을 가장 직접적으로 만든다.

**검토한 대안**: production 폴더에 남기고 access level만 낮추는 방식은 Preview 전용 코드가 production binary에 포함되는 문제를 해결하지 못한다.

## 결정 4: target은 UIComponentPreview, 폴더는 ComponentPreview

**결정**: `UIComponentLayoutHarness` target/app과 `ComponentLayoutHarness/` 경로를 각각 `UIComponentPreview`와 `ComponentPreview/`로 바꾼다. shared scheme `UI`, `UIUITests`는 유지하고 build/run target 및 UI test dependency만 교체한다.

**근거**: target에는 패키지 문맥을 포함하고 패키지 내부 source 폴더에는 역할만 사용한다는 저장소 규칙과 일치한다. 기존 scheme 이름은 검증 runner의 안정된 공개 진입점이다.

**검토한 대안**: scheme까지 rename하면 project-build와 CI 연결에 불필요한 파급이 생긴다. Harness 명칭을 유지하면 실행 앱의 실제 catalog 책임을 잘못 표현한다.

## 결정 5: 등록형 catalog와 결정적 fixture 사용

**결정**: 23개 public View 각각에 안정적인 `componentID`, display name, Leaf/Composite category, 지원 variant·size·state와 local factory를 갖는 catalog entry를 둔다. appearance, Dynamic Type, Reduce Motion, 긴 텍스트와 fallback은 launch configuration 또는 local environment 값으로 재현한다.

**근거**: 현재 catalog는 9개 시나리오를 단일 ScrollView에 직접 나열해 전수성, 탐색성 및 환경 확장이 부족하다. UI test가 같은 ID와 fixture를 재사용하면 catalog와 자동 검증의 상태 정의가 일치한다.

**검토한 대안**: 파일 단위 `#Preview`만 사용하는 방식은 중앙 등록 완전성과 UI test host 요구를 충족하지 못한다. 네트워크 fixture는 결정성과 계층 독립성을 위반한다.

## 결정 6: Preview는 재현, unit/UI test는 판정

**결정**: Preview는 화면과 test-only visible marker를 제공하되 assertion과 합격 판정을 수행하지 않는다. Swift Testing은 직접 입력·상태 매핑·callback·accessibility 의미를, XCTest UI는 geometry·실제 interaction·Dynamic Type·appearance·Reduce Motion·fallback을 판정한다.

**근거**: 현재 UI test는 geometry, 44pt interaction 영역, progress/accessibility, callback marker와 최대 Dynamic Type을 이미 판정한다. 책임 분리를 유지하면서 light appearance, Reduce Motion, 긴 텍스트와 fallback coverage를 추가할 수 있다.

**검토한 대안**: Preview 앱 자체 assertion은 사람이 탐색하는 host와 검증 주체를 결합한다. 모든 판정을 UI test에만 두면 값 정규화와 public contract 검증이 느리고 취약해진다.

## 결정 7: 접근성과 geometry는 보존 또는 강화

**결정**: 기존 accessibility label/value/trait, 최대 Dynamic Type, 최소 44×44pt interaction 영역과 확정 geometry를 제거하지 않는다. 직접 입력 전환으로 접근성 입력이 필요한 component는 표시 값에서 안전하게 파생하거나 의미가 별도일 때 직접 접근성 값을 받되 aggregate wrapper는 만들지 않는다.

**근거**: 활성 명세 FR-018과 SC-008이 접근성·geometry 회귀 0건을 요구하며 기존 UI test도 해당 계약을 판정한다.

**검토한 대안**: 이전 013 설계의 접근성 제거 방침은 현재 활성 014 명세와 충돌하므로 채택하지 않았다.

## 결정 8: 공용 Tuist helper와 UI 문서는 UI 단계 소유

**결정**: `UIModuleName.swift`, `ProjectName.swift`, `docs/package-rules/ui.md`, `docs/conventions/ui-component.md`의 변경을 UI 단계에 배정한다.

**근거**: 이 파일들의 변경은 UI target graph와 UI 정본화를 최초이자 유일하게 필요로 하며 다른 패키지 선언을 바꾸지 않는다.

**검토한 대안**: 별도 준비·마무리 단계는 Constitution이 금지한 무소유 다중 패키지 단계가 되므로 기각했다.

## 결정 9: 활성 UI 정본 범위

**결정**: 동기화할 활성 UI 정본은 현재 저장소에 존재하는 `docs/package-rules/ui.md`와 `docs/conventions/ui-component.md`로 한정한다.

**근거**: 명확화에서 존재하지 않는 기능 문서·UI component map·traceability·source index를 SC-010의 구현 대상으로 만들지 않기로 확정했다.

**검토한 대안**: 누락 문서를 이번 기능에서 새로 만드는 방식은 명세 목적과 문서 소유 범위를 확장하므로 기각했다.

## 결정 10: Red·lint·consumer 검증을 독립 gate로 유지

**결정**: 구현 전에 새 계약 테스트의 예상 실패를 확인하고, UI package Green 검증에는 Swift lint와 Feature/App/sample/document example consumer 전수 검색을 포함한다.

**근거**: 테스트를 먼저 작성해도 구현 전 실행하지 않으면 TDD 순서를 입증할 수 없고, build 성공만으로 SC-007의 lint 또는 FR-016의 모든 소비 지점 전환을 대체할 수 없다.

**검토한 대안**: 최종 build/test에 암묵적으로 포함됐다고 간주하는 방식은 각 required gate의 실제 결과를 분리해 보고하라는 Constitution 원칙과 충돌한다.

## 미해결 사항

`NEEDS CLARIFICATION` 없음. 구체 parameter 이름과 optional/default 보존은 현재 public behavior와 [UIComponent 공개 계약](./contracts/ui-component-public-contract.md)을 기준으로 구현 단계에서 파일별로 적용한다.
