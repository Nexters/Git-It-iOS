# OverlayContainer 이관 결정 리포트

작성일: 2026-09-04 · 브랜치: `feature/quiz-solving-flow`

에이전트가 자율 판단으로 선택한 사항을 추후 검토할 수 있도록 기록합니다. 각 항목은
**결정 / 근거 / 되돌리는 법**으로 구성합니다.

## 1. `OverlayContainer`가 `ScreenContainer` 책임을 흡수

**결정** — `OverlayContainer`가 `LayoutMetricsReader`, 고정 화면 배경, `preferredColorScheme(.dark)`를
직접 소유합니다. 슬롯 시그니처는 `(LayoutMetrics) -> View`가 되었고 `layoutMetrics` 파라미터는
사라졌습니다. 스크롤 화면은 `ScreenContainer`로 감싸지 않습니다.

**근거** — `ScreenContainer`는 `GeometryReader`로 safe area를 *읽어 내려주는* 공급자이고
`OverlayContainer`는 *받아 쓰는* 소비자였습니다. 중첩을 풀면서 공급자를 없애면 모든 화면이
`LayoutMetrics.default`(402×874, safeAreaTop 62) 상수로 떨어져 다른 기기에서 조용히 어긋납니다.
부수 효과로 라우터·프리뷰의 `layoutMetrics` 배선 30여 곳이 사라졌습니다.

**되돌리는 법** — 슬롯을 `() -> View`로 되돌리고 `layoutMetrics` 파라미터를 복원한 뒤 호출부를
다시 `ScreenContainer`로 감쌉니다.

## 2. 배경을 두 종류로 분리

**결정** — `screenBackground: SemanticColorToken`(safe area까지 덮는 고정 배경)과
`background: (LayoutMetrics) -> View`(본문과 함께 스크롤되는 장식 배경)를 분리했습니다.

**근거** — 검토 중 제안된 `Rectangle().designSystemBackground(.screenBackground)` 기본값에는 두 가지
문제가 있었습니다. (1) `designSystemBackground`는 `.background(Color(...))`이므로 `Rectangle`은
foreground style(다크 스킴 기본 = 흰색)로 칠해지고 토큰 색은 그 *뒤*에 깔립니다 — 결과는 흰 사각형.
(2) 고쳐도 이 슬롯은 스크롤 콘텐츠에 붙어 높이가 콘텐츠 높이이고 함께 스크롤되므로, 고정·전면이어야
하는 화면 기저 배경을 대신할 수 없습니다.

## 3. 헤더 높이를 `contentInset` 대신 숨긴 복사본으로 확보

**결정** — `OverlayHeader` 프로토콜과 `contentInset` 요구사항을 삭제하고, 헤더·푸터의 `.hidden()`
복사본이 스크롤 콘텐츠 안에서 같은 자리를 차지하도록 했습니다(`occlusionSpacer`).

**근거** — 선언한 숫자와 실제 헤더 높이가 어긋날 수 없고, 같은 레이아웃 패스에서 정해지므로
`GeometryReader`+`PreferenceKey` 측정 방식의 1프레임 지연이 없습니다(커밋 `17dc507`에서 걷어낸 방식).
제네릭 제약도 `Header: View`로 느슨해졌습니다.

**대안(미채택)** — `safeAreaInset(edge:)`. 레이아웃 시스템이 직접 인셋하지만, 상태 표시줄 관통
스크롤을 위한 `ignoresSafeArea`와의 적용 순서 확인이 필요해 현 구조를 유지했습니다.

**트레이드오프** — 헤더 높이를 값으로 단언하던 계약 테스트는 성립하지 않아 제거했습니다.

## 4. 헤더·푸터를 주입 컴포넌트로 분리

**결정** — `plain`/`largeTitle` 팩토리를 없애고 `ScreenOverlayHeader`(ScreenHeader + 화면 여백 +
상단 scrim), `ScreenOverlayFooter`(BottomActionBar + 화면 여백 + 불투명 배경)를 주입합니다.

**트레이드오프** — 헤더 없는 화면(`HomeScreen`)은 첫 트레일링 클로저가 `header`에 붙으므로
`OverlayContainer(content:)`처럼 레이블이 필요합니다. `content`를 첫 파라미터로 옮기면 해소되지만
`{ header } content:` 읽기 순서가 뒤집혀 현행을 유지했습니다.

## 5. 이관 대상 선별

| 화면 | 처리 | 근거 |
| --- | --- | --- |
| QuestionSolving, LearningSetIntro, ProjectDetail | `OverlayContainer` | 헤더 + 스크롤 본문 |
| Home | `OverlayContainer` (헤더 슬롯 생략) | 스크롤 본문, 헤더가 함께 스크롤됨 |
| PositionSelection, CareerSelection | `OverlayContainer` | 헤더 + 스크롤 본문 + 하단 버튼 |
| Saved (목록 상태) | `OverlayContainer` | 스크롤 목록 |
| Saved (빈 상태), 각 ErrorView, LearningCompletion | `ScreenContainer` 유지 | `Spacer` 세로 중앙 정렬은 `ScrollView`에서 접힘 |
| Tutorial | `ScreenContainer` 유지 | `TabView` 페이징. `ScrollView` 검색 결과는 `UIScrollView.appearance()` 오탐 |
| AppEntry, Splash, LaunchLogo, Placeholder, CurationSplash, ProjectRegistration | `ScreenContainer` 유지 | 비스크롤 |

**부작용(의도됨)** — Position/Career 선택 화면은 본문이 헤더 뒤로 스크롤되고 헤더에 scrim이 생깁니다.
하단 버튼은 `ScreenOverlayFooter`가 되어 불투명 배경(`.screenBackground`)을 갖습니다. 겹침 구조에서
배경이 없으면 본문이 비쳐 보이기 때문입니다.

## 6. 문서 주석(`///`) 제거

**결정** — 이번 변경분에 포함된 Swift 파일에서 `///` 문서 주석을 제거하고 `// MARK:`만 남겼습니다.

**근거** — 목표에 명시된 "`//MARK:` 제외 마크다운 제거" 지침. 총 25줄.

**범위 한정** — 이번 세션에서 추가·수정한 파일에만 적용했습니다. 저장소 전체에는 적용하지 않았습니다.

**되돌리는 법** — 이 커밋의 해당 hunk를 revert합니다.

## 7. 레거시 제거: `learningRequested`의 `nextQuestionID`

**결정** — `HomeFeature`·`MainShellRouterFeature`의 delegate 페이로드에서 `nextQuestionID`를 제거했습니다.

**근거** — `AppRootFeature`가 이 값을 `_`로 버리고 있었습니다. 실제 재개 지점은
`LearningSetResumption(set:)`이 세트를 받아 첫 미응답 문제로 다시 계산합니다. Domain·Data 모델의
`nextQuestionID` 필드는 그대로 두었고, 재생 버튼 활성 조건(`isLearningEnabled`)도 유지했습니다.

## 8. 홈 카드 재생 버튼 = 학습 이어하기 (작업 2번)

**확인 결과 — 추가 구현 불필요.** 전 구간이 이미 연결되어 있고 테스트도 존재합니다.

```
HomeProjectCard(play) → onStart → HomeFeature.learningTapped
  → delegate.learningRequested → MainShellRouterFeature → AppRootFeature
  → QuizRouterFeature(autoStartsLearning: true)
  → LearningSetIntroFeature(autoStartsOnLoad: true) → 세트 로드 즉시 startRequested
  → LearningSetResumption(set:).startIndex = 첫 미응답 문제
```

버튼은 `isLearningEnabled = nextSetID != nil && nextQuestionID != nil`일 때만 활성화됩니다.
관련 테스트: `HomeFeatureNavigationTests`, `HomeFeatureGenerationProgressTests`,
`MainShellRouterFeatureTests`, `AppRootFeatureTests`.

## 미검증 범위

- 레이아웃 변화(헤더 뒤 스크롤, scrim, 푸터 겹침)는 **시뮬레이터 육안 확인을 하지 않았습니다.**
  특히 Position/Career 선택 화면과 Home 화면의 상단 여백을 확인해야 합니다.
- `.scrollIndicators(.hidden)`을 `OverlayContainer` 바깥에서 적용했습니다(HomeScreen). 환경값 전파에
  의존하므로 실제 표시 여부 확인이 필요합니다.

---

# 후속 작업 결정 리포트 (작업 3·4·5)

## 9. 프로젝트 리스트 화면 (작업 3)

**상황** — `ProjectListFeature`는 완성되어 `MainShellRouterFeature`에 이미 배선돼 있었고, View만
`PlaceholderView`였습니다. 화면과 표시 모델만 새로 만들었습니다.

추가한 것:
- `ProjectListScreen` (`OverlayContainer` + `ScreenOverlayHeader(.largeTitle)`)
- `ProjectListDisplay` 표시 모델
- `Thumbnail` / `FailureView` / `EmptyProjectsView` 하위 뷰
- `ProjectListFeatureTests`, `ProjectListDisplayTests`
- `MainShellRouter`의 `.projects` 탭 연결

### 결정 9-1. 편집 모드로 삭제를 노출

`ProjectRow`의 `isDeleting` 파라미터는 "삭제 진행 중"이 아니라 **행 액세서리 버튼을 재생(▶)에서
삭제(−)로 바꾸는 편집 모드 플래그**였습니다. `ProjectListFeature`에는 편집 모드 상태가 없으므로
화면 로컬 `@State isEditing`을 두고 헤더 trailing 컨트롤(`trash` ↔ `checkmark`)로 토글합니다.

- 편집 중: 액세서리 → `deleteButtonTapped`
- 평상시: 액세서리(재생) → `projectRowTapped` (상세로 이동, 거기서 이어풀기)

**근거** — `ProjectListFeature.Action.View`에 "학습 시작" 액션이 없습니다. 기존 리듀서 계약을 바꾸지
않고 화면만으로 해결했습니다. 편집 모드를 리듀서 상태로 올리거나 재생 버튼에서 바로 학습을
시작하려면 액션 추가가 필요합니다.

### 결정 9-2. 세트 번호를 라벨에서 파싱

`ProjectRow`는 `currentSet: Int`를 받는데 `LearningProjectSummary.currentSetLabel`은 문자열
("CHAPTER 3")입니다. 라벨에서 숫자만 추출하고, 숫자가 없으면 `1`로 둡니다.

**리스크** — 라벨 형식이 바뀌면 잘못된 번호가 나옵니다. 서버가 세트 번호를 별도 필드로 주면
그쪽으로 옮기는 것이 옳습니다. (`ProjectListDisplayTests`에 두 경우 모두 테스트를 두었습니다.)

## 10. 저장 문제 리스트 (작업 4)

**결정** — `SavedScreen`이 이미 존재하고 `SavedFeature`도 배선돼 있어, `MainShellRouter`의 `.saved`
탭을 `PlaceholderView`에서 `SavedScreen`으로 교체했습니다. 목록 상태는 결정 5에 따라
`OverlayContainer`로 이관했습니다.

**주의** — 탭에서 열 때 `isBackControlPresented`가 기본값 `false`라 뒤로가기 컨트롤이 없습니다.
탭 진입에는 맞는 동작이고, 프로젝트 상세에서 진입할 때는 `true`로 들어옵니다.

## 11. 공유 URL → 레포지토리 등록 랜딩 (작업 5)

**상황** — 경로 자체는 이미 있었습니다.

```
ShareExtension → App Group(UserDefaults) → gitit://shared-link
  → GitItApp.onOpenURL → AppRootFeature.sharedRepositoryLinkReceived
  → ProjectRegistrationRouterFeature(initialRepositoryURL:)
  → RepositoryLinkInputFeature(pendingAutomaticValidation: true) → 자동 검증
```

**공백** — 확장이 `NSExtensionActivationSupportsWebURLWithMaxCount: 1`로만 활성화되고
`public.url` 첨부만 읽었습니다. 메신저·메모처럼 **텍스트로 공유된 GitHub 링크는 확장이 뜨지도
않았습니다.**

**결정** — 활성화 규칙을 predicate로 바꿔 `public.url` 또는 `public.plain-text`를 받고,
`ShareViewController`가 텍스트 첨부에서 `NSDataDetector`로 첫 http(s) 링크를 뽑도록 했습니다
(`SharedURLExtractor`).

**형식 판정은 앱에 남겼습니다.** `AppModuleName.swift`에 "확장은 URL 형식을 판정하지 않고 그대로
앱에 넘기므로 프로젝트 내부 패키지에 의존하지 않는다"는 설계 노트가 있어 그대로 따랐습니다.
지원 형식 판정은 `GitHubRepositoryURLParser`(github.com 호스트, `owner/name` 경로, `.git` 접미사 제거)가
링크 입력 화면의 자동 검증에서 수행하고, 지원하지 않는 링크는 그 화면에서 검증 실패로 보입니다.

**미검증** — `SharedURLExtractor`에 단위 테스트를 두지 않았습니다. `GitItTests`가 `ShareExtension`
타깃에 의존하지 않고(확장은 `dependencies: []`), 기존에도 확장 테스트가 없습니다. 테스트를 두려면
추출 로직을 별도 프레임워크로 빼야 하는데, 확장을 의존성 없이 유지하려는 설계와 충돌합니다.

## 12. 데드코드 도구 결과는 사용하지 않음

`code-review-graph`의 `dead_code` 모드가 513건을 보고했지만 대부분 오탐이었습니다.
`CodingKeys`·`Action`·`CancelID`·`Constant` 같은 중첩 타입을 미참조로 판정했고, 그래프 경로가
이전 디렉터리 구조(`Feature/Quiz/Reducers/`, `Feature/ProjectList/Reducers/`)로 남아 있어 실제 파일과
맞지 않았습니다. 레거시 판단은 직접 읽어서 했습니다.

## 13. 컨벤션 정합성 점검

### 13-1. `docs/conventions/view.md` §4.1 갱신 (수정함)

화면 골격 표에 `OverlayContainer`·`ScreenOverlayHeader`·`ScreenOverlayFooter`를 추가하고, 다음
두 규칙을 문서에 반영했습니다.

- 화면 루트는 `ScreenContainer` 또는 `OverlayContainer` 중 하나이며 중첩하지 않는다.
  중앙 정렬 화면은 `ScrollView`에서 `Spacer`가 접히므로 `OverlayContainer`에 담지 않는다.
- 색 구성표와 `LayoutMetrics` 공급은 화면 루트 컨테이너가 소유한다. 화면에서
  `preferredColorScheme(_:)`을 다시 지정하지 않고 `LayoutMetricsReader`를 직접 열지 않는다.

기존 문서는 "색 구성표는 `ScreenContainer`가 **단독으로** 소유한다"고 못박고 있어서,
`OverlayContainer`가 색 구성표를 갖게 된 변경과 충돌했습니다.

### 13-2. §4.3 `Self.` 호출 규칙 (부분 적용)

컨벤션은 화면 전용 서브뷰를 `body`에서 부를 때 `Self.`을 붙이도록 합니다(2026-09-03 추가).
새로 만든 `ProjectListScreen`은 이 규칙을 지키도록 고쳤습니다.

**미해결** — 기존 화면 다수가 이 규칙을 따르지 않습니다: `ProjectDetailScreen`(`ErrorView`,
`MenuSheet`, `RepositorySummaryView`, `SetListSection`), `SavedScreen`(`ErrorView`),
`LearningSetIntroScreen`(`ErrorView`), `QuestionSolvingScreen`(`SourceSheet`, `ChoiceSection`,
`AnswerEditor`, `QuestionPrompt`, `EssayResultSection`) 등. 규칙이 최근에 추가되어 기존 코드가
따라오지 못한 것으로 보입니다. 이번 변경 범위 밖이라 손대지 않았고, 별도 정리 작업으로 남깁니다.

### 13-3. 라우터 `store` 접근 수준 되돌림 (수정함)

작업 트리에 `MainShellRouter`·`OnboardingRouter`의 `@Bindable private var store`가
`public`으로 넓혀진 채 남아 있었습니다. 커밋 `cd4b15f [Refactor] Router와 화면의 store·헬퍼
접근 수준을 컨벤션에 맞춰 좁힘`과 정면으로 어긋납니다.

포매터가 한 변경이 아님을 확인했습니다(별도 probe 파일로 `format` 실행 — 선언 순서만 바꾸고
접근 수준은 건드리지 않음). 두 파일 모두 `private`으로 되돌렸고, `store`를 타입 밖에서 참조하는
곳은 없어 빌드에 영향이 없습니다.

### 13-4. `.codex/` 로컬 설정 (수정함)

`.codex/config.toml`은 Codex CLI의 MCP 서버 설정으로 머신·도구 전용입니다. `.claude`가 이미
무시되고 있는 것과 같은 이유로 `.gitignore`의 "Agent tool local configuration" 항목에 추가했습니다.

### 13-5. 선행 작업 트리 변경 (그대로 커밋)

이번 세션 이전부터 작업 트리에 있던 변경으로, 검토 후 그대로 둔 것들입니다.

- `sources/Tuist/Package.swift` — `Sharing`을 `.framework`에서 `.staticFramework`로.
- `TagBadgeContractTests.swift` — `accent` 스타일 기대값을 `blue400`/`blue100`으로. 커밋된
  `TagBadge.swift`의 실제 값과 일치시키는 수정이라 그대로 두었습니다.

## 14. 배경 API를 생성자 두 개로 분리

**결정** — 2번에서 나눈 두 배경을 이제 *서로 다른 생성자*로 호출합니다. 두 값을 한 생성자에
나란히 받지 않습니다.

| 생성자 | 시그니처 | 쓰는 곳 |
| --- | --- | --- |
| 스크롤 배경 | `init(header:content:background:footer:)` | 본문과 함께 스크롤되는 장식 배경이 있는 화면 |
| 색 토큰 배경 | `init(screenBackground:header:content:footer:)` (`Background == EmptyView`) | 나머지 전부 |

**근거** — 한 생성자에 `screenBackground:`와 `background:`를 함께 두면 호출부에서 "둘 중 무엇을
쓰는 화면인지"가 인자 목록을 다 읽어야 드러납니다. 실제 사용 분포도 배타적입니다 — 이관한 8개
화면 중 `background:` 슬롯을 쓰는 것은 `ProjectDetailScreen`(hero 그라디언트) 하나뿐이고,
나머지는 토큰 기본값만 씁니다.

**구현** — 두 public 생성자 모두 `private init(screenBackground:header:content:background:footer:)`로
위임합니다. 저장 프로퍼티는 한 곳에서만 채워집니다.

**과부하 모호성 없음** — 스크롤 배경 생성자는 `background:`에 기본값이 없고, 색 토큰 생성자는
`background:` 인자를 아예 받지 않습니다. 따라서 호출에 `background:`가 있으면 전자만,
없으면 후자만 적용 가능합니다.

**가정** — 색 토큰 생성자를 쓰지 않는 화면(`ProjectDetailScreen`)에서도 기저 배경은
`.screenBackground`로 깔립니다. `background:` 슬롯은 콘텐츠와 함께 스크롤되어 사라지므로 그 뒤에
고정 배경이 없으면 스크롤 후 화면이 비기 때문입니다. 스크롤 배경 생성자가 토큰까지 함께 받아야
한다면 이 가정을 바꿔야 합니다.

## 15. `LayoutMetrics` 타입 전체 제거

**결정** — `LayoutMetrics`/`LayoutMetricsReader`/`LayoutMetrics.HeaderStyle` 타입과
이를 화면·컴포넌트 트리에 걸쳐 주입하던 `(LayoutMetrics) -> View` 슬롯 시그니처를
모두 제거했습니다. `LayoutMetricsTests.swift`(9개 기기 파생값 회귀 테스트)도 함께
삭제했습니다.

**근거** — 공유 측정 타입을 화면부터 리프 컴포넌트까지 주입해 내려보내는 구조 자체가
과도한 결합과 보일러플레이트를 만든다는 판단입니다. 실제로 값을 계산에 쓰는 지점은
`ScreenOverlayHeader`(상단 scrim 높이), `BottomActionBar`(하단 최소 여백),
`HomeScreen.ProjectSection`(카드 그리드 폭) 세 곳뿐이었고, 나머지는 전부 파라미터를
그대로 통과시키기만 하는 보일러플레이트였습니다.

**대체 방식** — 공식은 그대로 유지하되, 값이 필요한 컴포넌트가 각자 자체
`GeometryReader`/`onGeometryChange`로 직접 측정합니다.

| 컴포넌트 | 이전 | 이후 |
| --- | --- | --- |
| `ScreenOverlayHeader` | 주입받은 `layoutMetrics.safeAreaTop + style.height` | 자체 `GeometryReader`의 `proxy.safeAreaInsets.top + style.height` |
| `BottomActionBar` | 주입받은 `max(layoutMetrics.safeAreaBottom, 24)` | `.background { onGeometryChange }`로 측정한 `max(safeAreaBottomInset, 24)` — 패딩 적용 *전* 시점에서 측정해 자기 참조를 피함 |
| `HomeScreen.ProjectSection` | 주입받은 `layoutMetrics.gridColumn2` | 자체 `onGeometryChange`로 측정한 섹션 폭에서 동일 공식으로 계산 |
| `ScreenEdgeScrim` | `Style` enum + `LayoutMetrics.HeaderStyle`을 받아 내부에서 높이 계산 | 호출부가 계산한 `height: CGFloat`만 받는 순수 프레젠테이션 컴포넌트로 축소 |
| `HomeProjectCard` | `layoutMetrics` 저장 프로퍼티 (내부에서 실제로는 한 번도 읽지 않던 죽은 파라미터) | 파라미터 자체를 삭제 |

**트레이드오프** — 기존에는 화면 루트 한 곳(`LayoutMetricsReader`)에서만 측정해
`GeometryReader` 1회로 끝났지만, 이제 값이 필요한 3곳이 각자 측정합니다.
`BottomActionBar`와 `ProjectSection`은 `onGeometryChange`를 쓰므로 최초 프레임에는
기본값(각각 0, 402pt 기준 카드 폭)으로 그려졌다가 한 프레임 뒤 실측값으로 갱신됩니다 —
이 지연은 같은 파일(`HomeScreen+ProjectSection.swift`)이 카드 스크롤 오프셋 측정에
이미 쓰던 것과 같은 패턴입니다.

**미검증 범위** — 이 변경은 빌드·시뮬레이터로 시각 확인을 하지 않았습니다. 특히
`BottomActionBar`의 `.background { onGeometryChange }` 측정 시점(패딩 적용 전 프레임 기준)이
의도대로 실제 safe area 값을 보고하는지, `ScreenOverlayHeader`의 scrim이 여전히 노치·상단
안전영역까지 정확히 덮는지는 사용자가 시뮬레이터에서 직접 확인해야 합니다.
