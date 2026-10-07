# 계약: 화면 구성과 흐름 전환

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

이 문서는 각 화면이 조립하는 UIComponent, 화면 자료(`s01`~`s13`) 대응, 흐름 전환 규칙을
고정한다. 색·치수·타이포는 DesignSystem 토큰만 사용한다(FR-048, SC-011).

## 1. 화면과 자료 대응

| 화면 | 자료 | 기준 상태 |
| --- | --- | --- |
| `ProjectDetailScreen` | `s01` | 저장소 정보·전체 진행률·세트 목록·메뉴 |
| `SavedScreen` | 없음 | 목록·빈 상태·실패 (렌더 미제공, D-010·D-014) |
| `LearningSetIntroScreen` | `s02` | 라벨·제목·설명·`시작하기` |
| `QuestionSolvingScreen` (객관식 편집) | `s03`, `s05`~`s07` | 미선택 / 선택 / 스크롤 |
| `QuestionSolvingScreen` (출처 Sheet) | `s04` | dim + Bottom Sheet |
| `QuestionSolvingScreen` (객관식 결과) | `s08`, `s09` | 정답 / 오답 |
| `QuestionSolvingScreen` (서술형) | `s10`~`s12` | 빈 입력 / 입력 중 / 결과 |
| `LearningCompletionScreen` | `s13` | 완료 |

SC-001은 각 기준 상태에 대응하는 `#Preview` 또는 테스트가 자료 식별자를 이름에 포함하는
것으로 추적한다. `SavedScreen`은 자료가 없으므로 식별자 대신 상태 이름으로 프리뷰를 만든다.

## 2. 화면별 조립

### 2.1 `ProjectDetailScreen` (`s01`)

- 골격: `ProjectDetailRouter`의 `ScreenContainer` 안, `ScreenHeader`(뒤로가기 + 메뉴)
- 저장소 요약: `ResourceImage`(배너·로고), 저장소 이름, 별 수, 기술 태그(`TagBadge`),
  우측 시작(play) 컨트롤 — 서브뷰 `+RepositorySummaryView`
- 전체 진행률: `LabeledProgressBar`(우측 `N%` 라벨)
- 세트 목록: 서브뷰 `+SetListSection`이 `ProjectDetailSetDisplay` 배열을 받아 `LearningSetRow`
  를 반복 배치한다. 넘기는 값은 `label`·`title`·`questionCount`·`completedCount`·`onStart`
  (data-model §2.1)
- 비어 있는 목록: `EmptyState`
- 메뉴: `isMenuPresented`에 따라 `저장한 문제` / `GitHub에서 보기` / `삭제하기`를 펼친다.
  `삭제하기`는 파괴적 의미가 드러나는 토큰 색을 쓴다(FR-044)
- 삭제 확인: 이 화면이 소유하는 alert. `Deletion.confirming`에서 표시하고 취소·확인 두 입력을
  가진다(FR-044c, D-012)
- 실패: 화면 전용 `+ErrorView` 서브뷰(제목·안내·`다시 시도`) — D-014
- 시작 컨트롤은 미완료 세트가 없으면 비활성으로 둔다(FR-041a)

### 2.2 `SavedScreen` (신규)

- 골격: 조합하는 Router의 골격 안, `ScreenHeader`. 뒤로가기 컨트롤은 `isBackControlPresented`가
  `true`일 때만 그린다(셸 흐름에서는 그리지 않는다)
- 본문: `SavedQuestionDisplay` 배열을 서브뷰 `+QuestionRow`로 반복 배치한다. 각 행은 문제
  본문과 `문제 풀기` 컨트롤만 갖는다(FR-044a-6). 행 본문은 탭 대상이 아니다(FR-044a-2)
- 빈 목록: `EmptyState`
- 실패: 화면 전용 `+ErrorView` 서브뷰(FR-044a-7, D-014)
- 이 행을 UI 컴포넌트로 승격하는 기준은 D-010에 있다

### 2.3 `LearningSetIntroScreen` (`s02`)

- 골격: Router의 `ScreenContainer` 안, `ScreenHeader`(뒤로가기)
- 본문: `TagBadge`(라벨), 제목·설명 `StyledText`
- 하단: `BottomActionBar` + `ActionButton.primary("시작하기")`
- 조회 중·실패는 본문 영역에서 표시하고 CTA는 비활성으로 둔다(FR-002b). 실패는 화면 전용
  `+ErrorView` 서브뷰(D-014)
- 문제가 없는 세트로 판정되면(`isEmptySetReported`) 본문에 문제 없음 안내를 표시하고 CTA는
  동작하지 않는다

### 2.4 `QuestionSolvingScreen` (`s03`~`s12`)

- 본문(스크롤 영역, FR-007): 문제 번호·질문(서브뷰 `+QuestionPrompt`), 답안 영역,
  출처 진입 컨트롤. `questionNumber`가 `nil`이면 순번을 그리지 않는다(단일 문제)
  - 객관식 편집·결과: 서브뷰 `+ChoiceSection`이 `ChoiceOptionDisplay` 배열을 받아
    `ChoiceAnswerOption`으로 그린다. `state`는 `.default` / `.selected` / `.correct` /
    `.incorrect`이며 결과 상태에서 선택되지 않은 나머지 선택지는 `.default`로 남는다.
    `ChoiceResultRow`의 `Judgement`는 `.correct`/`.incorrect` 둘뿐이라 중립 선택지를 표현할 수
    없으므로 사용하지 않는다(FR-013 재검토 결과)
  - 객관식 결과의 AI 해설: 서버 응답 문자열
  - 서술형 편집: 서브뷰 `+AnswerEditor`(placeholder, `현재 글자 수 / 400`)
  - 서술형 결과: 서브뷰 `+EssayResultSection`(`나의 답안`, `AI의 답안` 카드)
- 하단 고정(FR-008): `BottomActionBar` + `BookmarkButton` + `ActionButton`
  (편집 상태 `확인`, 결과 상태 `advanceActionTitle`). `safeAreaInset(edge: .bottom)`으로 본문
  스크롤과 분리하고 bottom inset을 확보한다
- 제출 실패: 하단 액션 위에 실패 안내와 재제출 경로를 둔다
- 출처 Sheet: `sheet(isPresented:)` + `SheetSurface`. 서브뷰 `+SourceSheet`가
  `QuestionSourceDisplay` 배열을 받아 설명·위치·URL 행·외부 링크 아이콘과 하단 `닫기` CTA를
  구성한다(FR-010b). URL 행은 `Link`가 아니라 콜백 컨트롤이므로 링크 접근성 특성을 명시적으로
  부여한다(FR-054, D-011)
- 접근성: 선택지는 식별자와 선택 여부, 결과는 색 이외 수단(기호·레이블), 북마크는 저장 상태.
  터치 대상은 44pt 이상(FR-052~FR-056)

### 2.5 `LearningCompletionScreen` (`s13`)

- 골격: `ScreenHeader`(닫기)
- 본문: 완료 제목, `ResourceAnimation(asset: .complete, isLooping: false)` 완료 애니메이션
  (D-013), 점수, 완료 메시지
- 하단: `BottomActionBar` + `ActionButton`
- `choiceQuestionCount == 0`이면 점수 영역을 그리지 않는다(FR-038)

### 2.6 Router View가 소유하는 것

| Router | 골격 | 흐름 공용 표현 |
| --- | --- | --- |
| `QuizRouter` | `ScreenContainer` | 없음 |
| `ProjectDetailRouter` | `ScreenContainer` | 단일 문제 진입 중 overlay, 진입 실패 alert (D-005) |

두 Router View 모두 활성 화면 값을 `switch`해 화면을 그리고, 각 화면의 Store는 Router State가
보유하는 child state에서 `scope`로 얻는다(Navigation 컨벤션 §2.3).

## 3. 흐름 전환과 이동 이벤트

### 3.1 `Quiz` 흐름

| 사건 | 활성 화면 | 이동 이벤트 |
| --- | --- | --- |
| 흐름 진입 | `learningSetIntro` | 초기값이므로 기록하지 않음 |
| `시작하기` (문제 있음) | `questionSolving` | 기록 (`cause: .startRequested`) |
| 다음 문제로 이동 | 변화 없음 | 기록하지 않음 (시나리오 4-2) |
| 출처 Sheet 개폐 | 변화 없음 | 기록하지 않음 (시나리오 5-4) |
| 문제 화면 뒤로가기 | `learningSetIntro` | 기록 (`cause: .backRequested`) |
| 되돌아온 뒤 `시작하기` | `questionSolving` | 기록 (`cause: .startRequested`). child State는 유지(FR-035d) |
| 마지막 문제 결과에서 진행 | `learningCompletion` | 기록 (`cause: .advancedToCompletion`) |
| 세트 시작 화면 뒤로가기 | 변화 없음 | 기록하지 않음. Router `delegate`로 이탈 |
| 완료 화면 닫기·CTA | 변화 없음 | 기록하지 않음. Router `delegate`로 이탈 |

### 3.2 `ProjectDetail` 흐름

| 사건 | 활성 화면 | 이동 이벤트 |
| --- | --- | --- |
| 흐름 진입 | `projectDetail` | 초기값이므로 기록하지 않음 |
| `저장한 문제` 선택 | `savedQuestions` | 기록 (`cause: .savedQuestionsRequested`) |
| `문제 풀기` → 준비 완료 | `singleQuestion` | 기록 (`cause: .singleQuestionPrepared`) |
| `문제 풀기` → 준비 실패 | 변화 없음 | 기록하지 않음. 흐름 공용 alert |
| 단일 문제 결과에서 `완료` | `savedQuestions` | 기록 (`cause: .singleQuestionFinished`) |
| 저장한 문제 목록 뒤로가기 | `projectDetail` | 기록 (`cause: .backRequested`) |
| 세트 시작 요청 | 변화 없음 | 기록하지 않음. Router `delegate`로 App에 위임 |
| 프로젝트 상세 뒤로가기 | 변화 없음 | 기록하지 않음. Router `delegate`로 이탈 |

### 3.3 공통 규칙

- 뒤로가기는 활성 화면 값을 이전 값으로 되돌리는 상태 전이이며 child State를 새로 만들지
  않는다(FR-035a).
- 되돌아갈 이전 화면이 없는 뒤로가기와 완료 화면의 닫기는 흐름 이탈이다(FR-035b).
- 답안 제출 중에는 뒤로가기를 무시한다(FR-035c).
- 이동 이벤트는 테스트 검증 수단이며 production 로깅으로 내보내지 않는다(FR-034a).

## 4. 금지 사항 (검증 대상)

- 흐름 코드에 `NavigationStack`·`StackState` 사용 0건 (SC-003)
- 화면 자료의 예시 문구·옵션 위치·`A`~`D` 문자에 의존하는 분기 0건 (FR-006, FR-018, SC-007)
- UIComponent에 `Store`·Feature `State`·Domain 모델 전달 0건 (SC-010)
- 서브뷰 파일에 `ComposableArchitecture`·Domain 패키지 import 0건 (View 컨벤션 §4.3, D-008)
- 새로 추가된 raw RGB·hex 색상 리터럴과 화면 임의 Typography 선언 0건 (SC-011)
- 화면 또는 Feature가 외부 URL을 직접 여는 경로 0건 (SC-021)
- 세트 항목 본문 전체를 `Button`으로 감싼 구현 0건 (SC-019)
