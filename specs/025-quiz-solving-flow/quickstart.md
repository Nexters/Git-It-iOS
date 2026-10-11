# 빠른 시작: Task3 학습 세트 풀이 흐름 검증

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

이 문서는 구현 결과를 확인하는 절차만 다룬다. 상태·Action 계약은
[contracts/feature-reducers.md](./contracts/feature-reducers.md), 화면 조립은
[contracts/screen-flow.md](./contracts/screen-flow.md), 모델은
[data-model.md](./data-model.md), 설계 근거는 [research.md](./research.md)를 본다.

## 1. 사전 준비

```sh
make init
```

workspace가 없으면 `sources`에서 `tuist generate`를 먼저 실행한다. 흐름 폴더를 추가해도
Tuist 매니페스트는 바꾸지 않는다(디렉터리·파일 컨벤션 §7).

## 2. 빌드와 테스트

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
"$project_build_runner" build
"$project_build_runner" compile
"$project_build_runner" test
```

세 명령은 순차 실행을 전제로 `sources/DerivedData/PreCommit`을 공유한다. 기본 테스트
destination은 `platform=iOS Simulator,name=iPhone 17 Pro`이며 `GIT_IT_TEST_DESTINATION`으로
덮어쓴다. SC-015는 이 세 명령의 통과로 확인한다.

## 3. 자동화 검증 항목

| 확인 | 대상 테스트 |
| --- | --- |
| 시작 지점 판정 3종(미응답 없음 / 앞쪽만 답변 / 전부 답변) | `Tests/Quiz/Shared/Models/LearningSetResumptionTests` (SC-016) |
| 완료 카운터 3종(혼합 세트 / 서술형만 / 건너뛴 정답 포함) | 같은 파일 + `Tests/Quiz/Router/QuizRouterFeatureTests` (SC-014) |
| 세트 조회와 북마크 조회의 상태 분리, 실패 의미 보존, 요청 식별 | `Tests/Quiz/LearningSetIntro/LearningSetIntroFeatureTests` (FR-032a~c) |
| 제출 중 중복 차단, 미선택·공백 제출 차단, 400자 상한 | `Tests/Quiz/QuestionSolving/QuestionSolvingFeatureTests` (SC-004, SC-005) |
| 결과 의미 역할이 서버 응답에서만 도출 | `Tests/Quiz/QuestionSolving/ViewModels/ChoiceOptionDisplayTests` (SC-007) |
| 출처 Sheet 개폐 전후 상태 보존 | `Tests/Quiz/QuestionSolving/QuestionSolvingFeatureTests` (SC-006) |
| 뒤로가기가 활성 화면만 되돌리고 child State를 유지 | `Tests/Quiz/Router/QuizRouterFeatureTests` (SC-022, FR-035a·d) |
| 활성 화면 전환과 이동 이벤트의 `from`·`to`·`cause` | 같은 파일 (SC-003, FR-034) |
| 세트 목록 진행 표시와 라벨 | `Tests/ProjectDetail/ProjectDetail/ProjectDetailFeatureTests` (SC-008) |
| 삭제 확인 단계·취소·중복 차단 | 같은 파일 (SC-018, FR-044c) |
| 저장소 시작 컨트롤과 세트 항목 시작 컨트롤이 같은 진입 의도를 만든다 | 같은 파일 (SC-017, FR-041a) |
| 저장한 문제 목록의 프로젝트 필터 고정과 추가 조회 없음 | `Tests/Saved/Saved/SavedFeatureTests` (SC-020) |
| 단일 문제 준비 성공·실패와 기존 답변 미복원 | `Tests/ProjectDetail/SingleQuestionEntry/SingleQuestionEntryFeatureTests` (FR-044a-3·5) |
| 상세 흐름 활성 화면 전환과 단일 문제 종료 시 목록 복귀 | `Tests/ProjectDetail/Router/ProjectDetailRouterFeatureTests` (FR-044a-4) |
| 상세 표시 → 세트 선택 → 풀이 → 닫기 후 갱신, 외부 URL 단일 경로 | `App/Tests/GitIt/Reducers/AppRootFeatureTests` (SC-002, SC-021) |
| DTO 값 복원 매핑 | `Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests` (FR-039) |
| 세트 항목 컴포넌트의 라벨·세그먼트·단일 조작 단위 | `UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests` (SC-019, FR-042·042a·042b) |

각 화면 Reducer 테스트는 다른 화면의 상태를 준비하지 않고 독립 실행한다(SC-012).

## 4. 정적 검사 항목

`[no-write]` 검증에서 다음을 확인한다.

| 확인 | 기준 |
| --- | --- |
| 흐름 코드의 `NavigationStack`·`StackState` | 0건 (SC-003) |
| 변경 파일 중 `sources/Projects/Data/` 경로 | 0건 (SC-009) |
| UIComponent 인자로 전달된 `Store`·Feature `State`·Domain 모델 | 0건 (SC-010) |
| 서브뷰 파일(`SubViews/`)의 `ComposableArchitecture`·Domain import | 0건 (D-008) |
| 새 raw RGB·hex 색상 리터럴과 화면 임의 Typography | 0건 (SC-011) |
| 화면·Feature의 직접 URL 열기(`UIApplication.shared.open`, `openURL`, `Link`) | 0건 (SC-021) |
| 새 import가 아키텍처 §3.1 허용 방향 밖 | 0건 (FR-051) |
| 세트 시작 화면을 거치지 않고 문제 화면으로 진입하는 경로 | 0건 (SC-017) |
| 버튼·링크·선택지의 hit area | 44pt 이상 (FR-056) |

## 5. 수동 확인

Preview로 기준 상태를 확인한다. 프리뷰 이름에 자료 식별자를 포함해 SC-001의 1:1 추적을
만든다.

| Preview | 확인 |
| --- | --- |
| `ProjectDetailScreenPreviews` | 목록·메뉴 펼침·삭제 확인·빈 상태·실패 (`s01`) |
| `SavedScreenPreviews` | 목록·빈 상태·실패 (자료 없음) |
| `LearningSetIntroScreenPreviews` | 라벨·제목·설명·CTA, 로딩·실패·문제 없음 (`s02`) |
| `QuestionSolvingScreenPreviews` | 객관식 미선택·선택·정답·오답, 서술형 빈 입력·입력 중·결과, 출처 Sheet, 단일 문제(순번 없음) (`s03`~`s12`) |
| `LearningCompletionScreenPreviews` | 점수 있음 / 점수 없음 (`s13`) |

Simulator에서 두 경로를 각각 한 번 직접 확인한다.

1. 프로젝트 상세 → 세트 시작 → 문제 풀이 → 뒤로가기 → 다시 시작(진행 유지 확인) → 완료 →
   상세 복귀
2. 프로젝트 상세 → 메뉴 → 저장한 문제 → `문제 풀기` → 제출 → `완료` → 목록 복귀

긴 질문·긴 선택지에서 하단 고정 액션이 본문 터치 영역을 가리지 않는지, 서술형 입력 중
키보드가 CTA와 글자 수 표시를 가리지 않는지 함께 본다.

## 6. 포맷

Swift 포맷은 빌드 시 `FormatSwift` 플러그인이 적용한다. 셸 스크립트를 바꾸지 않았다면
`tools/script-*` 검증은 실행하지 않는다. 커밋 전 staged 파일과 포맷 결과가 다르면 pre-commit이
커밋을 막으므로 변경 파일을 다시 stage한다. 훅을 우회하지 않는다.
