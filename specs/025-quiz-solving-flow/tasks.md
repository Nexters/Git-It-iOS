# 작업 목록: Task3 학습 세트 풀이 흐름

**입력**: `specs/025-quiz-solving-flow/`의 설계 문서

**선행 조건**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Git 기준선**: `/speckit-implement`를 시작할 때 이 tasks.md의 blob hash와 전체 diff를
snapshot한다. 별도 기준선 commit은 사용자가 요청했거나 협업상 영속 기준선이 필요한 경우에만
선택한다.

**테스트**: 포함한다. 명세가 변경 시나리오마다 독립 테스트를 요구하고 SC-012·SC-014·SC-016·
SC-020·SC-022가 테스트 존재와 통과를 성공 기준으로 지정했다.

**구성**: 실행 단위를 최상위 구조로 사용한다. 순서는 아키텍처 §3.1의 허용 의존성에서 도출한
위상 순서(Domain·Composition → UI → Feature → App)이며, 첫 단위는 분리하면 compile되지 않는
불가분한 integration unit이다.

## 형식: `[ID] [P?] [시나리오?] 설명`

- **[P]**: 현재 실행 단위 안에서만 병렬 실행 가능(서로 다른 파일, 미완료 의존성 없음)
- **[시나리오]**: S1 객관식 풀이 · S2 서술형 · S3 세트 시작 · S4 다음 문제와 완료 ·
  S5 출처 확인 · S6 프로젝트 상세 · S7 북마크 · S8 저장한 문제 다시 풀기
- **[no-write]**: 추적 대상 소스·문서와 Git index를 직접 변경하지 않는 명령 실행 또는 수동
  검증. `make tuist`의 파생 workspace·project·심볼릭 링크·cache 갱신은 허용하되 실행 전후
  Git 상태를 비교하고 추적 파일 변경이 생기면 완료로 처리하지 않는다.

## 실행 단위 소유권 규칙

- 파일 변경 작업은 책임 패키지 단계에 둔다.
- 패키지 1만 다중 패키지 integration unit이며 분리 불가 근거를 해당 단계에 기록한다.
- 공유 Test Double은 둘 이상의 테스트 파일이 쓰는 것만 `TestDoubles/`에 둔다
  ([파일 어휘 컨벤션](../../docs/conventions/file-vocabulary.md)). 한 파일에서만 쓰는 Double은
  그 테스트 파일 안에 `private`으로 둔다. 흐름 fixture는 저장소 선례
  (`Feature/Tests/Home/TestDoubles/HomeTestFixture.swift`)를 따라 같은 폴더에 둔다.

---

## 작업 패키지 1: Domain + Composition (integration unit)

**목표**: Data DTO에 이미 있으나 Domain이 버리는 값(세트 설명, 출처 배열, 기존 답변의 선택
index·정답 여부)을 Domain 모델과 Adapter 매핑에서 복원한다(FR-039).

**분리 불가 근거**: `LearningSet`·`Question`·`QuestionSource`의 이니셜라이저 시그니처가
바뀌면 유일한 호출부인 `LearningSetRepositoryAdapter`를 함께 바꾸지 않는 한 Composition이
compile되지 않는다. 두 변경은 하나의 목적을 가지며 독립적으로 되돌릴 수 없다
(Constitution 원칙 7, [plan.md](./plan.md) §실행 단위).

**소유 경로**:
`sources/Projects/Domain/LearningProject/Models/Quiz/`,
`sources/Projects/Domain/Tests/LearningProject/`,
`sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`,
`sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift`

**관련 변경 시나리오**: S1, S3, S4, S5

**독립 검증**: Domain은 다른 내부 패키지에 의존하지 않고, Composition Adapter 테스트가
DTO → Domain 매핑만으로 복원 결과를 확인한다. UI·Feature·App 없이 두 패키지 테스트로 완결된다.

### 테스트

- [X] T001 [P] [S1] [S4] `sources/Projects/Domain/Tests/LearningProject/Models/Quiz/SubmittedAnswerTests.swift`에 기존 답변이 선택 index·답안 텍스트·정답 여부를 각각 보존하고 서술형의 정답 여부가 비어 있음을 확인하는 테스트를 작성한다
- [X] T002 [P] [S3] [S5] `sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift`에 세트 설명, 출처 배열 전체와 각 출처의 줄 번호·심볼·설명, 기존 답변의 선택 index·정답 여부가 복원되고 배열 순서가 유지되는 테스트를 추가한다 (FR-039, FR-040)
- [X] T003 `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningSetTests.swift`의 fixture를 새 `Question`·`QuestionSource`·`SubmittedAnswer` 이니셜라이저로 갱신한다

### 구현

- [X] T004 [S1] [S4] `sources/Projects/Domain/LearningProject/Models/Quiz/SubmittedAnswer.swift`에 `selectedIndex`, `text`, `correct`를 가진 `SubmittedAnswer` 모델을 신설한다 ([data-model.md §1.4](./data-model.md))
- [X] T005 [P] [S5] `sources/Projects/Domain/LearningProject/Models/Quiz/QuestionSource.swift`에 `startLine`, `endLine`, `symbol`, `summary`를 optional로 추가한다
- [X] T006 [P] [S3] `sources/Projects/Domain/LearningProject/Models/Quiz/LearningSet.swift`에 `description`을 추가한다
- [X] T007 [S1] [S5] `sources/Projects/Domain/LearningProject/Models/Quiz/Question.swift`의 `source: QuestionSource`를 `sources: [QuestionSource]`로 바꾸고 `myAnswer`를 `SubmittedAnswer?`로 바꾼다
- [X] T008 [S3] [S5] `sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift`의 매핑을 [data-model.md §1.5](./data-model.md)의 표대로 복원하고 배열을 재정렬하지 않는다

### 정리와 패키지 검증

- [X] T009 [no-write] Domain과 Composition 테스트 scheme을 실행해 T001~T003이 통과하는지 확인하고 결과를 기록한다

**진행 점검**: T001~T009의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로
진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 2: UI

**목표**: 세트 항목 컴포넌트를 렌더(`s01`) 정본에 맞춰 개편한다(FR-042·042a·042b, D-009).

**소유 경로**: `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift`,
`sources/Projects/UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests.swift`

**관련 변경 시나리오**: S6

**독립 검증**: UI는 Domain·Feature에 의존하지 않고 현재 사용처가 UI 테스트뿐이므로 이 단위
만으로 compile·테스트가 완결된다.

### 테스트

- [X] T010 [S6] `sources/Projects/UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests.swift`를 새 계약(`label`·`title`·`questionCount`·`completedCount`·`onStart`)으로 갱신하고, 탭 가능한 컨트롤이 시작 버튼 하나뿐이며 진행 표시가 문제 수만큼의 세그먼트인지 검증한다 (SC-019, FR-042·042a·042b)

### 구현

- [X] T011 [S6] `sources/Projects/UI/Component/CollectionItems/LearningSetRow/LearningSetRow.swift`를 [data-model.md §2.1](./data-model.md)의 계약으로 개편한다. 카드 전체를 감싼 `Button`을 제거하고 우측 시작 버튼만 조작 단위로 두며, 진행 표시를 `ProgressSegments(completed:total:)`로 바꾸고 `문제 N개` 캡션과 `완료` 배지를 제거한다. 역할 폴더는 `CollectionItems/`를 유지한다 (D-009, FR-050a)

### 정리와 패키지 검증

- [X] T012 [no-write] UI 테스트 scheme을 실행해 T010이 통과하는지 확인하고, 시작 버튼의 hit area가 44pt 이상인지 확인해 결과를 기록한다 (FR-056)

**진행 점검**: T010~T012의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로
진행한다.

---

## 작업 패키지 3: Feature

**목표**: 순차 Router 2개와 화면 Feature 6종으로 풀이 흐름과 프로젝트 상세 흐름을 구성한다
(FR-001~FR-045b, FR-052~FR-056).

**소유 경로**: `sources/Projects/Feature/Quiz/`,
`sources/Projects/Feature/ProjectDetail/`,
`sources/Projects/Feature/Saved/Saved/`,
`sources/Projects/Feature/Tests/Quiz/`,
`sources/Projects/Feature/Tests/ProjectDetail/`,
`sources/Projects/Feature/Tests/Saved/`

**관련 변경 시나리오**: S1, S2, S3, S4, S5, S6, S7, S8

**독립 검증**: Feature는 Domain과 UI에만 의존하므로 App 없이 compile·테스트가 성립한다. 각
화면 Reducer 테스트가 다른 화면의 상태를 준비하지 않고 독립 실행된다(SC-012).

### 준비와 기반

- [X] T013 [P] `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubFetchLearningSetUseCase.swift`에 성공·실패 동작을 지정할 수 있는 Stub을 추가한다 (T023·T031이 함께 사용)
- [X] T014 [P] `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubFetchBookmarkedQuestionsUseCase.swift`에 성공·실패 Stub을 추가한다 (T023·T030이 함께 사용)
- [X] T015 [P] `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSubmitChoiceAnswerUseCase.swift`에 호출 인자를 기록하는 Stub을 추가한다 (T024·T028·T032가 함께 사용)
- [X] T016 [P] `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSubmitEssayAnswerUseCase.swift`에 호출 인자를 기록하는 Stub을 추가한다
- [X] T017 [P] `sources/Projects/Feature/Tests/Quiz/TestDoubles/StubSetQuestionBookmarkUseCase.swift`에 호출 인자를 기록하는 Stub을 추가한다
- [X] T018 [P] `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/StubFetchLearningProjectDetailUseCase.swift`에 성공·실패 Stub을 추가한다 (T029·T032가 함께 사용)
- [X] T019 [P] `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/StubDeleteLearningProjectUseCase.swift`에 성공·실패와 호출 횟수를 기록하는 Stub을 추가한다 (T029·T032가 함께 사용)
- [X] T020 `sources/Projects/Feature/Tests/Quiz/TestDoubles/QuizTestFixture.swift`에 세트 fixture 세 종류(기존 답변 없음 / 앞쪽 문제만 답변 / 전부 답변)와 객관식·서술형 혼합·서술형 전용 세트, 출처가 없는 문제와 출처가 여럿인 문제를 추가한다
- [X] T021 `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/ProjectDetailTestFixture.swift`에 세트 진행이 섞인 프로젝트 상세 fixture와 저장한 문제 목록 fixture를 추가한다

### 테스트

- [X] T022 [P] [S3] [S4] `sources/Projects/Feature/Tests/Quiz/Shared/Models/LearningSetResumptionTests.swift`에 시작 index 판정 3종과 `choiceQuestionCount`·`skippedCorrectChoiceCount` 계산을 검증하는 테스트를 작성한다 (SC-014, SC-016)
- [X] T023 [P] [S3] `sources/Projects/Feature/Tests/Quiz/LearningSetIntro/LearningSetIntroFeatureTests.swift`에 진입 조회 1회, `SetLoad`·`BookmarkLoad` 상태 분리, 두 실패의 오류 의미 보존, 늦은 응답을 `requestID`로 거부, 조회 중 시작 차단, 재시도, `input(.emptySetReported)` 처리, `startRequested` payload를 검증하는 테스트를 작성한다 (FR-032a·b·c)
- [X] T024 [P] [S1] [S2] [S5] [S7] `sources/Projects/Feature/Tests/Quiz/QuestionSolving/QuestionSolvingFeatureTests.swift`에 단일 선택, 미선택·공백 제출 차단, 400자 상한, 제출 중 중복·진행·뒤로가기 차단, 실패 후 draft 보존, 결과 상태 전이, 출처 Sheet 개폐 전후 상태 보존, 빈 출처에서 컨트롤 미노출, `sourceLinkTapped`가 `externalURLRequested`로 나가는지, 북마크 중복 차단과 ID 일치 반영을 검증하는 테스트를 작성한다 (SC-004, SC-005, SC-006, FR-010a·c, FR-035c)
- [X] T025 [P] [S1] `sources/Projects/Feature/Tests/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplayTests.swift`에 선택지 표시 상태가 서버 채점 결과에서만 도출되고 배열 위치·문자로 추론되지 않는지, 결과 상태에서 선택되지 않은 선택지가 중립으로 남는지, 옵션 식별자·선택 여부·색 이외 구별 수단이 접근성 문자열에 담기는지 검증하는 테스트를 작성한다 (SC-007, FR-052, FR-053)
- [X] T026 [P] [S5] `sources/Projects/Feature/Tests/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplayTests.swift`에 출처 배열 전체가 순서대로 변환되고 URL 행이 링크 접근성 문자열을 갖는지 검증하는 테스트를 작성한다 (FR-010b, FR-054)
- [X] T027 [P] [S4] `sources/Projects/Feature/Tests/Quiz/LearningCompletion/LearningCompletionFeatureTests.swift`에 점수 표시 여부와 "객관식 N문제 중 M문제 정답" 형태의 접근성 레이블 문장을 검증하는 테스트를 작성한다 (FR-038, FR-055)
- [X] T028 [P] [S3] [S4] `sources/Projects/Feature/Tests/Quiz/Router/QuizRouterFeatureTests.swift`에 활성 화면 전환, 이동 이벤트의 `from`·`to`·`cause` 기록과 미기록, 문제 화면 뒤로가기가 활성 화면만 되돌리고 child State를 유지하는지, 되돌아온 뒤 `시작하기`가 진행을 이어가는지, 문제 이동 시 이전 상태 미잔류, 건너뛴 정답을 포함한 완료 카운터, 문제 없는 세트 처리, 흐름 이탈 delegate를 검증하는 테스트를 작성한다 (SC-003, SC-014, SC-022, FR-034, FR-035a·b·d)
- [X] T029 [P] [S6] `sources/Projects/Feature/Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests.swift`에 상세 조회, 세트 진행 표시와 라벨 값, `setStartRequested` payload, 저장소 시작 컨트롤이 첫 미완료 세트로 같은 의도를 만드는지, 미완료 세트가 없으면 비활성인지, 메뉴 펼침, `repositoryLinkTapped`의 `externalURLRequested`, 삭제 확인 단계·취소·중복 차단·성공 후 delegate, `input(.refreshRequested)` 재조회가 서버 값을 그대로 반영하는지 검증하는 테스트를 작성한다 (SC-008, SC-017, SC-018, FR-004c, FR-041a, FR-044b·c)
- [X] T030 [P] [S8] `sources/Projects/Feature/Tests/Saved/Saved/SavedFeatureTests.swift`에 프로젝트 필터 고정 시 다른 프로젝트 문제가 포함되지 않는지, 목록 표시에 세트 조회가 발생하지 않는지, 빈 상태·실패·재시도, `solveTapped`만 진입 의도를 만드는지, `isBackControlPresented`가 `false`면 `backRequested`가 발생하지 않는지 검증하는 테스트를 작성한다 (SC-020, FR-044a·a-2·a-6·a-7)
- [X] T031 [P] [S8] `sources/Projects/Feature/Tests/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeatureTests.swift`에 세트 조회 성공 시 대상 문제를 찾아 `questionPrepared`를 보내는지, 문제를 찾지 못하거나 조회가 실패하면 `preparationFailed`를 보내는지, 진행 중 같은 입력을 무시하고 `questionID` 불일치 결과를 거부하는지 검증하는 테스트를 작성한다 (FR-032c, FR-044a-3)
- [X] T032 [P] [S6] [S8] `sources/Projects/Feature/Tests/ProjectDetail/Router/ProjectDetailRouterFeatureTests.swift`에 활성 화면 전환과 이동 이벤트, 저장한 문제 진입 시 프로젝트 필터 고정, 단일 문제 준비 완료 시 전환과 준비 실패 시 미전환, 단일 문제 결과 진행이 목록으로 복귀하는지, 세트 시작·외부 URL·삭제 완료·이탈 delegate가 그대로 상위로 올라가는지 검증하는 테스트를 작성한다 (FR-034, FR-044a-4, FR-045a·b)

### 구현 — 흐름 모델과 Reducer

- [X] T033 [S3] [S4] `sources/Projects/Feature/Quiz/Shared/Models/LearningSetResumption.swift`에 `startIndex`, `choiceQuestionCount`, `skippedCorrectChoiceCount`를 계산하는 값 타입을 추가한다 ([data-model.md §4.1](./data-model.md))
- [X] T034 [S3] `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroFeature.swift`에 [contracts/feature-reducers.md §7](./contracts/feature-reducers.md)의 계약대로 Reducer를 구현하고 `FetchLearningSetUseCase`·`FetchBookmarkedQuestionsUseCase`를 생성자 주입으로 받는다
- [X] T035 [S1] [S2] [S5] [S7] `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingFeature.swift`에 §8의 계약대로 Reducer를 구현하고 `SubmitChoiceAnswerUseCase`·`SubmitEssayAnswerUseCase`·`SetQuestionBookmarkUseCase`를 생성자 주입으로 받는다. 진행 입력은 흐름과 무관하게 `advanceRequested` 하나만 보낸다 (D-004, FR-045b)
- [X] T036 [S4] `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionFeature.swift`에 §9의 계약대로 Reducer를 구현한다
- [X] T037 [S3] [S4] `sources/Projects/Feature/Quiz/Router/QuizRouterFeature.swift`에 §6의 계약대로 `ActiveScreen`, `ScreenTransition`(`from`·`to`·`cause`), child State와 전환 규칙을 구현하고 UseCase 5종을 자식 생성용으로만 전달한다
- [X] T038 [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/ProjectDetailFeature.swift`를 §3의 계약으로 확장한다. 메뉴 3항목, `Deletion` 상태 기계, `resumeTapped`, `repositoryLinkTapped`, `input(.refreshRequested)`와 delegate 5종을 추가하고 `DeleteLearningProjectUseCase`를 생성자 주입에 더한다 (D-012)
- [X] T039 [S8] `sources/Projects/Feature/Saved/Saved/SavedFeature.swift`를 §4의 계약으로 확장한다. `projectFilter`와 `isBackControlPresented`를 **기본값이 있는** 이니셜라이저 인자로 추가해 `MainShellRouterFeature`의 기존 `SavedFeature.State()` 호출부가 그대로 compile되게 하고, `retryTapped`·`backTapped`·`backRequested`를 추가하며 `bookmarkRowTapped`를 `solveTapped`로 바꾼다 (D-016, FR-044a-1)
- [X] T040 [S8] `sources/Projects/Feature/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeature.swift`에 §5의 계약대로 화면 없는 조건부 Feature를 구현하고 `FetchLearningSetUseCase`를 생성자 주입으로 받는다 (D-005)
- [X] T041 [S6] [S8] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouterFeature.swift`에 §2의 계약대로 `ActiveScreen`, `ScreenTransition`, child State와 전환 규칙을 구현하고 UseCase 7종을 자식 생성용으로만 전달한다

### 구현 — 표시 모델

- [X] T042 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplay.swift`에 선택지 표시 상태를 서버 결과에서 파생하는 표시 모델을 추가한다
- [X] T043 [P] [S5] `sources/Projects/Feature/Quiz/QuestionSolving/ViewModels/QuestionSourceDisplay.swift`에 출처 배열을 서브뷰용 표시 값으로 변환하는 표시 모델을 추가한다 (D-008)
- [X] T044 [P] [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/ViewModels/ProjectDetailSetDisplay.swift`에 세트별 라벨·제목·문제 수·완료 수·시작 가능 여부를 파생하는 표시 모델을 추가한다
- [X] T045 [P] [S8] `sources/Projects/Feature/Saved/Saved/ViewModels/SavedQuestionDisplay.swift`에 저장한 문제 항목의 표시 값을 파생하는 표시 모델을 추가한다

### 구현 — 화면과 서브뷰

- [X] T046 [S3] `sources/Projects/Feature/Quiz/LearningSetIntro/LearningSetIntroScreen.swift`와 `sources/Projects/Feature/Quiz/LearningSetIntro/SubViews/LearningSetIntroScreen+ErrorView.swift`에 라벨·제목·설명과 `시작하기` CTA, 로딩 표현, 문제 없음 안내, D-014의 실패 서브뷰를 조립한다
- [X] T047 [S1] [S2] [S7] `sources/Projects/Feature/Quiz/QuestionSolving/QuestionSolvingScreen.swift`에 스크롤 본문, safe area 위 고정 하단 액션(`BookmarkButton` 포함), 결과 상태 CTA 문구를 `advanceActionTitle`에서 읽는 구성, 제출 실패 안내와 재제출 경로를 조립한다
- [X] T048 [P] [S1] [S2] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+QuestionPrompt.swift`에 문제 번호와 질문 서브뷰를 중첩 타입으로 구현한다. `questionNumber`가 없으면 순번을 그리지 않는다
- [X] T049 [P] [S1] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+ChoiceSection.swift`에 `ChoiceOptionDisplay` 배열을 받아 `ChoiceAnswerOption`으로 편집·결과 표현을 구성한다. 중립 선택지를 표현할 수 없는 `ChoiceResultRow`는 쓰지 않는다
- [X] T050 [P] [S2] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+AnswerEditor.swift`에 서술형 입력과 `현재 글자 수 / 400` 표시를 중첩 타입으로 구현한다
- [X] T051 [P] [S2] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+EssayResultSection.swift`에 `나의 답안`과 `AI의 답안` 읽기 전용 카드를 구성한다
- [X] T052 [P] [S5] `sources/Projects/Feature/Quiz/QuestionSolving/SubViews/QuestionSolvingScreen+SourceSheet.swift`에 `SheetSurface`로 `QuestionSourceDisplay` 배열과 `닫기` CTA를 구성하고 URL 행에 링크 접근성 특성을 부여한다 (FR-054)
- [X] T053 [S4] `sources/Projects/Feature/Quiz/LearningCompletion/LearningCompletionScreen.swift`에 완료 제목, `ResourceAnimation(asset: .complete, isLooping: false)`, 점수, 메시지, 하단 CTA를 조립한다 (D-013)
- [X] T054 [S3] [S4] `sources/Projects/Feature/Quiz/Router/QuizRouter.swift`에 `ScreenContainer` 골격과 활성 화면 `switch`를 구현한다
- [X] T055 [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/ProjectDetailScreen.swift`와 `sources/Projects/Feature/ProjectDetail/ProjectDetail/SubViews/ProjectDetailScreen+ErrorView.swift`에 저장소 정보·전체 진행률·세트 목록·삭제 확인 alert와 D-014의 실패 서브뷰를 조립한다
- [X] T056 [P] [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/SubViews/ProjectDetailScreen+RepositorySummaryView.swift`에 저장소 배너·이름·별 수·기술 태그와 시작 컨트롤을 구성한다
- [X] T057 [P] [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/SubViews/ProjectDetailScreen+SetListSection.swift`에 `TagBadge`(라벨)와 `LearningSetRow`를 묶은 세트 항목 목록과 빈 상태를 구성한다 (FR-042)
- [X] T058 [P] [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/SubViews/ProjectDetailScreen+MenuSheet.swift`에 `저장한 문제`·`GitHub에서 보기`·`삭제하기` 항목을 구성하고 삭제 항목에 파괴적 의미의 토큰 색을 적용한다 (FR-044)
- [X] T059 [S8] `sources/Projects/Feature/Saved/Saved/SavedScreen.swift`와 `sources/Projects/Feature/Saved/Saved/SubViews/SavedScreen+ErrorView.swift`에 목록·빈 상태·실패 표현을 조립하고 뒤로가기 컨트롤을 `isBackControlPresented`가 참일 때만 그린다
- [X] T060 [P] [S8] `sources/Projects/Feature/Saved/Saved/SubViews/SavedScreen+QuestionRow.swift`에 문제 본문과 `문제 풀기` 컨트롤만 가진 행 서브뷰를 구현한다 (D-010, FR-044a-2·a-6)
- [X] T061 [S6] [S8] `sources/Projects/Feature/ProjectDetail/Router/ProjectDetailRouter.swift`에 `ScreenContainer` 골격, 활성 화면 `switch`, 단일 문제 진입 overlay와 진입 실패 alert를 구현한다 (D-005)

### 구현 — 프리뷰

- [X] T062 [P] [S3] `sources/Projects/Feature/Quiz/LearningSetIntro/Previews/LearningSetIntroScreenPreviews.swift`에 `s02` 기준 상태와 로딩·실패·문제 없음 프리뷰를 추가한다
- [X] T063 [P] [S1] [S2] [S5] `sources/Projects/Feature/Quiz/QuestionSolving/Previews/QuestionSolvingScreenPreviews.swift`에 `s03`~`s12` 기준 상태와 순번 없는 단일 문제 프리뷰를 추가한다
- [X] T064 [P] [S4] `sources/Projects/Feature/Quiz/LearningCompletion/Previews/LearningCompletionScreenPreviews.swift`에 `s13`과 점수 없는 상태 프리뷰를 추가한다
- [X] T065 [P] [S3] [S4] `sources/Projects/Feature/Quiz/Router/Previews/QuizRouterPreviews.swift`에 활성 화면별 프리뷰를 추가한다
- [X] T066 [P] [S6] `sources/Projects/Feature/ProjectDetail/ProjectDetail/Previews/ProjectDetailScreenPreviews.swift`에 `s01`과 메뉴 펼침·삭제 확인·빈 상태·실패 프리뷰를 추가한다
- [X] T067 [P] [S8] `sources/Projects/Feature/Saved/Saved/Previews/SavedScreenPreviews.swift`에 목록·빈 상태·실패 프리뷰를 추가한다
- [X] T068 [P] [S6] [S8] `sources/Projects/Feature/ProjectDetail/Router/Previews/ProjectDetailRouterPreviews.swift`에 활성 화면별 프리뷰와 진입 실패 alert 프리뷰를 추가한다

### 정리와 패키지 검증

- [X] T069 `sources/Projects/Feature/Quiz/Quiz/QuizFeature.swift`를 삭제한다
- [X] T070 [P] `sources/Projects/Feature/Quiz/Quiz/AnswerEditor.swift`를 삭제한다
- [X] T071 [P] `sources/Projects/Feature/Quiz/Quiz/QuestionPrompt.swift`를 삭제한다
- [ ] T072 [no-write] Feature 테스트 scheme을 실행해 T022~T032가 통과하는지 확인하고 결과를 기록한다

**진행 점검**: T013~T072의 변경 파일과 검증 결과를 보고하고 같은 기능 범위의 다음 실행 단위로
진행한다. 새 범위나 권한이 필요하면 여기서 중단하고 명시적 승인을 요청한다.

---

## 작업 패키지 4: App

**목표**: 두 흐름을 앱 Navigation에 연결하고 외부 URL 열기의 단일 경로를 만든다
(FR-001, FR-010c, FR-043, FR-044b, [contracts/app-navigation.md](./contracts/app-navigation.md)).

**소유 경로**: `sources/Projects/App/GitIt/`, `sources/Projects/App/Tests/GitIt/`

**관련 변경 시나리오**: S3, S4, S6, S8

**독립 검증**: `AppRootFeatureTests`가 상세 표시 → 세트 선택 → 풀이 흐름 표시 → 닫기 후 상세
복귀와 갱신 신호, 외부 URL 단일 경로까지를 `TestStore`로 검증한다.

### 테스트

- [ ] T073 [S6] `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift`에 새로 주입되는 UseCase 5종과 `openExternalURL` 호출을 기록하는 test double을 추가한다
- [ ] T074 [S3] [S4] [S6] [S8] `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift`에 프로젝트 상세 흐름 표시, 세트 선택 시 풀이 흐름 표시, 흐름 종료 시 상세 복귀와 `refreshRequested` 전달, 외부 URL delegate가 `openExternalURL`을 정확히 한 번 호출, 삭제 완료 delegate가 상세 표시를 해제하는지 검증하는 테스트를 추가한다 (SC-002, SC-021)

### 구현

- [ ] T075 [S3] [S4] [S6] [S8] `sources/Projects/App/GitIt/Reducers/AppRootFeature.swift`에 `@Presents` 상세 흐름·풀이 흐름 상태와 [contracts/app-navigation.md §2](./contracts/app-navigation.md)의 delegate 해석을 추가하고, `fetchLearningProjectDetail`·`fetchLearningSet`·`submitChoiceAnswer`·`submitEssayAnswer`·`setQuestionBookmark`와 `openExternalURL`을 생성자 주입으로 받는다
- [ ] T076 [S6] `sources/Projects/App/GitIt/Screens/AppRootView.swift`에 프로젝트 상세 흐름과 그 위의 풀이 흐름 표시를 추가하고 프리뷰 지원의 Noop UseCase를 보강한다
- [ ] T077 [S6] `sources/Projects/App/GitIt/GitItApp.swift`에서 `AppComposition`이 공개하는 UseCase 5종과 `UIApplication.shared.open`을 감싼 `openExternalURL` 클로저를 `AppRootFeature`에 전달한다 (D-011)

### 정리와 패키지 검증

- [ ] T078 [no-write] App 테스트 scheme을 실행해 T074가 통과하는지 확인하고 결과를 기록한다

**진행 점검**: T073~T078의 변경 파일과 검증 결과를 보고하고 전체 완료 검증으로 이어간다.

---

## 전체 완료 검증

**선행 조건**: 작업 패키지 4의 파일 변경 작업을 완료하고, 전체 검증과 hook 결과를 포함할
마지막 커밋 단위를 아직 commit하지 않은 상태여야 한다.

**커밋 경계**: 아래 `[no-write]` 작업은 App 패키지의 마지막 커밋 단위에 배정한다. 모든 검증과
필수 `after_implement` hook(Swift 포맷)을 마친 뒤 그 단위를 최종 commit한다. 읽기 전용 전체
검증은 반복 승인 없이 같은 실행에서 이어서 수행한다.

- [ ] T079 [no-write] `GIT_IT_PROJECT_BUILD_RUNNER`의 `build`·`compile`·`test`를 순서대로 실행하고 결과를 기록한다 (SC-015)
- [ ] T080 [no-write] [quickstart.md §4](./quickstart.md)의 정적 검사 8항목을 확인한다 — 흐름 코드의 `NavigationStack`·`StackState` 0건, 변경 파일 중 `sources/Projects/Data/` 0건, UIComponent 인자의 `Store`·Feature `State`·Domain 모델 0건, `SubViews/` 파일의 `ComposableArchitecture`·Domain import 0건, 새 raw RGB·hex 색상과 임의 Typography 0건, 화면·Feature의 직접 URL 열기 0건, 아키텍처 §3.1 허용 방향 밖 import 0건, 버튼·링크·선택지 hit area 44pt 이상 (SC-003, SC-009, SC-010, SC-011, SC-021, FR-051, FR-056)
- [ ] T081 [no-write] 변경 시나리오 S1~S8의 독립 수용 기준을 [quickstart.md §3·§5](./quickstart.md)로 검증하고, Preview 이름이 `s01`~`s13`과 1:1로 대응하는지, 전부 답변된 세트를 재풀이한 뒤 프로젝트·세트 진행 표시가 감소하거나 초기화되지 않는지, Simulator에서 두 경로(세트 풀이·저장한 문제 단일 풀이)를 확인한다 (SC-001, SC-002, FR-004c)
- [ ] T082 [no-write] [contracts/feature-reducers.md §1](./contracts/feature-reducers.md)의 Reducer별 주입 UseCase 표와 구현된 각 Reducer의 생성자 인자가 일치하는지 대조한다 (SC-013)

## 의존성과 실행 순서

### 실행 단위 순서와 위험 기반 승인

- 채택한 순서: **패키지 1(Domain + Composition) → 패키지 2(UI) → 패키지 3(Feature) →
  패키지 4(App)**. 근거는 아키텍처 §3.1의 허용 의존성(App → Feature·Composition·Domain,
  Composition → Domain, Feature → Domain·UI)이다.
- 패키지 1을 integration unit으로 둔 근거는 위 §작업 패키지 1의 분리 불가 근거와 같다.
  통합 검증은 T009다.
- 패키지 2는 패키지 1과 서로 의존하지 않는다. UI가 Domain에 의존하지 않기 때문이며, 그럼에도
  패키지 3보다 앞에 두는 이유는 `LearningSetRow`의 공개 계약이 바뀌고 그 사용처가 패키지 3에
  생기기 때문이다.
- 패키지 3과 4는 App이 Feature를 참조하는 단방향 의존이므로 순서를 바꾸지 않는다.
- 각 단위의 변경 파일과 검증 결과를 보고하되 같은 기능 범위에서는 반복 승인을 요구하지 않는다.
- 새 범위, 파괴적 작업, remote·외부 상태 변경, 새로운 제품 결정이 필요할 때만 중단하고 명시적
  승인을 요청한다. 이번 범위에서 사전에 식별된 승인 지점은 없다. 구현 중 새 UI 자산이
  필요하다고 판단되면 그 시점에 승인을 요청한다.

### 변경 시나리오 추적성

| 시나리오 | 작업 |
| --- | --- |
| S1 객관식 풀이 | T001, T004, T007, T024, T025, T035, T042, T047, T048, T049, T063 |
| S2 서술형 | T024, T035, T047, T048, T050, T051, T063 |
| S3 세트 시작 | T002, T006, T008, T022, T023, T028, T033, T034, T037, T046, T054, T062, T065, T074, T075 |
| S4 다음 문제와 완료 | T001, T004, T022, T027, T028, T033, T036, T037, T053, T054, T064, T065, T074, T075 |
| S5 출처 확인 | T002, T005, T007, T008, T024, T026, T035, T043, T052, T063 |
| S6 프로젝트 상세 | T010, T011, T018, T019, T029, T032, T038, T041, T044, T055, T056, T057, T058, T061, T066, T068, T073, T074, T075, T076, T077 |
| S7 북마크 | T024, T035, T047 |
| S8 저장한 문제 다시 풀기 | T021, T030, T031, T032, T039, T040, T041, T045, T059, T060, T061, T067, T068, T074, T075 |

- 각 시나리오의 독립 수용 기준은 관련 패키지가 모두 완료된 뒤 T081에서 검증한다.
- 최소 가치 범위: 패키지 1·2와 패키지 3의 S1·S3·S4 작업까지 완료하면 세트 시작 → 객관식 풀이
  → 완료 화면 경로를 Feature 테스트와 Preview로 검증할 수 있다. 여기에도 같은 위험 기반 승인
  기준을 적용하며, 새 권한이 필요하지 않으면 계속 진행한다.

### 실행 단위 내부 실행

- 테스트는 같은 패키지의 구현 전에 작성하고 예상한 이유로 실패하는지 확인한다.
- `[P]`는 현재 실행 단위 안의 서로 다른 파일에만 사용한다. 대표 병렬 묶음은 다음과 같다.
  - 패키지 1: T001, T002 / T005, T006
  - 패키지 3: T013~T019 / T022~T032 / T042~T045 / T048~T052 / T056~T058 / T062~T068 / T070, T071
- 같은 파일을 변경하는 작업과 Red → Green 의존 작업은 순차 실행한다. T003은 T004~T007의
  이니셜라이저 확정에 의존하고, T020·T021은 T013~T019 뒤에 둔다. T047은 T042·T043 이후,
  T055는 T044 이후, T059는 T045 이후에 둔다.
- 서로 다른 실행 단위의 Git index·같은 파일 변경은 병렬 실행하지 않는다.
- `/speckit-implement`는 파일을 수정하기 전에 현재 패키지의 미완료 작업을 하나의 목적과
  독립적인 rollback 경계를 갖는 순서화된 커밋 단위로 묶는다. 각 단위는 포함 작업 ID, 정확한
  파일 경로, 검증과 커밋 메시지를 먼저 제시하고, 검증과 `[X]` 표시를 마친 뒤 해당 파일과 이
  `tasks.md`만 stage·commit한다.
- App 패키지의 마지막 단위는 T079~T082와 필수 `after_implement` hook이 끝날 때까지
  commit하지 않는다.

## 구현 전략

1. tasks.md의 blob hash와 전체 diff를 기준선으로 고정한다.
2. 첫 미완료 실행 단위를 선택하고 미완료 작업을 논리적 커밋 단위로 설계한다.
3. 각 단위의 구현·검증·완료 표시·커밋을 순서대로 완료하고 생성된 커밋을 확인한다.
4. 단위가 커밋되면 변경 파일·검증 결과·커밋을 보고하고 같은 범위의 다음 단위로 이어간다.
5. 새 권한이 필요한 경계가 나타나면 변경을 시작하기 전에 중단하고 승인을 요청한다.
6. App 패키지에서 전체 읽기 전용 검증과 시나리오 수용 검증, 필수 hook을 실행하고 결과를
   재검증한 뒤 마지막 단위를 최종 commit한다.
