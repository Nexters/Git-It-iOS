# 계약: 점검 결과 문서 `docs/review/domain-data-infra-design-review.md`

이 기능의 외부 인터페이스는 후속 명세와 개발자가 읽는 점검 결과 문서 하나다. 문서 구조를
고정해 후속 `speckit-specify`가 항목 ID로 인용할 수 있게 한다.

## 1. 머리부

```markdown
# Domain·Data·Infrastructure 설계 점검 결과

**상태**: 초안 | 완료
**작성일**: YYYY-MM-DD
**근거 시점**: branch `feature/domain-data-infra-design-review`, commit `<sha>`
**명세**: specs/035-domain-data-infra-design-review/spec.md
**판정 기준**: (FR-014·FR-017·FR-020과 명확화 1~6의 요약, 정본 링크)
```

## 2. 절 구성과 표 열

절 순서는 고정한다. 각 표의 열 이름과 순서는 아래와 같으며 빈 값은 `—`로 적는다.

### 2.1 문서 교정 (`DOC-NN`)

| ID | 기준 위치 | 대상 위치 | 불일치 | 상태 |

`상태`는 `해소` 또는 `미해소`. 기능 완료 시 모두 `해소`.

### 2.2 rename (`RN-NN`)

| ID | 옛 이름 | 새 이름 | 종류 | 대상 위치 | 위반 근거 | 참조 패키지 | 저장·전송 값 | 상태 |

`종류`는 `타입`·`프로토콜`·`연산`·`파일`·`폴더`·`target` 중 하나 이상.

### 2.3 후속 설계 변경 (`DS-NN`)

| ID | 대상 | 기준 위치 | 불일치 | 권장 방향 | 영향 범위 |

관심사 중복 쌍은 같은 표에 두되 `대상` 열을 `Domain <타입> ↔ Data <타입>`으로 쓰고, 다음
하위 표를 항목 뒤에 둔다.

| 판정 조건 | Domain 선언 | Data 선언 | 연결 Adapter |

### 2.4 위반 아님 (`OK-NN`)

| ID | 기준 위치 | 대상 위치 | 판정 근거 |

### 2.5 검증 결과

| 성공 기준 | 확인 방법 | 결과 |

SC-001~SC-010 각 행. `결과`는 실제 실행 결과만 적는다(Constitution 원칙 3).

## 3. 불변 조건

- 명세 배경의 예시 5건과 `ExternalRepositoryLocation` 쌍이 항목으로 존재한다(SC-001·SC-007).
- 처리 구분은 ID 접두어와 절 위치로만 표현하고 별도 열로 반복하지 않는다.
- ID는 삭제·재번호하지 않는다. 판정을 바꾸면 새 ID를 만들고 옛 항목의 `상태`/`판정 근거`에
  `→ 새 ID`를 적는다.
- `docs/review/README.md`의 "그 밖의 점검 문서" 목록에 이 문서를 추가한다.
