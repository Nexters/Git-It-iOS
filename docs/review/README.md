# 설계 점검 문서

이 폴더는 특정 기능이 아니라 **구조 전반**을 대상으로 한 점검 결과와 그에서 도출한 요구사항을 담습니다. 각 요구사항 문서는 그대로 `speckit-specify`의 입력으로 사용할 수 있도록 작성합니다.

## 재설계 요구사항

2026-09-15 설계 점검에서 도출한 5건입니다. 점검 근거 시점은 branch `feature/screen-type-refactor`, commit `bee2388`입니다.

| # | 문서 | 대상 | 상태 |
| --- | --- | --- | --- |
| 1 | [AsyncStream 재설계](./async-stream-redesign-requirements.md) | 동작하지 않는 스트림 제거, 생성 상태 관측 모델 통합 | 초안 |
| 2 | [UseCase 통합](./usecase-consolidation-requirements.md) | UseCase 26개의 분해 기준 확정과 통합 | 초안 |
| 3 | [계층 과잉 축소](./layer-overengineering-requirements.md) | 변화를 흡수하지 않는 프로토콜 계층 제거 | 초안 |
| 4 | [패키지 의존성 원칙 강제](./package-dependency-enforcement-requirements.md) | 의존성 표 자동 검증, CompositionAdapter 수렴점 분할 | 초안 |
| 5 | [Composition 책임 정리](./composition-responsibility-requirements.md) | 조립 경계에 들어온 정책·영속·기동 흐름 반환 | 초안 |

## 결정된 전제

이 5건은 다음 결정 위에서 작성되었습니다. 전제가 바뀌면 해당 문서를 다시 검토해야 합니다.

- **Domain↔Data 경계 구조는 현행을 유지한다.** Domain 계약 ← Composition Adapter → Data API 구조를 바꾸지 않습니다. 이 경계의 축소(Data가 Domain 계약을 직접 구현)는 추후 별도 리팩터링으로 다룹니다.
- **Feature는 단일 target을 유지한다.**
- App → UIComponent 직접 의존은 제거 완료되었습니다.

## 권장 진행 순서

문서 간 의존이 있어 순서가 결과에 영향을 줍니다.

1. **1번 FR-1·FR-2·FR-3** — 죽은 스트림 경로 제거. 다른 문서와 독립이며 2번의 대상을 3개 줄입니다.
2. **4번 FR-1~FR-6** — 의존성 검증 도구 도입. 이후 모든 작업 중 위반 유입을 막습니다.
3. **5번** — Composition에서 정책·영속·기동 흐름 반환.
4. **3번 FR-4·FR-2** — 오류 정리와 Data 계약 제거.
5. **2번** — UseCase 통합. 1·3번이 끝난 뒤 대상이 가장 작아집니다.
6. **1번 FR-4·FR-5** — 생성 상태 모델 통합.
7. **4번 FR-7** — CompositionAdapter 분할. 5번으로 Composition이 가벼워진 뒤 수행합니다.

## 그 밖의 점검 문서

- [Domain UseCase 의도 점검표](./domain-usecase-review.md) — UseCase 26개의 책임·기능·테스트가 의도와 일치하는지 판정하는 체크리스트
- [Domain·Data·Infrastructure 설계 점검 결과](./domain-data-infra-design-review.md) — 세 패키지를 규칙 문서와 명세 035의 패키지 관심사 원칙에 대조한 발견 항목(문서 교정·rename·후속 설계 변경·위반 아님)
- [내부 Swift 타입 인벤토리](./type-naming-inventory/README.md) — 네이밍 점검용으로 프로젝트 소유 타입 전체를 패키지별로 나열하고 설명·단어 분해와 단어 사전을 정리한 자료

## 관련 문서

- [아키텍처](../architecture.md)
- [패키지별 규칙](../package-rules/)
- [공통 컨벤션](../conventions/README.md)
