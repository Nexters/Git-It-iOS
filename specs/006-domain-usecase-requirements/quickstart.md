# 빠른 시작: Git-It 학습 도메인 UseCase 요구사항 검증

**날짜**: 2026-08-19 | **명세**: [spec.md](./spec.md) | **계획**: [plan.md](./plan.md)

이 기능은 실행 가능한 코드를 만들지 않는다(spec.md `범위 밖`). 아래 절차는 이 계획이
산출한 `data-model.md`·`contracts/`가 근거 자료(`Git-It-server-scheme.json`,
`spec.md`)와 어긋나지 않는지 사람이 대조 확인하는
검증 가이드다. 자동화 스크립트는 이 계획의 허용 수정 경로 밖이라 포함하지 않는다
(research.md §3).

## 사전 준비

- [spec.md](./spec.md) — 기능 요구사항(FR-001~042)과 명확화 이력
- [data-model.md](./data-model.md) — 엔터티 정의
- [contracts/](./contracts/) — UseCase별 계약 10개
- `docs/Git-It-server-scheme.json` — Git-It 서버 OpenAPI 스키마

## 시나리오 A — UseCase ↔ 계약 파일 1:1 대응 확인 (SC-001)

1. spec.md가 정의한 UseCase 10개의 이름을 나열한다.
2. `contracts/` 아래 파일 10개의 이름을 나열한다.
3. 두 목록이 파일명 기준(확장자 제외) 정확히 1:1로 대응하는지 확인한다.

**기대 결과**: 누락되거나 짝이 맞지 않는 UseCase가 0개.

## 시나리오 B — 계약이 서버 스키마와 일치하는지 확인 (SC-002, SC-003)

각 `contracts/<usecase>.md`에 대해:

1. 문서에 적힌 HTTP 메서드·경로를 `Git-It-server-scheme.json`의 `paths`에서 찾는다
   (`FetchExternalRepository`만 예외 — Git-It 서버가 아닌 GitHub 공개 API를 호출하므로
   `paths`에 대응 항목이 없는 것이 정상이다).
2. 요청 필드(경로·쿼리·바디)가 해당 엔드포인트의 `parameters`/`requestBody` 스키마와
   이름·타입이 일치하는지 확인한다.
3. 성공 응답 필드가 `responses.200`(또는 관련 `$ref` 스키마)과 일치하는지 확인한다.
4. 오류 표에 나열한 HTTP 상태·코드가 `responses`의 `4xx`/`5xx` 항목과 일치하는지
   확인한다.

**기대 결과**: 9개 계약(FetchExternalRepository 제외)이 스키마와 완전히 일치하고,
불일치가 있다면 spec.md `예외·경계 사례` 또는 `가정`에 이미 그 불일치가 기록돼 있다
(예: `quizLevel`/`selectedIndex`가 스키마상 `required`가 아닌 점).

## 시나리오 C — FR ↔ 계약 상호 참조 확인 (SC-004)

1. `spec.md`의 `FR-001`부터 `FR-042`까지 각 번호가 정확히 하나의 `contracts/*.md`
   파일 머리말(`**명세**: ... FR-xxx~yyy`)에 포함되는지 확인한다.
2. 비어 있는 FR 구간(어느 계약에도 속하지 않는 번호)이 있는지 확인한다.

**기대 결과**: FR-001~042가 빠짐없이 정확히 하나의 계약 파일에 배정된다.

## 시나리오 D — 명확화 이력이 계약에 반영됐는지 확인

1. `spec.md`의 `## 명확화` 섹션에서 질문 7건을 확인한다.
2. 각 답변이 최소 하나의 `contracts/*.md` 또는 `data-model.md` 문장에 반영됐는지
   확인한다 — 특히 "저장소당 프로젝트 1개 제한"(`create-learning-project.md`),
   "다음 세트 판단"(`fetch-learning-project-detail.md`), "`setId` 필수"
   (`fetch-bookmarked-questions.md`).

**기대 결과**: 7건 모두 최소 하나의 산출물에서 확인된다.

## 다음 단계

이 검증을 통과하면, 10개 UseCase 중 하나를 골라 그 `contracts/<usecase>.md`와
`data-model.md`의 관련 엔터티만 입력으로 별도의 `/speckit-specify`를 실행해 후속
구현 스펙을 시작한다(spec.md `범위 밖`).
