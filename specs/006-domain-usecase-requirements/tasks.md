---

description: "기능 구현 작업 목록: Git-It 학습 도메인 UseCase 요구사항"
---

# 작업 목록: Git-It 학습 도메인 UseCase 요구사항

**입력**: `/specs/006-domain-usecase-requirements/`의 설계 문서
(plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md)

**선행 조건**: plan.md·spec.md·research.md·data-model.md·contracts/(10개)·quickstart.md
모두 `/speckit-plan`에서 이미 작성 완료됨.

**테스트**: 실행 가능한 코드가 없는 기능이므로 자동화 테스트 작업이 없다. 검증은
`quickstart.md`의 대조 절차(시나리오 A~D)로 대체한다.

**구성**: 이 기능은 spec.md `범위 밖`·plan.md 헌법 점검(원칙 7 "해당 없음")에 명시된
대로 **`sources/**`의 어떤 패키지도 변경하지 않는 문서 전용 산출물**이다. 따라서
Domain → Data → Infrastructure → Composition → UI → Feature → App 패키지 단계는 이
기능에 하나도 적용되지 않는다(적용 대상 패키지 0개). 이미 작성된 산출물
(`data-model.md`, `contracts/`, `quickstart.md`)이 근거 자료와 어긋나지 않는지
확인하는 **읽기 전용 검증 작업만** 남아 있다.

**유즈케이스별 태스크 분리**: `contracts/` 10개 파일 각각을 spec.md 및 서버 스키마
(`docs/Git-It-server-scheme.json`)와 대조하는 작업을, 문서 전체를 한 번에
묶어 검증하지 않고 UseCase 10개 각각 별도 작업(T002~T011)으로 분리했다(사용자 요청).

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 서로 다른 계약 파일을 대상으로 하므로 병렬 실행 가능
- **[시나리오]**: spec.md의 S1(프로젝트 생명주기)·S2(학습 세트 풀이)·S3(북마크 관리)
- **[no-write]**: 파일을 변경하지 않는 대조·확인 작업(이 기능에는 file-write 작업이
  없다 — `data-model.md`·`contracts/`·`quickstart.md`가 이미 완성되어 있기 때문)

## 작업 패키지: 없음 (적용 대상 패키지 0개)

**근거**: plan.md 헌법 점검 "패키지 진행(원칙 7): 해당 없음 — 현재 명세가 변경하는
패키지가 없으므로 게이트가 트리거되지 않는다." 이 기능은 `specs/006-*/` 아래 문서만
생성했고 `sources/**`를 전혀 건드리지 않았다. 승인 게이트를 거칠 구현 패키지 단계가
없으므로, 아래 "전체 완료 검증"이 이 기능의 유일한 실행 단계다.

---

## 전체 완료 검증

**선행 조건**: 없음 — 검증 대상 산출물(`data-model.md`, `contracts/` 10개,
`quickstart.md`)이 모두 이미 존재한다.

### 시나리오 A — UseCase ↔ 계약 파일 1:1 대응 확인 (SC-001)

- [ ] T001 [no-write] spec.md가 정의한 UseCase 10개와
  `specs/006-domain-usecase-requirements/contracts/`의 파일 10개 이름(확장자 제외)이
  정확히 1:1로 대응하는지 확인한다(quickstart.md 시나리오 A). 누락·불일치 0건을 기대한다.

### 시나리오 B+C — UseCase별 계약 ↔ 서버 스키마 ↔ FR 대조 (SC-002, SC-003, SC-004)

- [ ] T002 [P] [S1] `specs/006-domain-usecase-requirements/contracts/fetch-external-repository.md`를
  spec.md FR-001~004와 대조한다. `Git-It-server-scheme.json`의 `paths`에는 대응 엔드포인트가 없는 것이
  정상임을 확인한다(GitHub 공개 API 직접 호출).
- [ ] T003 [P] [S1] `specs/006-domain-usecase-requirements/contracts/create-learning-project.md`를
  `docs/Git-It-server-scheme.json`의 `POST /api/v1/projects`, spec.md FR-005~010과 대조한다. 재등록 멱등성(FR-007)과
  삭제 후 재등록 복원(FR-008) 규칙이 계약에 반영됐는지 확인한다.
- [ ] T004 [P] [S1] `specs/006-domain-usecase-requirements/contracts/fetch-learning-projects.md`를
  `docs/Git-It-server-scheme.json`의 `GET /api/v1/projects`, spec.md FR-011~015와 대조한다. `nextSetId`/`nextQuestionId`
  동시 반환(FR-012)이 반영됐는지 확인한다.
- [ ] T005 [P] [S1] `specs/006-domain-usecase-requirements/contracts/fetch-learning-project-detail.md`를
  `docs/Git-It-server-scheme.json`의 `GET /api/v1/projects/{projectId}`, spec.md FR-016~019와 대조한다. `sets[]`
  기반 다음 세트 판단 규칙(FR-019)이 반영됐는지 확인한다.
- [ ] T006 [P] [S1] `specs/006-domain-usecase-requirements/contracts/delete-learning-project.md`를
  `docs/Git-It-server-scheme.json`의 `DELETE /api/v1/projects/{projectId}`, spec.md FR-020~022와 대조한다. 소유권 비노출
  404(`PROJECT-001`) 통일 처리(FR-022)가 반영됐는지 확인한다.
- [ ] T007 [P] [S2] `specs/006-domain-usecase-requirements/contracts/fetch-learning-set.md`를
  `docs/Git-It-server-scheme.json`의 `GET /api/v1/projects/{projectId}/sets/{setId}`, spec.md FR-023~027과 대조한다.
  `myAnswer` 기반 이어 풀기/재풀이 판단(FR-025)이 반영됐는지 확인한다.
- [ ] T008 [P] [S2] `specs/006-domain-usecase-requirements/contracts/submit-choice-answer.md`를
  `docs/Git-It-server-scheme.json`의 `POST /api/v1/projects/{projectId}/questions/{questionId}/answers/choice`,
  spec.md FR-028~031과 대조한다. 덮어쓰기 제출(FR-030)과 형식 불일치 400(FR-031)이
  반영됐는지 확인한다.
- [ ] T009 [P] [S2] `specs/006-domain-usecase-requirements/contracts/submit-essay-answer.md`를
  `docs/Git-It-server-scheme.json`의 `POST /api/v1/projects/{projectId}/questions/{questionId}/answers/essay`,
  spec.md FR-032~036과 대조한다. 서버 미채점·`rubric` 반환(FR-033~034)이 반영됐는지
  확인한다.
- [ ] T010 [P] [S3] `specs/006-domain-usecase-requirements/contracts/set-question-bookmark.md`를
  `docs/Git-It-server-scheme.json`의 `POST /api/v1/projects/{projectId}/questions/{questionId}/bookmark`,
  spec.md FR-037~039와 대조한다. toggle 미추론·명시적 상태 전달(FR-038)이 반영됐는지
  확인한다.
- [ ] T011 [P] [S3] `specs/006-domain-usecase-requirements/contracts/fetch-bookmarked-questions.md`를
  `docs/Git-It-server-scheme.json`의 `GET /api/v1/projects/bookmarks`, spec.md FR-040~042와 대조한다. `setId` 필수
  포함(FR-041)과 `availableProjects` 전체 반환(FR-042)이 반영됐는지 확인한다.

### 시나리오 D — 명확화 이력 반영 확인

- [ ] T012 [no-write] spec.md `## 명확화` 섹션의 질문 7건 각각이 T002~T011에서 확인한
  `contracts/*.md` 또는 `data-model.md` 문장 중 최소 하나에 반영됐는지 확인한다
  (quickstart.md 시나리오 D). 특히 "저장소당 프로젝트 1개 제한"
  (`create-learning-project.md`), "다음 세트 판단"(`fetch-learning-project-detail.md`),
  "`setId` 필수"(`fetch-bookmarked-questions.md`) 3건을 개별 확인한다.

**검증 결과 보고**: T001~T012 완료 후, 시나리오 A~D 각각의 통과 여부와 발견된 불일치를
사용자에게 보고한다. 불일치가 있으면 `specs/006-domain-usecase-requirements/spec.md`
또는 `contracts/*.md`를 수정해야 하므로 이 tasks.md의 실행을 중단하고 해당 문서
스킬(`/speckit-specify`, `/speckit-plan`)로 되돌아간다.

---

## 의존성과 실행 순서

### 실행 순서

- 적용 대상 패키지가 없으므로(0개) 패키지 승인 게이트도 없다. T001 → (T002~T011,
  병렬 가능) → T012 순서로 한 번에 진행한다.
- T001(전체 파일 목록 대응)을 먼저 완료해야 T002~T011에서 대조할 계약 파일 10개가
  누락 없이 존재함이 보장된다.
- T002~T011은 서로 다른 계약 파일을 대상으로 하므로 순서 무관하게 병렬 실행할 수
  있다.
- T012는 T002~T011의 대조 결과를 입력으로 사용하므로 마지막에 실행한다.

### 패키지 내부 병렬 실행 예시

이 기능에는 적용 대상 패키지가 없으므로 패키지 내부 병렬 규칙은 해당 없다. 대신 위
"전체 완료 검증" 단계 안에서 T002~T011(`[P]`)을 병렬로 실행할 수 있다 — 각 작업이
서로 다른 `contracts/*.md` 파일 하나만 읽어 대조하고 아무 파일도 쓰지 않기 때문이다.

### 변경 시나리오 추적성

- **S1**(프로젝트 생명주기, P1): T002~T006 — FetchExternalRepository,
  CreateLearningProject, FetchLearningProjects, FetchLearningProjectDetail,
  DeleteLearningProject.
- **S2**(학습 세트 풀이, P2): T007~T009 — FetchLearningSet, SubmitChoiceAnswer,
  SubmitEssayAnswer.
- **S3**(북마크 관리, P3): T010~T011 — SetQuestionBookmark,
  FetchBookmarkedQuestions.
- 최소 가치 범위: S1(T001~T006, T012 중 S1 관련 부분)만 먼저 검증해도 spec.md
  시나리오 1의 독립 테스트 기준("이 문서만 읽고 5개 UseCase의 입력·출력·오류를
  재구성할 수 있는지")을 충족하는지 확인할 수 있다.

## 구현 전략

1. T001로 계약 파일 10개가 모두 존재하는지 먼저 확인한다.
2. T002~T011을 병렬로 실행해 UseCase 10개 각각의 계약을 원본 도메인 문서·서버
   스키마·FR과 대조한다.
3. T012로 명확화 이력 7건이 산출물에 반영됐는지 마지막으로 확인한다.
4. 불일치를 하나라도 발견하면 실행을 중단하고 어느 문서(spec.md 또는
   contracts/*.md)를 고쳐야 하는지 사용자에게 보고한 뒤, 해당 스킬로 넘어간다.
5. 모두 통과하면 "완료 보고"에 결과를 정리한다.

## 참고

- 이 tasks.md는 **문서 검증만** 다룬다. 10개 UseCase의 실제 Domain/Data/...
  구현은 spec.md `범위 밖`에 명시된 대로 이 기능의 책임이 아니다.
- 작업 ID는 실제 실행 순서대로 증가한다.
- 문제 해결과 암묵지 기록을 구현 작업 ID로 생성하지 않는다.
