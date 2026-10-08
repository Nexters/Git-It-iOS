# 데이터 모델: Domain·Data·Infrastructure 설계 점검과 문서·네이밍 교정

이 기능의 데이터는 코드가 아니라 점검 결과 문서의 항목이다. 문서 형식은
[contracts/review-record.md](./contracts/review-record.md)가 고정한다.

## 1. 점검 기준

| 필드 | 값 |
| --- | --- |
| 문서 | Constitution, `docs/architecture.md`, `docs/package-rules/{domain,data,infrastructure}.md`, `docs/conventions/naming.md`와 하위, `docs/conventions/abstraction.md`와 `structure-baseline.md`, `docs/conventions/directory-file.md`, `docs/conventions/file-vocabulary.md`와 `shape-vocabulary.md`, `docs/conventions/test.md`, 명세 035 FR-014·FR-017·FR-020 |
| 조항 | 문서 안의 절·표·행 (예: "네이밍 4장 패키지 문맥 표 Data 행") |

기준 문서끼리 충돌하면 AGENTS.md 우선순위로 정본을 정하고 하위 문서를 DOC 항목으로 만든다.

## 2. 발견 항목

| 필드 | 형식 | 규칙 |
| --- | --- | --- |
| ID | `DOC-NN`, `RN-NN`, `DS-NN`, `OK-NN` | 처리 구분별 접두어. 번호는 문서 안에서 유일하고 재사용하지 않는다. 한 research 항목이 여러 선언으로 나뉘면 `RN-07a`처럼 소문자 하위 문자를 붙인다. research 번호가 다른 처리 구분으로 바뀌면(예: RN-11 → `OK-NN`) 그 번호는 비워 두고 새 ID 항목의 근거에 원래 번호를 적는다 |
| 기준 위치 | 1절의 문서와 조항 | 필수 |
| 대상 위치 | 저장소 상대경로(+선언 이름 또는 행) | 필수. 코드는 파일 경로, 문서는 파일과 절 |
| 불일치 설명 | 한 문장 이상 | 재현 가능해야 한다(수용 시나리오 1-1) |
| 처리 구분 | `문서 교정` · `rename` · `후속 설계 변경` · `위반 아님` | 정확히 하나 |
| 근거 | 자유 서술 | `위반 아님`은 필수(FR-004). 예외 조항 또는 외부 고정 명칭 근거 |

### 2.1 처리 구분과 이 기능의 책임

| 처리 구분 | 이 기능에서 | 완료 조건 |
| --- | --- | --- |
| 문서 교정 | 해소 | 대상 문서가 현재 코드와 확정 결정을 설명(FR-005) |
| rename | 해소 | 옛 이름 0건, 동작·시그니처·저장 값 불변(FR-007·FR-008·FR-010) |
| 후속 설계 변경 | 기록만 | 권장 방향·영향 범위 기록(FR-011). 관심사 중복은 3절 추가 필드 |
| 위반 아님 | 기록만 | 근거 기록(FR-004) |

## 3. 관심사 중복 쌍 (`DS-NN`의 하위 종류)

발견 항목 필드에 다음을 더한다.

| 필드 | 값 |
| --- | --- |
| 판정 조건 | `(1)` 책임·연산 1:1 · `(2)` Domain에 비즈니스 로직 없이 Data 구현 래핑 · `(3)` 이름·필드 동일 — 해당하는 것 모두 |
| Domain 선언 | 파일 경로와 타입 이름 |
| Data 선언 | 파일 경로와 타입 이름 |
| 연결 Adapter | `sources/Projects/Composition/**/Adapters/*.swift` 경로 또는 "없음" |
| 권장 방향 | 남길 쪽과 제거할 쪽 |
| 영향 범위 | 제거 시 바뀌는 Composition·Feature·App·테스트 파일 |

## 4. rename 항목의 추가 필드

| 필드 | 값 |
| --- | --- |
| 옛 이름 → 새 이름 | 타입·프로토콜·연산·파일·폴더·target 각각 |
| 참조 패키지 | 옛 이름을 참조하는 패키지 목록 (research 4절) |
| 저장·전송 값 | 영향 없음 또는 불변으로 유지한 key 목록(FR-010) |
| 문서 갱신 | README·structure-baseline·패키지 규칙 중 이름이 바뀌는 곳 |

## 5. 상태 전이

```text
점검 결과 초안(모든 항목 기록)
  → 문서 교정 단위 완료(DOC-* 해소 표시)
  → rename 단위 완료(RN-* 해소 표시, 옛 이름 0건)
  → 전체 검증 완료(SC-001~SC-010 확인 표)
```

후속 설계 변경·위반 아님 항목은 상태가 바뀌지 않는다. 후속 명세가 DS 항목을 소비하면 그
명세가 자기 spec에서 이 문서의 ID를 인용한다(이 문서는 수정하지 않는다).
