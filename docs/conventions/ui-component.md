# Git It iOS UIComponent 컨벤션

**상태**: 초안

**작성일**: 2026-08-21

**최종 수정일**: 2026-09-22 (UIComponent는 컴포넌트에 딸린 선언을 한 파일에 두는 규칙 반영)

## 목적

이 문서는 `UIComponent`의 재사용 가능한 표현 계약을 정의하고 컴포넌트의 역할 분류, 공개
입력, 선언·자산 구성과 검증 방식을 통일합니다. UI 패키지의 책임과 의존 방향은
[UI 패키지 규칙](../package-rules/ui.md)이, 폴더 뎁스와 파일 분할의 공통 규칙은
[디렉터리·파일 컨벤션](./directory-file.md)이 소유하고, 컴포넌트 구현 방식과 역할
폴더의 목록은 이 문서가 소유합니다. 문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/UI/Component/` 아래의 모든 컴포넌트와 역할 폴더
- `sources/Projects/UI/Component/Resources/`의 이미지·애니메이션·일러스트레이션 자산
- `UIComponentPreviewApp`과 UI 자동화 target의 컴포넌트 레이아웃 검증

DesignSystem 토큰의 정의, Feature 화면 상태와 화면 흐름은 이 문서의 범위가 아닙니다.

## 2. 공개 계약

컴포넌트는 화면과 Feature 구현에서 독립적으로 해석 가능한 표현 계약이어야 합니다.

→ [공개 계약](./ui-component/public-contract.md)

## 3. 컴포넌트 역할 분류

컴포넌트는 구현의 복잡도나 화면 안의 위치가 아니라 공개 계약이 드러내는 역할로 분류합니다. 역할이 정해지면 그 컴포넌트가 소유할 수 있는 범위도 함께
정해집니다.

### 3.1 분류 축은 역할입니다

→ [분류 축은 역할입니다](./ui-component/role-axis.md)

### 3.2 판정 순서

→ [판정 순서](./ui-component/role-decision-order.md)

### 3.3 역할별 소유 범위

→ [역할별 소유 범위](./ui-component/role-ownership.md)

### 3.4 현재 컴포넌트 배치

→ [현재 컴포넌트 배치](./ui-component/current-placement.md)

### 3.5 재분류 기준

→ [재분류 기준](./ui-component/reclassification.md)

## 4. 재사용 판단

재사용 가능성은 사용처의 수나 외형의 유사성이 아니라 공개 입력의 의미적 통일성으로 판단합니다.

→ [재사용 판단](./ui-component/reuse.md)

## 5. 파일·선언·자산 구성

컴포넌트의 내부 선언은 컴포넌트 파일 하나에, 자산은 그 컴포넌트의 이름 아래에 모입니다. 컴포넌트 하나를 읽거나 옮길 때 흩어진 자리를 찾아다니지 않게 하기 위한
것입니다.

### 5.1 폴더와 파일

→ [폴더와 파일](./ui-component/folder-file.md)

### 5.2 중첩 선언

→ [중첩 선언](./ui-component/nested-declaration.md)

### 5.3 자산

→ [자산](./ui-component/asset.md)

## 6. 상태와 생성 경로

컴포넌트는 전달받은 값을 렌더링할 뿐 표시 상태의 정본을 소유하지 않습니다. 공개 생성
경로는 [View 컨벤션 — 공개 생성 경로](./view.md#3-공개-생성-경로)가, 외부 상태를
`Binding`으로 보존하는 규칙은
[View 내부 선언 컨벤션 — 외부 상태와 `Binding`](./view-declarations/binding.md)이 소유합니다.

## 7. 분리 절차

컴포넌트 분리는 표현 책임 식별에서 배치 표 갱신까지 정해진 순서로 진행합니다.

→ [분리 절차](./ui-component/extraction.md)

## 8. 검증

공개 입력과 상태별 표현, 레이아웃 계약을 단위 테스트 또는 UI 자동화 테스트로 검증합니다.

→ [검증](./ui-component/verification.md)

## 9. 검토 체크리스트

- [ ] 화면과 Feature 상태에서 독립적으로 설명할 수 있는 표현 계약인가?
- [ ] 외형이 아니라 입력·상태·경계값·접근성 의미로 재사용을 판단했는가?
- [ ] §3.2의 판정 질문을 순서대로 적용해 역할 폴더를 정했는가?
- [ ] 역할 판정 근거가 구현 의존 구조가 아니라 공개 계약인가?
- [ ] §3.4의 배치 표가 실제 폴더와 일치하는가?
- [ ] 폴더 뎁스와 파일 이름이 [디렉터리·파일 컨벤션](./directory-file.md)을 따르는가?
- [ ] 컴포넌트에 딸린 선언이 `+` 분리 파일이나 타입 패밀리 폴더 없이 컴포넌트 파일 하나에 있는가?
- [ ] 자산과 DesignSystem 토큰의 소유 경계가 분리되는가?
- [ ] 레이아웃과 사용자 입력 전달을 독립적으로 검증했는가?

## 관련 문서

- [아키텍처](../architecture.md)
- [UI 패키지 규칙](../package-rules/ui.md)
- [디렉터리·파일 컨벤션](./directory-file.md)
- [파일·형태 어휘 컨벤션](./file-vocabulary.md)
- [View 컨벤션](./view.md)
- [View 내부 선언 컨벤션](./view-declarations.md)
- [네이밍 컨벤션](./naming.md)
- [테스트 컨벤션](./test.md)
- [컴포넌트 인덱스](../../.agents/skills/implement-figma-ui/references/component-index.md)

## 문서 변경 기준

UIComponent의 공개 입력 형태, 역할 폴더의 목록과 판정 순서, 컴포넌트 배치 또는 레이아웃
검증 방식이 바뀔 때 수정합니다. 폴더 뎁스와 파일 분할의 공통 규칙이 바뀌면 이 문서보다
[디렉터리·파일 컨벤션](./directory-file.md)을 먼저 갱신합니다. Figma 노드와 코드
컴포넌트의 대응만 바뀌면 이 문서가 아니라
[컴포넌트 인덱스](../../.agents/skills/implement-figma-ui/references/component-index.md)를
수정합니다.
