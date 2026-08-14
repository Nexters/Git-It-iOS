# 데이터 모델: InMemoryCache

**날짜**: 2026-08-15 | **명세**: [spec.md](./spec.md) | **조사**: [research.md](./research.md)

명세의 핵심 엔터티를 `InfrastructureCache` target이 소유하는 타입으로 옮긴 결과입니다.

## 엔터티 대응

| 명세의 핵심 엔터티 | 타입 |
| --- | --- |
| 캐시 저장소 | `InMemoryCache<Key, Value>` |
| 캐시 항목 | 공개 타입 없음 — `InMemoryCache` 내부 `Dictionary<Key, Value>`의 키-값 쌍으로만 존재한다(research.md §4) |

## `InMemoryCache<Key, Value>`

키-값 쌍을 프로세스 메모리 범위에서만 보관하는 범용 기술 API입니다(FR-001, FR-009).

| 항목 | 내용 |
| --- | --- |
| 종류 | `actor`(research.md §1) |
| 제네릭 제약 | `Key: Hashable & Sendable`, `Value: Sendable`(research.md §2) |
| 내부 상태 | `Dictionary<Key, Value>` 하나(research.md §4) |
| 근거 | FR-001, FR-002, FR-004~FR-012 |

### 상태 전이

| 시작 상태 | 연산 | 종료 상태 |
| --- | --- | --- |
| 키 `k`에 값 없음 | 저장(`k`, `v`) | 키 `k`에 값 `v` |
| 키 `k`에 값 `v1` | 저장(`k`, `v2`) | 키 `k`에 값 `v2`(FR-004) |
| 키 `k`에 값 `v` | 제거(`k`) | 키 `k`에 값 없음(FR-005) |
| 키 `k`에 값 없음 | 제거(`k`) | 변화 없음, 오류 없음(FR-007) |
| 임의 상태 | 전체 비우기 | 모든 키에 값 없음(FR-006) |
| 키 `k`에 값 없음 | 조회(`k`) | `nil` 반환, 오류 없음(FR-003) |
| 키 `k`에 값 `v` | 조회(`k`) | `v` 반환(FR-002) |

### 검증 규칙

- 저장·조회·제거·전체 비우기는 서로 다른 `InMemoryCache` 인스턴스의 상태에 영향을 주지 않는다(FR-012).
- 동시에 발생한 여러 연산은 `actor`의 상호 배제에 의해 순차 처리된 것과 동일한 최종 상태를 만든다(FR-008).
- `InMemoryCache`는 Domain·Data가 소유한 어떤 구체 타입도 알지 못하며, 제네릭 매개변수로만 값을 다룬다(FR-010, FR-011).
