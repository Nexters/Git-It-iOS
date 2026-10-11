# Git It iOS TCA 컨벤션 — State

**상태**: 초안

**작성일**: 2026-08-31

**최종 수정일**: 2026-08-31 ([TCA 컨벤션](./README.md)에서 분리)

## 목적

이 문서는 Feature `State`가 소유하는 정본의 범위, 배타·병행 상태의 표현 방식, 교체
가능한 요청을 식별하는 방법과 화면 로컬 SwiftUI 상태의 허용 조건을 정의합니다.
Feature 분리 기준은 [Feature 컨벤션](./feature.md), `Action` 설계는
[Action 컨벤션](./action.md)이 소유합니다.

문서 우선순위, 문서 구조와 문서 간 참조 규칙은
[컨벤션 공통 원칙](../common/README.md)이 소유합니다.

## 1. 적용 범위

- `sources/Projects/Feature/**`의 Feature `State` 설계에 적용합니다.
- `sources/Projects/Feature/Tests/**`의 `TestStore` 기반 테스트 중 State 검증에
  적용합니다.
- Feature 분리 기준과 `Action` 설계는 [Feature 컨벤션](./feature.md)·
  [Action 컨벤션](./action.md)이 적용 범위를 소유합니다.

## 2. 정본과 파생값

`State`는 Presentation 상태와 화면 흐름에 필요한 최소 정본만 소유하고, 정본에서 계산할 수 있는 값은 저장하지 않습니다.

→ [정본과 파생값](./state/source-of-truth.md)

## 3. 상태 형태

`isDeleting`, `pendingDeletion`과 `isDeletionLoading`처럼 하나의 배타 프로세스를 여러 프로퍼티로 나눠 유효하지 않은
조합을 만들지 않습니다.

→ [상태 형태](./state/shape.md)

## 4. 요청 식별

새 요청이 이전 요청을 대체할 수 있으면 State가 request identity를 보존하고 현재 요청과 일치하는 결과만 반영합니다.

→ [요청 식별](./state/request-identity.md)

## 5. SwiftUI 로컬 상태

`@State`와 `@FocusState`는 다음 조건을 모두 만족할 때만 화면에 둘 수 있습니다.

→ [SwiftUI 로컬 상태](./state/swiftui-local.md)

## 6. 검토 체크리스트

- [ ] State가 최소 정본만 저장하고 파생값, dependency, Task와 Effect를 저장하지 않는가?
- [ ] 배타 상태는 `enum`, 병행 가능한 operation은 별도 상태로 표현하는가?
- [ ] 교체 가능한 요청에 request identity가 있고 늦은 결과를 거부하는가?
- [ ] SwiftUI 로컬 상태가 §5의 다섯 조건을 모두 만족하는가?

## 관련 문서

- [아키텍처](../../architecture.md)
- [TCA 컨벤션](./README.md)
- [Feature 컨벤션](./feature.md)
- [Action 컨벤션](./action.md)
- [Effect 컨벤션](./effect.md)
- [Feature 패키지 규칙](../../package-rules/feature.md)

## 문서 변경 기준

`State`의 정본 범위, 상태 형태 표현 방식, 요청 식별 방식 또는 SwiftUI 로컬 상태 허용
조건이 바뀔 때 수정합니다. Feature 분리 기준이 바뀌면 이 문서가 아니라
[Feature 컨벤션](./feature.md)을, `Action` 설계가 바뀌면
[Action 컨벤션](./action.md)을 갱신합니다.
