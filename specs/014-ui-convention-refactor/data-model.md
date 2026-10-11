# 데이터 모델: UI 패키지 컨벤션 정본화

이 기능은 영속 데이터나 서버 schema를 추가하지 않는다. 아래 모델은 public UI contract와 Preview/test 상태를 일관되게 구현·검증하기 위한 설계 모델이다.

## 1. Component 공개 계약

### 필드

- `presentationValues`: 문자열, 숫자, 이미지·animation asset, progress와 표시 상태
- `semanticTypes`: component가 소유하는 `Style`, `Size`, `Variant`, `Item`, `Option`
- `eventCallbacks`: 한 번의 사용자 interaction을 상위로 전달하는 closure
- `externalBindings`: 즉시 양방향 동기화가 component 본질인 값
- `contentSlots`: 호출부가 제공하는 자유로운 하위 View

### 검증 규칙

- initializer 인자를 단순 복제한 aggregate wrapper는 허용하지 않는다.
- Domain, DTO, Feature State/Action, Store, Use Case와 route 의미는 포함하지 않는다.
- `Item`과 `Option` identity는 목록 순서와 독립적으로 안정적이어야 한다.
- 제품 의미 상태는 상위 계층이 계산하며 local state는 재생성해도 제품 데이터가 손실되지 않는 시각 상태만 허용한다.

## 2. ComponentCatalogEntry

### 필드

- `componentID`: UI test route와 catalog 탐색에 사용하는 안정적 고유 문자열
- `displayName`: 개발자에게 보이는 component 이름
- `category`: `leaf | composite`
- `supportedVariants`: 공개 `Style`/`Variant` 목록
- `supportedSizes`: 공개 `Size` 목록
- `supportedStates`: enabled, disabled, selected, loading, empty 등 실제 공개 상태 목록
- `previewFactory`: local fixture와 environment로 View를 생성하는 경로

### 관계와 검증 규칙

- public View 하나는 정확히 하나 이상의 catalog entry에 연결된다.
- `componentID`는 catalog 전체에서 고유하며 rename을 명시적으로 결정하지 않는 한 유지한다.
- 공개 variant·size·주요 state는 최소 한 개의 fixture에서 재현돼야 한다.
- catalog completeness는 production public View 집합과 등록 집합의 차이가 0건인지 판정한다.

## 3. ComponentPreviewFixture

### 필드

- `fixtureID`: entry 안에서 안정적인 상태 식별자
- `displayValues`: 현재 시각 상태를 재현하는 최소 값
- `interactionState`: callback count, selection 등 UI test가 관찰할 local 상태
- `environment`: appearance, Dynamic Type, Reduce Motion, 긴 텍스트, fallback 조건

### 상태 전이

```text
catalog entry 선택 → fixture 선택 → environment 적용 → component 렌더링
component interaction → local marker 갱신 → UI test 또는 개발자가 결과 관찰
environment 변경 → 동일 fixture 재생성 → 제품 데이터 부작용 없음
```

### 검증 규칙

- 네트워크, 날짜, 난수, production credential, 개인정보를 사용하지 않는다.
- Domain·DTO·Feature 타입을 생성하지 않는다.
- test marker는 관찰 가능한 상태만 노출하며 합격 여부를 계산하지 않는다.

## 4. TabShellSelection

### 필드

- `selected`: 상위 소유자가 전달한 현재 `TabShellItem`
- `onSelect`: 사용자가 새 항목을 선택했을 때 호출되는 callback
- `content`: 선택된 항목의 content를 생성하는 slot

### 상태 전이

```text
selected=A + user selects B → onSelect(B) 1회
selected=A + parent updates B → B가 선택된 상태로 렌더링
```

### 검증 규칙

- production에서 `.constant(selected)`를 사용하지 않는다.
- component가 별도 제품 selection 원본을 소유하지 않는다.
- Preview fixture만 callback 결과를 local state에 반영할 수 있다.

## 5. UIContractScenario

### 분류

- `publicAPI`: 직접 입력, default, variant/size mapping, clamp와 callback
- `geometry`: frame, inset, spacing, radius와 scrollability
- `interaction`: tap, disabled 차단, selection과 pass-through
- `accessibility`: label, value, trait, element grouping과 44×44pt 영역
- `environment`: 최대 Dynamic Type, 긴 텍스트, light/dark, Reduce Motion, fallback
- `boundary`: forbidden import/dependency, Preview source inclusion과 legacy 이름

### 검증 규칙

- 각 scenario는 Preview fixture ID 또는 source/target boundary와 연결된다.
- Preview는 scenario 결과를 판정하지 않고 test target이 expected outcome을 소유한다.
- build, build-for-testing과 test body 성공은 서로 대체하지 않고 별도로 기록한다.
