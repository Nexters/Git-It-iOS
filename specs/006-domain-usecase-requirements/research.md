# 조사: Git-It 학습 도메인 UseCase 요구사항

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md)

이 기능은 소스 코드를 변경하지 않는다(spec.md `범위 밖`, `/speckit-plan` 사전 확인 질문 답변).
따라서 이 조사는 기술 스택 선택이 아니라, `data-model.md`·`contracts/`·`quickstart.md`를
어떤 형식으로 산출해야 후속 UseCase별 구현 스펙이 재조사 없이 바로 쓸 수 있는지를 결정한다.

## 1. `contracts/` 형식 — UseCase별 Markdown 계약 문서 (10개)

**결정**: `Git-It-server-scheme.json`(OpenAPI 3.x) 전체를 그대로 노출하지 않고,
`sources/docs/git-it-domain-usecases/`의 UseCase 이름과 1:1 대응하는 Markdown 계약 파일을
10개 작성한다. 각 파일은 HTTP 메서드·경로, 요청(경로·쿼리·바디), 성공 응답 필드, 오류
응답(HTTP 상태·서버 오류 코드·조건), spec.md의 관련 `FR-XXX`를 포함한다.

**근거**:
- `Git-It-server-scheme.json`은 118KB, 3개 태그(Project/Member/Auth) 전체를 포함해
  이 기능이 다루는 10개 UseCase보다 훨씬 넓다. 후속 구현자가 매번 전체 파일을 다시 열어
  10개 중 필요한 부분만 골라내는 재작업을 없애는 것이 이 계획의 목적이다.
- 기존 프로젝트 관례(`specs/003-http-client/contracts/http-client-api.md`,
  `specs/004-in-memory-cache/contracts/in-memory-cache-api.md`)가 이미 "공개 계약을
  Markdown 한 개(또는 대상 단위별 여러 개) 문서로 정리"하는 패턴을 쓰고 있다.
- UseCase 단위로 파일을 나누면 후속 `/speckit-specify`가 UseCase 하나를 골라 시작할 때
  그 파일 하나만 읽으면 되고, 다른 UseCase 변경이 이 파일에 영향을 주지 않는다.

**검토한 대안**:
- OpenAPI YAML/JSON 조각으로 UseCase별 파일을 만드는 방안 — 기계 판독성은 높지만, 이
  프로젝트의 Spec Kit 산출물은 원칙 6(한국어 Spec-Kit 산출물)에 따라 한국어 설명이
  필요하고, 기존 contracts/ 관례도 Markdown이므로 일관성이 떨어져 기각했다.
- 계약 전체를 `contracts/`에 파일 1개로 통합하는 방안 — 10개 UseCase의 요청/응답/오류가
  뒤섞여 후속 구현자가 자신이 담당할 UseCase 하나만 골라 읽기 어려워져 기각했다.

## 2. `data-model.md` 구조 — 서버 응답 스키마를 따르는 개념 모델(Swift 타입 아님)

**결정**: spec.md `핵심 엔터티`의 9개 항목을 필드 표로 확장하되, 아직 Swift 타입(구조체,
enum)으로 확정하지 않고 "표현하는 의미 + 필드 + 출처(서버 스키마 필드명)"만 기록한다.
실제 Domain 모델·DTO 설계는 후속 UseCase별 계획 단계에서 결정한다.

**근거**: 이 기능은 어떤 패키지도 구현하지 않으므로(헌법 점검 참고), Swift 타입을 미리
확정하면 후속 구현자의 설계 자유를 제한하고 이 문서가 실제로 구현되지 않을 세부사항(예:
struct 이름, 접근 제어자)까지 떠안게 된다. 서버 필드명과 의미만 정본으로 남기는 편이
`sources/docs/naming.md`의 책임 기반 네이밍 원칙과도 맞다 — 실제 이름은 그 타입을 소유할
패키지가 문맥에 맞게 정한다.

**검토한 대안**: Swift `struct`/`enum` 초안을 미리 작성하는 방안 — 004-in-memory-cache처럼
이 기능 자체가 그 타입을 구현한다면 적절하지만, 006은 구현하지 않으므로 초안이 실제 구현과
어긋날 위험(및 그 어긋남을 검증할 코드가 없다는 위험)이 더 크다고 판단해 기각했다.

## 3. `quickstart.md` 검증 방식 — 문서 대조 체크리스트(실행 명령 없음)

**결정**: 이 기능에는 실행할 코드가 없으므로, `quickstart.md`는 "이 산출물 3종이
`git-it-domain-usecases`·`Git-It-server-scheme.json`·`spec.md`와 어긋나지 않는지"를
사람이 대조 확인하는 절차로 작성한다. 각 단계는 구체적인 파일 경로 대조로 끝나 재현 가능하다.

**근거**: `spec.md`의 성공 기준(SC-001~004)이 이미 "문서 커버리지 100%"를 요구하고
있어, quickstart의 검증 대상도 코드 동작이 아니라 문서 커버리지가 되는 것이 자연스럽다.

**검토한 대안**: 스크립트로 FR-XXX ↔ contracts 파일 매핑을 자동 검증하는 방안 — 유용하지만
이 계획이 스크립트(소스)를 만들 수 있는 허용 경로가 아니므로(헌법 점검, 허용 수정 경로)
범위 밖으로 두고 사람이 따라 할 수 있는 수동 절차만 남겼다.

## 4. NEEDS CLARIFICATION 해소 여부

`spec.md`는 `/speckit-clarify` 3회 세션을 거쳐 [NEEDS CLARIFICATION] 표식이 남아있지
않은 상태로 확정됐다(`checklists/requirements.md` 16/16 통과). 이 계획의 기술 맥락에도
해소되지 않은 `NEEDS CLARIFICATION`이 없다.
