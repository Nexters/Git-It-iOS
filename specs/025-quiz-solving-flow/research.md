# 조사: Task3 학습 세트 풀이 흐름

**기능 브랜치**: `feature/quiz-solving-flow`

**작성일**: 2026-09-03

**입력**: [spec.md](./spec.md) (FR 98 · SC 22), 프로젝트 컨벤션, 저장소 현재 구현

이 문서는 계획이 내린 설계 결정과 근거를 기록한다. 명세가 이미 확정한 제품 결정은
반복하지 않고, **어떤 구조로 구현할지**만 다룬다.

## D-001 — 흐름을 두 개의 순차 Router로 나눈다

**결정**: `Quiz` 흐름(`QuizRouterFeature`)과 `ProjectDetail` 흐름
(`ProjectDetailRouterFeature`)을 각각 순차 Router로 둔다.

**근거**: FR-031이 "화면이 둘 이상인 흐름"에 Router를 요구하고, 명확화 이후 두 흐름 모두
화면이 둘 이상이 되었다. `Quiz`는 세트 시작·문제·완료 3화면, `ProjectDetail`은 상세·저장한
문제 목록·단일 문제 3화면이다. [Navigation 컨벤션 §2.3](../../docs/conventions/tca/navigation.md)의
순차 흐름 정의(정해진 순서로 이어지는 여정, `ScreenContainer` 골격, 흐름 차원 뒤로가기 있음,
이동 이벤트 기록)에 두 흐름 모두 부합한다.

**검토한 대안**: `ProjectDetail`을 Router 없이 화면 하나로 유지하고 저장한 문제 목록과 단일
문제를 App이 표시 — App이 Feature 내부 여정을 알게 되어 FR-035·Feature 패키지 규칙("다른
Feature의 목적지 생성과 앱 전체 Navigation 정책을 소유하지 않는다")과 어긋난다.

## D-002 — 두 Router의 상하 관계는 App이 표시로 해결한다

**결정**: `ProjectDetailRouterFeature`가 `QuizRouterFeature`를 조합하지 않는다. 상세 흐름은
`delegate(.learningSetRequested(projectID:setID:label:))`를 App에 올리고, App이 상세 흐름 위에
풀이 흐름을 표시한다.

**근거**: Navigation 컨벤션 §2.1은 "Feature 바깥으로 이동해야 하면 delegate를 출력하고 App이
목적지와 전환 방식을 결정"하도록 한다. 풀이 흐름은 상세 흐름의 내부 여정이 아니라 별도 흐름
이며, 완료 후 상세로 복귀해 진행 표시를 갱신해야 하므로(FR-043, FR-004c) 두 흐름이 계층으로
공존하는 표시가 필요하다. Router 중첩은 이 요구를 만족시키지 못한다.

**검토한 대안**: 상세 Router의 활성 화면에 풀이 흐름 case 추가 — 활성 화면 값이 다른 흐름의
Router를 품게 되어 §2.3의 "Router는 화면 Feature들의 조합과 전환만 책임진다"를 벗어난다.

## D-003 — `QuestionSolvingFeature`는 `Quiz` 흐름이 소유하고 상세 흐름이 조합한다

**결정**: 화면과 Feature는 `Feature/Quiz/QuestionSolving/`에 두고,
`ProjectDetailRouterFeature`가 같은 Feature를 `Scope`로 조합해 단일 문제 화면에 사용한다.

**근거**: FR-045a가 복제를 금지하고 한 흐름만 소유하도록 요구한다. Navigation 컨벤션 §2.3의
"Router는 **다른 target의 흐름 진입 Feature도 조합할 수 있습니다**"가 근거이며, 같은 target
안의 다른 흐름은 더 약한 조건이다. 배치는
[디렉터리·파일 컨벤션 §4.3](../../docs/conventions/directory-file.md)의 "화면 폴더는 Screen
하나와 Feature 하나를 1:1로 담습니다"를 그대로 지킨다.

**검토한 대안**: `Shared/`로 승격 — `Shared/`는 "여러 화면이 함께 쓰는 선언"을 담는 자리이고
화면 폴더가 아니므로 Screen·Feature 쌍을 둘 수 없다.

## D-004 — 화면 Feature가 흐름을 알지 않도록 진행 의도를 하나로 통일한다

**결정**: `QuestionSolvingFeature`의 결과 상태 진행 입력은 흐름과 무관하게 항상
`delegate(.advanceRequested)` 하나를 보낸다. 하단 컨트롤 문구는 State가 주입받은 표시 값
(`advanceActionTitle`)으로 렌더링하고, 다음 문제·완료 화면·목록 복귀의 결정은 각 Router가 한다.

**근거**: FR-045b는 조합되는 화면 Feature가 흐름을 알지 않고 종료 의미를 delegate로만 알리도록
요구한다. 세트 문맥의 `다음`(FR-026~FR-028)과 단일 문제의 `완료`(FR-044a-4)를 화면 Feature
안에서 분기하면 이 요구를 위반한다.

**검토한 대안**: `delegate(.nextRequested)`와 `delegate(.finishRequested)`를 모두 두고 State의
모드 값으로 선택 — 화면 Feature가 흐름 종류를 상태로 갖게 되어 같은 이유로 배제한다.

## D-005 — 단일 문제 진입 조회는 화면 없는 조건부 Feature가 맡는다

**결정**: `SingleQuestionEntryFeature`를 두어 `FetchLearningSetUseCase`로 세트를 조회하고
`questionID`에 해당하는 문제를 찾아 `delegate(.questionPrepared(...))`로 Router에 알린다. 진입
중 표시와 실패 표시는 `ProjectDetailRouter` View가 흐름 공용 overlay·alert로 소유한다.

**근거**: FR-044a-3은 단일 문제 데이터를 세트 조회 결과에서 찾도록 하지만, Router는 화면
Feature의 조합과 전환만 책임지므로(§2.3) UseCase를 직접 호출할 수 없다. `SavedFeature`에
조회를 넣으면 그 Feature가 흐름을 알게 되어 FR-045b에 어긋나고 FR-044a-6(추가 조회 금지)이
말하는 목록 표시 책임과도 섞인다. §2.3은 "상위로 나가야 하는지가 여러 신호의 조합이나 추가
단계에 달려 있으면 그 판단만 하는 얇은 조건부 Feature를 둔다"는 패턴을 제공하며, 화면 전환
조건을 만드는 얇은 Feature라는 점에서 같은 자리다. 흐름 공용 overlay·alert를 Router View가
소유하는 것도 §2.3이 명시한다.

**검토한 대안**: `QuestionSolvingFeature`가 스스로 조회 — 세트 문맥에서는 Router가 이미 문제를
쥐고 있어 조회가 불필요하므로 흐름별 분기가 생긴다(FR-045b 위반).

## D-006 — 이동 이벤트에 전환 원인을 담는다

**결정**: `ScreenTransition`을 `from`·`to`·`cause` 세 값으로 정의하고, `cause`는 전환을 유발한
Action을 식별하는 흐름별 enum으로 둔다.

**근거**: FR-034와 Navigation 컨벤션 §2.3이 "전환 이전 화면, 전환 이후 화면과 **전환을 유발한
Action을 식별할 수 있는 값**"을 함께 요구한다. Action 자체를 담으면 State가 Action을 보관하게
되어 [State 컨벤션 §2](../../docs/conventions/tca/state.md)의 저장 금지 목록에 가까워지므로
식별 enum으로 축약한다.

## D-007 — 조회 상태를 operation별로 분리하고 요청 식별을 보존한다

**결정**: `LearningSetIntroFeature`는 `setLoad: SetLoad`와 `bookmarkLoad: BookmarkLoad`를 각각
enum으로 갖는다. 두 enum 모두 `failed(LearningProjectError)`를 보존하고, `SetLoad`는
`loading(requestID:)`·`loaded`에 요청 식별 값을 함께 둔다.

**근거**: FR-032a(병행 operation 분리), FR-032b(실패는 오류 의미와 복구 경로 보존),
FR-032c(대체 가능한 요청의 식별)와 State 컨벤션 §3·§4가 같은 내용을 요구한다.
`isBookmarkLoadFailed: Bool`은 오류 의미를 버려 FR-032b에 어긋난다.

## D-008 — 서브뷰에는 표시 모델만 넘긴다

**결정**: 출처 Sheet 서브뷰에 `[QuestionSource]`를 넘기지 않고
`QuestionSolving/ViewModels/QuestionSourceDisplay.swift`를 추가해 화면이 변환한 표시 값을
넘긴다. 선택지는 기존 `ChoiceOptionDisplay`, 세트 항목은 `ProjectDetailSetDisplay`,
저장한 문제 항목은 `SavedQuestionDisplay`가 같은 역할을 한다.

**근거**: [View 컨벤션 §4.3](../../docs/conventions/view.md)은 서브뷰가 `SwiftUI`·
`DesignSystem`·`UIComponent`·`Foundation`만 import할 수 있고 Domain 모델을 입력으로 쓸 수
없다고 규정하며 이를 기계적 확인 기준으로 삼는다. 디렉터리 컨벤션 §4.3의 `ViewModels/`가
"화면이 Feature `State`에서 파생해 서브뷰에 넘기는 표시 모델"의 자리다.

## D-009 — `LearningSetRow`를 렌더 정본에 맞춰 개편하고 역할을 재판정한다

**결정**: `LearningSetRow`의 공개 계약을 `label`·`title`·`questionCount`·`completedCount`·
`onStart`로 바꾼다. 카드 전체를 감싸던 `Button`을 제거하고 우측 시작 버튼만 조작 단위로 두며,
진행 표시는 기존 `ProgressSegments(completed:total:)`로 그린다. 역할 폴더는
`CollectionItems/`를 유지한다.

**근거**: FR-042·042a·042b가 렌더(`s01`)를 정본으로 요구한다. FR-050a와
[UIComponent 컨벤션 §3.2](../../docs/conventions/ui-component.md)의 판정 순서를 다시 적용한
결과, 표시 값(라벨·제목·진행)을 모두 지우면 카드가 남지 않고 버튼만 남으므로 이 컴포넌트는
`AccountActionRow`형(조작 중심)이 아니라 `SettingRow`형(정보 표시 중심)이다. 따라서 순서 3
`Controls/`가 아니라 순서 4 `CollectionItems/`가 맞다. 현재 사용처가 UI 테스트뿐이어서 계약
변경의 파급이 없다.

**검토한 대안**: `Controls/`로 이동 — 카드가 조작 단위 자체가 아니므로 판정 질문을 만족하지
못한다.

## D-010 — 저장한 문제 항목은 화면 전용 서브뷰로 시작한다

**결정**: 저장한 문제 목록의 행을 UI 패키지 컴포넌트로 만들지 않고
`SavedScreen+QuestionRow` 서브뷰로 둔다.

**근거**: UIComponent 컨벤션 §4는 재사용을 사용처 수가 아니라 공개 입력의 의미적 통일성으로
판정하되, [View 컨벤션 §4.3](../../docs/conventions/view.md)은 "재사용 가능한 표현이면 서브뷰로
만들지 않고 컴포넌트로 옮긴다"고 한다. 이번 범위에서 이 행을 쓰는 화면은 하나이고 MainShell
`saved` 탭 화면은 범위 밖이므로, 두 번째 사용처가 생기는 시점을 승격 기준으로 남긴다.

## D-011 — 외부 URL 열기는 App의 단일 주입 경로를 쓴다

**결정**: `GitItApp`이 `openExternalURL` 클로저를 `AppRootFeature`에 주입하고, Feature는
`delegate`로 URL 의도만 올린다. 각 Router는 자식의 URL delegate를 자신의 delegate로 그대로
올린다.

**근거**: FR-010c·FR-044b·SC-021이 단일 경로를 요구한다. 저장소에는 같은 형태의 선례가 있다 —
`GitItApp`이 `openNotificationSettings` 클로저를 주입한다. Feature 패키지 규칙은 Infrastructure
기술 API 참조를 금지하므로 `UIApplication`을 Feature가 직접 부를 수 없다.

**검토한 대안**: 출처 URL 행만 SwiftUI `Link`로 처리 — 링크 특성은 자동으로 얻지만 열기 경로가
둘로 갈라져 SC-021을 만족하지 못한다. 대신 FR-054가 요구하는 링크 특성을 명시적으로 부여한다.

## D-012 — 삭제 확인은 기존 `Deletion` 상태 기계를 준용한다

**결정**: `ProjectDetailFeature`에 `Deletion` enum(`idle`/`confirming`/`committing`/`failed`)과
`DeleteLearningProjectUseCase`를 둔다. 확인 표현은 그 화면이 소유하는 alert다.

**근거**: FR-044c가 확인 단계·취소·중복 방지를 요구하고, State 컨벤션 §3이 바로 이 형태를
예시로 제시하며 `ProjectListFeature`에 동일 구현이 있다. 메뉴 펼침은 payload가 없고 두 경우만
있으므로 같은 예시의 `isMenuPresented`처럼 `Bool`로 둔다.

## D-013 — 완료 화면은 기존 완료 애니메이션 자산을 쓴다

**결정**: 정지 일러스트가 아니라 `ResourceAnimation(asset: .complete, isLooping: false)`으로
렌더링한다(사용자 확정, 2026-09-03). 새 자산을 추가하지 않는다.

**근거**: FR-030이 asset 이름 직접 해석을 금지하고 UIComponent 표현 API를 요구하는데,
`ResourceAnimation`이 바로 그 표현 API이고 `Asset.complete` 케이스가 이미 존재한다
(`UI/Component/Displays/ResourceAnimation.swift`). 완료는 한 번만 재생되어야 하는 사건이므로
`isLooping: false`를 쓴다 — 같은 파일의 프리뷰가 동일한 조합을 사용한다.

**검토한 대안**: `ResourceImage.Asset.illust`의 기존 케이스 — 렌더(`s13`)의 완료 표현을 정지
이미지로 대체하게 되어 실제 디자인과 어긋난다.

## D-014 — 실패 표현은 화면 전용 `+ErrorView` 서브뷰로 통일한다

**결정**: 세트 시작·프로젝트 상세·저장한 문제 목록의 조회 실패는 각 화면의 `+ErrorView`
서브뷰(제목·안내·`다시 시도`)로 표시한다. 구성은 기존 `AppEntryScreen+ErrorView`와 같다.

**근거**: 명세 §예외·경계 사례가 "실패 전용 화면 디자인은 자료가 없으므로 기존 공통 오류
표현을 재사용한다"고 하고, FR-044a-7도 기존 공통 표현 재사용을 명시한다.

## D-015 — 실행 단위 위상 순서에 UI를 넣는다

**결정**: Domain+Composition → UI → Feature → App 순으로 구현한다.

**근거**: [아키텍처 §3.1](../../docs/architecture.md)의 허용 의존성이 `Feature → Domain, UI`,
`Composition → Domain`, `App → Feature·Composition·Domain`이다. UI는 Domain에 의존하지 않으므로
Domain+Composition 단위와 독립이지만 Feature보다 먼저 와야 한다(D-009의 계약 변경을 Feature가
사용한다).

## D-016 — `Saved`는 독립 흐름으로 두고 두 Router가 조합한다

**결정**: `SavedFeature`를 `Feature/Saved/Saved/`에 그대로 두고 같은 폴더에 `SavedScreen`을
추가한다. `MainShellRouterFeature`(셸 흐름)와 `ProjectDetailRouterFeature`(순차 흐름)가 각각
이 Feature를 조합한다. 흐름마다 달라지는 값은 `projectFilter`와 `isBackControlPresented` 두
표시 값뿐이며, 두 인자 모두 기본값을 두어 기존 호출부의 compile을 유지한다.

**근거**: FR-045a는 여러 흐름이 같은 화면을 쓰면 한 흐름만 소유하도록 요구한다. `SavedFeature`
는 `MainShell`이 이미 조합하고 있으므로 `ProjectDetail`로 옮기면 셸 흐름이 다른 흐름의 화면
폴더를 참조하게 된다. 화면이 하나뿐인 흐름에는 Router를 두지 않는다는 Navigation 컨벤션
§2.3에 따라 `Router/` 없이 화면 폴더만 완성한다. 뒤로가기 컨트롤 표시 여부를 상태로 주입하는
방식은 D-004와 같으며, 화면 Feature가 흐름 종류를 알지 않게 한다(FR-045b).

**검토한 대안**: `ProjectDetail/Saved/`로 이동 — `MainShellRouterFeature`가 `ProjectDetail`
흐름 폴더의 화면 Feature를 조합하게 되어 흐름 소유가 뒤집힌다.
