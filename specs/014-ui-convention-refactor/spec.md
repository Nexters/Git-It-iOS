# 기능 명세: UI 패키지 컨벤션 정본화

**Git-flow 유형**: `feature`

**기능 브랜치**: `feature/ui-convention-refactor`

**생성일**: 2026-08-22

**상태**: 초안

**입력**: 사용자 설명: "UIComponent의 컴포넌트별 ViewModel을 제거하고 직접 입력 API를 단일 컨벤션으로 채택하며, UIComponentLayoutHarness를 UIComponentPreview로 전환해 시각적 탐색과 자동화 검증의 책임을 분리한다."

## 명확화

### 세션 2026-08-22

- 질문: SC-010의 정본 동기화 범위를 저장소에 실제로 존재하는 어떤 문서로 한정할까요? → 답변: `docs/package-rules/ui.md`와 `docs/conventions/ui-component.md`만 대상으로 하고 존재하지 않는 기능 문서·UI component map·traceability·source index는 제외한다.

## 변경 시나리오와 테스트 *(필수)*

### 시나리오 1 - 일관된 컴포넌트 공개 계약 사용 (우선순위: P1)

Feature 개발자는 컴포넌트별 표시 상태 wrapper를 만들지 않고 렌더링에 필요한 presentation value와 UI 전용 의미 타입을 직접 전달하며, 사용자 입력을 callback 또는 승인된 `Binding`으로 받을 수 있다.

**주요 행위자**: Feature 개발자

**우선순위 이유**: UIComponent의 공개 계약은 모든 Feature 소비 지점에 영향을 주며 상위 계층 타입 누출과 상태 소유권 역전을 막는 핵심 경계다.

**독립 테스트**: 모든 public UIComponent의 선언과 생성 지점을 검사하고 대표 상태를 생성해 component-scoped `ViewModel`과 동등 wrapper 없이 표시와 interaction 계약이 유지되는지 확인한다.

**수용 시나리오**:

1. **전제** 컴포넌트가 렌더링 값을 `ViewModel`로 받는 상태, **실행** 새 공개 계약으로 컴포넌트를 생성하면, **결과** 호출부는 최소 presentation value를 initializer에 직접 전달하고 동일한 표시 결과를 얻는다.
2. **전제** 사용자가 버튼·카드·메뉴를 조작하는 상태, **실행** interaction이 발생하면, **결과** 컴포넌트는 Feature Action이나 route를 해석하지 않고 의미가 분명한 callback으로 입력을 전달한다.
3. **전제** 양방향 제어가 컴포넌트의 본질인 상태, **실행** 상위 상태가 변경되거나 사용자가 값을 변경하면, **결과** 상위 계층 타입을 노출하지 않는 승인된 `Binding`을 통해 값이 동기화된다.

---

### 시나리오 2 - Preview에서 컴포넌트 탐색 (우선순위: P2)

UI 개발자와 검토자는 제품 앱이나 네트워크를 실행하지 않고 `UIComponentPreview`에서 모든 public component의 변형과 주요 상태를 결정적으로 재현할 수 있다.

**주요 행위자**: UI 개발자와 디자인 검토자

**우선순위 이유**: 컴포넌트 탐색 환경의 책임과 이름을 일치시키고 제품 통합과 독립된 빠른 시각 검토 경로를 제공한다.

**독립 테스트**: Preview 앱을 네트워크와 production credential 없이 실행하고 catalog의 모든 public component 및 공개 variant·주요 상태를 연다.

**수용 시나리오**:

1. **전제** public component 목록이 존재하는 상태, **실행** Preview catalog를 탐색하면, **결과** 각 컴포넌트를 안정적인 식별자로 열고 Leaf·Composite 분류와 지원 상태를 확인할 수 있다.
2. **전제** light/dark appearance, 최대 Dynamic Type 또는 Reduce Motion 검토가 필요한 상태, **실행** 해당 로컬 fixture를 선택하면, **결과** 외부 서비스 없이 동일한 상태가 반복 재현된다.
3. **전제** Preview에서 컴포넌트가 정상 표시되는 상태, **실행** 기능 완료 여부를 판정하면, **결과** Preview 도달성과 GitIt App 도달성이 별도 결과로 기록된다.

---

### 시나리오 3 - 자동화된 UI 계약 검증 유지 (우선순위: P3)

UI 패키지 유지보수자는 Preview 앱을 재현 host로 사용하되 레이아웃·접근성·interaction의 합격 여부는 전용 unit/UI test에서 자동 판정할 수 있다.

**주요 행위자**: UI 패키지 유지보수자와 검토자

**우선순위 이유**: 사람이 보는 catalog와 회귀를 판정하는 검증 주체를 분리해야 결과의 재현성과 CI 신뢰성을 유지할 수 있다.

**독립 테스트**: UIComponent unit test와 Preview를 target application으로 하는 UI test를 실행해 공개 API, 상태, geometry, 접근성 및 interaction 계약을 판정한다.

**수용 시나리오**:

1. **전제** Preview가 특정 컴포넌트 상태를 재현하는 상태, **실행** 관련 UI test를 실행하면, **결과** 기대 geometry·Dynamic Type·interaction·접근성 결과를 테스트가 자동 판정한다.
2. **전제** Preview와 테스트 책임이 분리된 상태, **실행** Preview 앱 구현을 검사하면, **결과** 앱 내부에 계약 합격을 판정하는 assertion 또는 production-like 테스트 결과 표시가 없다.

---

### 시나리오 4 - 정본과 활성 구현의 동기화 (우선순위: P4)

저장소 유지보수자는 UI 컨벤션 문서, 공개 API, Tuist target·scheme, 테스트 및 추적성 자료가 하나의 변경 단위에서 같은 규칙과 이름을 가리키는지 확인할 수 있다.

**주요 행위자**: 저장소 유지보수자

**우선순위 이유**: 문서와 코드가 서로 다른 컨벤션을 가리키는 과도 상태는 후속 구현과 검토의 기준을 불명확하게 만든다.

**독립 테스트**: 활성 문서·소스·Tuist·scheme·CI 참조를 전수 검색하고 저장소의 UI 관련 build 및 test gate를 실행한다.

**수용 시나리오**:

1. **전제** 기존 문서에 불변 ViewModel 또는 layout harness 표현이 남아 있는 상태, **실행** 마이그레이션을 완료하면, **결과** 활성 정본과 추적성 자료는 직접 입력 및 `UIComponentPreview` 규칙으로 일치한다.
2. **전제** 기존 UIComponent 소비 지점과 테스트가 있는 상태, **실행** 공개 계약과 target 명칭을 변경하면, **결과** 모든 소비 지점이 컴파일되고 관련 required gate가 통과한다.

### 예외·경계 사례

- initializer 인자가 많아도 이를 그대로 복제한 `Model`, `Configuration`, `Props` wrapper로 다시 묶지 않으며 책임 분리·UI 의미 타입·content slot·반복 항목 타입을 먼저 검토한다.
- `Item`, `Option`, `Style`, `Size`, `Variant`는 UI 의미와 stable identity를 표현할 때만 허용하며 Domain entity나 DTO를 복제하면 안 된다.
- 컴포넌트를 재생성했을 때 제품 데이터가 손실되는 상태는 컴포넌트 내부에 둘 수 없다.
- route·프로젝트 식별자 같은 제품 식별자는 호출부 callback이 캡처하며 컴포넌트가 저장하거나 해석하지 않는다.
- 외부 패키지 소비자가 발견되면 장기 deprecated wrapper를 자동 도입하지 않고 별도 호환성 결정을 요구한다.
- historical changelog와 과거 migration 기록의 `UIComponentLayoutHarness` 문자열은 활성 참조로 계산하지 않는다.
- 파일 단위 `#Preview`는 간단한 개발 확인에 유지할 수 있지만 중앙 catalog 등록을 대체하지 않는다.
- Preview fixture는 날짜·난수·네트워크·credential·개인정보에 따라 달라지지 않아야 한다.

## 요구사항 *(필수)*

### 기능 요구사항

- **FR-001**: `UIComponent`의 production component는 component-scoped `ViewModel`을 선언하거나 public initializer 입력으로 사용하지 않아야 한다.
- **FR-002**: `UIComponent`의 public initializer에는 `viewModel:` label 및 initializer 인자를 단순 복제한 `Model`, `Configuration`, `Props` wrapper가 없어야 한다.
- **FR-003**: component는 렌더링에 필요한 최소 presentation value, UI 전용 의미 타입, callback, 승인된 `Binding` 및 content slot을 직접 입력받아야 한다.
- **FR-004**: `UIComponent`의 구현과 public API는 App, Composition, Feature, Domain, Data, Infrastructure, TCA Store, Use Case, 서버 DTO, 네트워크 client 및 session 저장소에 의존하지 않아야 한다.
- **FR-005**: 표시용 파생 값과 제품 의미가 있는 loading·selected·enabled 상태는 Feature 또는 Feature View의 presentation projection 경계에서 계산해 전달해야 한다.
- **FR-006**: 사용자 interaction은 의미가 분명한 callback을 기본으로 전달하고, `Binding`은 즉시 양방향 동기화가 컴포넌트의 본질이며 상위 계층 타입을 노출하지 않는 경우에만 사용해야 한다.
- **FR-007**: `TabShell`은 상위 계층이 선택 상태를 소유하는 `selected + onSelect` controlled contract를 제공하고 production 연결에서 `.constant` selection을 사용하지 않아야 한다.
- **FR-008**: `UIComponentLayoutHarness` target·경로·앱·catalog의 활성 명칭은 각각 `UIComponentPreview` 책임에 맞는 명칭으로 교체되어야 한다.
- **FR-009**: `UIComponentPreview`는 모든 public component를 안정적인 `componentID`, 분류, 지원 variant·size·state 및 재현 factory와 함께 catalog에 등록해야 한다.
- **FR-010**: `UIComponentPreview`는 `UIComponent`와 `DesignSystem`만 프로젝트 모듈 의존성으로 사용하고 로컬의 결정적 fixture만으로 실행되어야 한다.
- **FR-011**: Review·Preview 전용 catalog, chrome, detail 및 fixture 코드는 `UIComponent` production public API와 source inclusion에서 분리되어야 한다.
- **FR-012**: `UIComponentTests`는 public initializer, 기본값, style·size·variant, 상태, callback, 접근성 및 금지 의존 계약을 자동 판정해야 한다.
- **FR-013**: `UIComponentUITests`는 `UIComponentPreview`를 target application으로 사용해 geometry, 기준 폭, 최대 Dynamic Type, 긴 텍스트, interaction 영역, 접근성 요소, appearance, Reduce Motion 및 fallback 계약을 자동 판정해야 한다.
- **FR-014**: Preview 앱은 계약의 합격 여부를 자체 판정하지 않아야 하며 Preview 도달성과 GitIt App 기능 도달성을 별도 결과로 취급해야 한다.
- **FR-015**: 승인된 제품·기술 결정, 공통·기능 요구사항, UI 컨벤션 문서, UIComponent 공개 API, Preview·테스트 구현의 우선순위를 유지하고 충돌하는 활성 문서와 코드를 같은 변경 단위에서 동기화해야 한다.
- **FR-016**: public API 변경 뒤 Feature View, App View, Composite, `#Preview`, catalog, unit/UI test, compilation test, sample 및 활성 문서 예시를 포함한 모든 소비 지점이 새 계약을 사용해야 한다.
- **FR-017**: target 전환 뒤 활성 Tuist 설정, scheme, test plan, UI test host, CI 및 문서에서 legacy 명칭을 제거해야 한다.
- **FR-018**: ViewModel 제거와 Preview 전환은 기존 제품 동작, route, API 계약, Domain 모델, 시각·접근성 의미 및 확정 레이아웃 계약을 변경하지 않아야 한다.

### 핵심 엔터티 *(기능에 데이터가 포함되면 작성)*

- **Component 공개 계약**: component를 생성하는 presentation value, UI 전용 의미 타입, callback, 승인된 `Binding` 및 content slot의 집합이다.
- **Preview catalog 항목**: 안정적인 `componentID`, 표시 이름, Leaf·Composite 분류, 지원 variant·size·state 및 결정적 재현 경로를 가진다.
- **Preview fixture**: 외부 서비스나 제품 계층 타입 없이 component의 특정 공개 상태를 반복 재현하는 로컬 UI 데이터다.
- **자동 검증 계약**: unit/UI test가 판정하는 공개 API, 상태, geometry, interaction, 접근성 및 의존 경계의 기대 결과다.

## 성공 기준 *(필수)*

### 측정 가능한 결과

- **SC-001**: `UIComponent` production component의 component-scoped `ViewModel`, `viewModel:` public initializer 및 동등 aggregate wrapper가 각각 0건이다.
- **SC-002**: `UIComponent`와 `UIComponentPreview`에서 금지된 프로젝트 모듈 import 및 target dependency가 0건이다.
- **SC-003**: 공개 API가 변경된 component 소비 지점의 100%가 새 직접 입력 계약으로 컴파일된다.
- **SC-004**: public UIComponent의 100%를 Preview catalog에서 열 수 있고 각 component의 모든 공개 variant와 명세된 주요 상태를 네트워크·production credential 없이 반복 재현할 수 있다.
- **SC-005**: 활성 Tuist·scheme·test plan·CI·source·문서에서 `UIComponentLayoutHarness` legacy 참조가 0건이며 `UIComponentPreview` target이 생성·빌드·실행된다.
- **SC-006**: Preview 전용 source가 `UIComponent` production target의 generated source 목록에 포함된 건수가 0건이다.
- **SC-007**: 변경 범위의 UI unit test, UI test, lint, source inclusion 및 금지 의존 required gate가 100% 통과한다.
- **SC-008**: 최대 Dynamic Type, 접근성 의미, 최소 44×44pt interaction 영역 및 기존 확정 geometry에 대한 회귀가 0건이다.
- **SC-009**: production `TabShell`의 `.constant` selection 연결이 0건이며 선택 callback 계약 검증이 통과한다.
- **SC-010**: `docs/package-rules/ui.md`와 `docs/conventions/ui-component.md`가 직접 입력 API와 Preview/검증 책임 분리를 일관되게 기술하며, 활성 UI 문서·소스·Tuist 설정 사이의 미해결 충돌이 0건이다.
- **SC-011**: Preview 성공을 GitIt App 기능 구현 완료로 판정하는 활성 문서 또는 CI 결과가 0건이다.

## 가정

- 본 변경의 직접 이해관계자는 UI component를 구현·소비·검토하는 개발자와 디자인 검토자이며 새로운 최종 사용자 기능을 추가하지 않는다.
- 기존 승인된 제품·기술 결정과 공통·기능 요구사항은 본 컨벤션보다 상위 정본이며 제품 상태, API, route, 오류 및 Figma 화면 의미는 변경하지 않는다.
- 접근성 label·value·trait, Dynamic Type, interaction 영역 및 확정 geometry는 제거 대상이 아니라 보존 또는 강화해야 하는 기존 계약이다.
- `DesignSystem`, `UIComponent`, `UIComponentPreview`, UI 관련 Feature·App 소비 지점, 관련 테스트, Tuist 설정과 활성 문서가 마이그레이션 영향 범위다.
- 외부 패키지 소비자는 현재 확인되지 않은 것으로 가정하며 발견 시 호환성 정책을 별도 결정한다.
- snapshot testing library나 새로운 외부 UI library 도입은 범위에 포함하지 않는다.
- U02·U06·U07·U08의 누락 component 신규 구현, Feature reducer 구조 변경, Domain 모델 변경, API 계약 변경 및 GitIt App root·route 구현은 범위 밖이다.
