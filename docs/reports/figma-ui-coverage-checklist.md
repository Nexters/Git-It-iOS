# Figma UI ↔ 구현 화면 인덱스와 미매칭 체크리스트

조사일: 2026-09-04 · 브랜치: `feature/my-page` · Figma 파일: `mCRt0ejmzI4EFW3UnC9Bzb`
(요청 URL의 `node-id=4128-6392` = `UI` 섹션)

이 문서는 Figma `UI` 섹션 아래 기기 크기 프레임 66개와 `sources/Projects/Feature/` 화면 25개를
양방향으로 대조한 결과다. 상태·문구·구성 요소 수준의 대조이며 **레이아웃 실측(±0.5pt) 비교는
하지 않았다**. 상세 노드 좌표와 실측값은 `.agents/skills/implement-figma-ui/references/`의
인덱스(로컬 전용, `.gitignore` 대상)가 소유하고, 이 문서는 커버리지와 미매칭 항목을 추적한다.

## 0. 조사 방법과 근거 수준

| 수단 | 범위 |
| --- | --- |
| `use_figma` 읽기 전용 | 페이지·섹션 구조, `UI` 섹션 재귀 탐색(≥320×700 프레임 66개), 컴포넌트 60개와 variant 축, 프레임 56개의 가시 텍스트, 선택 카드 인스턴스의 variant 상태 |
| `get_screenshot` | `2116:31423`, `2116:31377`, `2116:31380`, `737:10726`, `1859:21645`, `779:33852`, `805:10982` |
| 코드 | `#Preview` 이름의 노드 ID, 소스 주석의 노드 ID, 화면별 렌더 상태·문자열·사용 컴포넌트 |
| 명세 | `specs/006-final-uxui-screens/contracts/screen-inventory.md`, `specs/025-quiz-solving-flow/contracts/screen-flow.md`, `specs/023-registration-home-ux-fixes/spec.md`, `specs/026-my-page/*` |

근거 수준은 스킬 규약을 따른다. `A` 이번 조회로 직접 확인 · `B` 저장소 확정 계약 · `C` 렌더 판독·추론.

매칭 표기: `✅` 대응 확인 · `⚠️` 대응하나 차이 있음 · `❌` 미구현 · `➖` 제외(앱 화면 아님) · `?` 미확인.

## 1. Figma 구조 변경 (2026-08-26 인덱스 대비, `A`)

- 페이지 `86:761`의 직속 자식이 **단일 섹션 `4328:6364` `Section 2147207212`** 하나로 바뀌었고,
  그 아래에 `Design system`(`459:5559`)·`UI`(`4128:6392`)·`Section 2147207211`(`4128:6393`, 빈 섹션)·
  `사용한 컴포넌트`(`739:24524`)·`애니메이션 및 앱 에셋`(`2023:28703`)이 있다.
- **`브랜딩 이미지`(`4003:26706`)는 폐기됐다**(조회 결과 `null`). `Icon` 섹션(`4003:26707`, 아이콘 30개)은
  `사용한 컴포넌트` 직속으로 옮겨졌다.
- **`마이페이지` 섹션(`4393:6038`)이 신설**돼 `마이` 3프레임·`설정` 4프레임·`세부설정` 컴포넌트(`1433:18243`)가
  `UI` 직속에서 이곳으로 이동했다. `UI` 직속 자식은 70 → 58개.
- `객관식문항-문제 풀이`(`1064:19756`)·`객관식문항-답안`(`1369:17327`) 컴포넌트 세트는
  `사용한 컴포넌트` 안의 새 하위 섹션 `Selected`(`4228:6392`)로 이동했다. `사용한 컴포넌트` 직속 자식은 51 → 45개.
- 기기 크기 프레임 66개 = 006 계약의 65개(제외 항목 `Examples/Notifications` 2개 포함) + 006이 목록에서
  뺀 `1828:19279`(700×840 설명 조합). 프레임 이름·ID는 006 계약과 모두 일치하고 새로 추가되거나 사라진
  화면 프레임은 없다. 로딩 변형 `2026:29388`은 `824:12149`의 하위 서브트리라 이 수에 들지 않는다.

## 2. 화면 인덱스: Figma 프레임 → 구현

### 2.1 Core Page (`UI` 직속) + Task 4 저장

| 프레임 | 노드 | 식별한 내용 | 구현 (`sources/Projects/Feature/`) | 프리뷰 | 매칭 | 근거 |
| --- | --- | --- | --- | --- | --- | --- |
| `홈화면 (완)` | `1542:19610` | 빈 데크 + `아직 등록된 프로젝트가 없어요.` | `Home/Home/HomeScreen.swift` (`HomeProjectSectionState.empty`) | `Project Absent - 1542:19610` | ✅ | A(08-30·09-01 인덱스) |
| `홈화면 (완)` | `1465:19015` | 카드 덱, `지금 불러오기`, `전체보기` | 같은 파일 (`.loaded`) | `Project Present - 1465:19015` | ✅ | A |
| `홈화면 (완)` | `1828:19279` | 700×840 카드 나열 설명 조합 | — | — | ➖ | A |
| `프로젝트` | `1542:19495` | 목록 기본 상태 | `ProjectList/ProjectList/ProjectListScreen.swift` | `프로젝트 목록` | ⚠️ 노드 미조회·프리뷰에 노드 ID 없음 | C |
| `프로젝트` | `1621:30331` | 메뉴 열림(`Dropdown menu --> 프로젝트 삭제` 화살표 `1621:30705`) | 없음. 코드는 헤더 trailing `trash`/`checkmark` 토글로 편집 모드 진입(`docs/reports/overlay-container-migration.md` 결정 9-1) | — | ❌ | A(구조)·C |
| `프로젝트 (Empty)` | `1597:19052` | `projects = []` + `아직 등록한 프로젝트가 없어요. 관심 있는 오픈소스를 가져와 문제…` | `SubViews/ProjectListScreen+EmptyProjectsView.swift` | `프로젝트 목록 · 빈 상태` | ✅ 문구 일치 | A(문구) |
| `프로젝트 삭제` | `1621:23431`, `1621:30561` | 헤더 제목 `프로젝트 삭제`, `ProjectList` `Delete` variant 행 | `ProjectListScreen` `isEditing` + `ProjectRow(isDeleting:)` | 없음 | ⚠️ 헤더 제목이 `프로젝트`로 유지, 두 프레임 차이 미확인 | A(문구)·C |
| `프로젝트 삭제 모달` | `1621:24059` | `삭제`/`취소` 버튼 모달 | `ProjectListScreen` `deletion == .confirming` → `ConfirmationSheet` | `프로젝트 목록 · 삭제 확인` | ⚠️ 모달 제목·설명 문구 미대조 | C |
| `프로젝트 상세(완)` | `1342:19562`(360×1209), `1342:19609`(메뉴 열림), `1871:22144`(삭제 시트) | 저장소 요약·전체 진행률·세트 5개 | `ProjectDetail/ProjectDetail/ProjectDetailScreen.swift` | `프로젝트 상세 · s01/메뉴 펼침/삭제 확인` | ✅ (프리뷰는 025 사설 렌더 `s01` 이름) | A(09-03 인덱스) |
| `프로젝트 상세(완)` | `1342:19659` | 진행률 12%. 나머지 3개와의 차이 **미확인** | 같은 파일 | — | ? | A(문구만) |
| `프로젝트 등록하기` | `1342:20123` | 링크 입력 + `불러오기 방법` (`986:13646`과 같은 내용) | `ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift` | — | ✅ 문구 일치, 레이아웃 미조회 | A(문구)·C |
| `Task4_06` | `1597:19231`(Inline Title, 360×1083), `1597:21241`(Large Title, 360×1139) | 필터 칩 `전체·Flask·Now in Android`, `4개`, 카드(`Now in Android · Set 2 · 문제 1` + 본문 + `문제풀기`) | `Saved/Saved/SavedScreen.swift` + `SubViews/SavedScreen+FilterSection.swift`(칩·개수) + `UIComponent`의 `SavedQuestionCard`(카드) | `저장한 문제 · 목록` | ✅ 2026-09-04 사용자 스크린샷 근거로 칩·개수·카드 메타데이터 반영(025 FR-044a-6·D-010을 슈퍼시드 — DTO가 이미 프로젝트명·세트 라벨·문제 번호를 응답에 포함해 추가 조회 없이 구현). spec 문서(025)는 갱신하지 않음, PR에 편차 기록. 헤더는 Large Title만 | A(문구)·B(006 헤더 변형) |
| `저장 (Empty)` | `1597:19247`(Inline Title), `1597:21683`(Large Title) | `Nothing saved yet.` + 안내 | `SavedScreen` `EmptyState` | `저장한 문제 · 빈 상태` | ✅ 문구 일치, 헤더는 Large Title만 | A(문구) |

### 2.2 마이페이지 (`4393:6038`, 신설 섹션)

| 프레임 | 노드 | 식별한 내용 | 구현 | 프리뷰 | 매칭 | 근거 |
| --- | --- | --- | --- | --- | --- | --- |
| `마이` | `1539:19209` | 이번 주/이번 달 0문제·연속 0일, `이번 주 첫 문제를 풀어볼까요?` | `Settings/Profile/ProfileScreen.swift` | `Profile - … - 1539:19209` ×3 | ✅ | A(09-04 인덱스) |
| `마이` | `1539:19358` | 19문제·연속 3일, `이번 주도 차근차근 풀고 있어요` | 같은 파일. 코드 문구는 `이번 주 N문제를 풀었어요` | 없음 | ⚠️ 문구 변형 미구현 | A(문구) |
| `마이` | `1465:19359` | 44문제·연속 7일, `이번 주 학습을 하루도 놓치지 않았어요` | 같음 | 없음 | ⚠️ 문구 변형 미구현 | A(문구) |
| `설정` | `1465:19689` | `학습 설정`(개발 분야·개발 수준) · `알림`(세트 생성 완료 알림 `켜짐`) · `일반`(약관·로그아웃·계정 삭제) | `Settings/Settings/SettingsScreen.swift` | `Settings - … - 1465:19689` ×3 | ⚠️ `알림` 섹션은 FR-014로 제외(승인된 차이). `SettingRow` 아이콘·56pt·px20 불일치는 UI 확장 승인 대기 | A |
| `설정` | `1535:18281` | `개발 분야` 4카드 | `SubViews/SettingsScreen+PositionSelectionView.swift` | `Settings - 개발 분야 … - 1535:18281` ×2 | ✅ | A |
| `설정` | `1535:18378` | `개발 수준` 4카드 + 설명 | `SubViews/SettingsScreen+CareerLevelSelectionView.swift` | `Settings - 개발 수준 선택 - 1535:18378` | ✅ | A |
| `설정` | `1636:31714` | `계정 삭제` 경고 문단 + `계정 삭제` 버튼 | `SubViews/SettingsScreen+AccountDeletionView.swift` | `Settings - 계정 삭제 … - 1636:31714` ×2 | ✅ 문구 일치 | A(문구) |

### 2.3 Task 1. 온보딩/로그인/튜토리얼 (`4113:6393`)

| 프레임 | 노드 | 식별한 내용 | 구현 | 프리뷰 | 매칭 | 근거 |
| --- | --- | --- | --- | --- | --- | --- |
| `온보딩_애플로그인` | `779:33450`, `779:33529`, `779:33564` | 튜토리얼 1·2·3면 | `Onboarding/Tutorial/TutorialScreen.swift` | `Tutorial - N페이지 · 노드` ×3 | ✅ | A(08-26 인덱스) |
| `약관 동의` | `786:38332` (+ `Sheet Modal` 인스턴스 `786:38391`) | 전체 동의 시트 | `Onboarding/LegalAgreement/LegalAgreementScreen.swift` | `Legal Agreement - idle/전체 선택 · 786:38391` | ✅ | A(08-27)·B(016) |
| `약관 동의` | `779:33852`, `805:10982` | 두 프레임 렌더 동일: 저장한 문제 목업 위 시트, 전체 동의 체크, `취소`·`다음` | 같은 파일 | — | ✅ 같은 화면. `786:38332`과의 상태 차이는 미확인 | A(렌더) |
| `Task1_05` | `737:10375` | 분야 선택 **미선택**(카드 4개 모두 `off`) | `Onboarding/PositionSelection/PositionSelectionScreen.swift` | `Position Selection - 미선택 · 737:10367` | ⚠️ 프리뷰 노드 ID가 `737:10367`로 잘못 적힘 | A(variant 조회) |
| `Task1_06` | `737:10367` | 분야 선택 **선택됨**(`Back-end` `on`) | 같은 파일 | `Position Selection - 선택됨 · 737:10367` | ✅ | A(variant 조회) |
| `Task1_07` / `Task1_08` | `737:10358` / `737:10349` | 경력 미선택 / `주니어` 선택 | `Onboarding/CareerSelection/CareerSelectionScreen.swift` | `Career Selection - 미선택/선택됨 · 노드` | ✅ | A |
| `Task1_09` | `2116:31423` | 텍스트 없는 **로고 스플래시** | `AppEntry/AppEntry/AppEntryScreen.swift` (`LaunchLogo`) | `AppEntry - 세션 확인 중` | ✅ 렌더 대응, 프리뷰에 노드 ID 없음 | C(렌더) |
| `Task1_10` | `2116:31377` | `Hello World` 텍스트 스플래시 | `Onboarding/Router/SubViews/OnboardingRouter+CurationSplashView.swift` (`SplashView` 타이핑 1단계) | `Onboarding - curation` | ✅ 렌더 대응, 프리뷰에 노드 ID 없음 | C(렌더) |
| `Task1_10` | `2116:31380` | `Hello World` + `Let's Git-it!` | 같은 파일 (타이핑 2단계) | 같음 | ✅ | C(렌더) |

### 2.4 Task 2. 문제 생성 (`4113:6394`)

| 프레임 | 노드 | 식별한 내용 | 구현 | 프리뷰 | 매칭 | 근거 |
| --- | --- | --- | --- | --- | --- | --- |
| `스플래시` | `986:13739`, `986:13646`, `986:13693`, `1338:17500` | 링크 입력 기본·안내·입력됨·오류 | `ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift` | `링크 입력 · 986:13739`, `링크 입력 · 검증 실패` | ✅ | A(08-31 인덱스) |
| `Task2_04` | `737:10890` | 레포지토리 확인(썸네일·이름 가로 배치) | `RepositoryConfirmation/RepositoryConfirmationScreen.swift` | `레포지토리 확인 · 737:10890` | ✅ 2026-08-31 인덱스의 세로 배치 불일치는 `HStack`으로 교정됨 | A(코드)·A(08-31) |
| `Task2_05` / `Task2_06` | `737:10882` / `737:10874` | 이해도 **미선택**(모두 `off`) / **선택됨**(`기술 개념은 알아요` `on`) | `QuizLevelSelection/QuizLevelSelectionScreen.swift` | `이해도 선택 · 737:10882`, `… 선택됨 · 737:10874` | ✅ | A(variant 조회) |
| `Task2_09` | `737:10830` | 생성 시작 확정 | `QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift` | `생성 시작 확정 · 737:10830` | ✅ | A |
| `로딩(완)` | `737:10800`, `824:12149`, `2026:29388` | 생성 진행 체크리스트. `737:10800`은 `약 5분의 시간이 소요돼요`, `824:12149`는 `1~5분…` | `QuizGenerationProgress/QuizGenerationProgressScreen.swift` (`+GeneratingView`, `+ChecklistView`) | `생성 진행 · 2026:29388` | ✅ 코드 문구는 `737:10800`을 따름 | A(08-31 인덱스) |
| 알림 옵션 시트 | `824:12536` (`824:12149` 하위) | `세트 생성이 완료되면 리마인드 알림을…` | `SubViews/QuizGenerationProgressScreen+GenerationReminderSheet.swift` | `알림 옵션 시트 · 824:12149` | ✅ | A |
| `홈 - 생성 완료` | `737:10726` | 홈 위에 **`세트 생성이 완료되었습니다` 모달 + `프로젝트 확인하기`** 버튼 | 없음 (`Home/**`에 완료 모달·해당 문구 없음) | — | ❌ | A(렌더) |
| `홈 - 생성 완료` | `986:14959` | 텍스트는 `737:10726`과 동일. 렌더 **미확인** | 없음 | — | ❌ / ? | A(문구) |
| `홈 - 생성 완료` | `1859:21645` | 등록 패널 CTA가 `문제 생성 중` 비활성 표기 | `Home/Home/SubViews/HomeScreen+RegistrationPanelView.swift` (`isGenerationInProgress`) | 없음 | ⚠️ 코드 문구 `학습세트 생성 중...` | A(렌더)·B(023 FR-006) |
| `Examples/Notifications` | `994:14657`, `994:14799` | iOS 잠금화면 알림 예시 | — | — | ➖ | A |

### 2.5 Task 3. 문제 풀이 (`4113:6395` › `4006:6400`)

025 명세는 저장소 밖 사설 렌더 `s01`~`s13`을 정본으로 구현했다. 아래 표는 각 `sNN`을 Figma 노드에
처음으로 연결한 결과다(문구 대조 `A`, 레이아웃은 미대조).

| 프레임 | 노드 | 식별한 내용 | 구현 | 프리뷰 | 매칭 | 근거 |
| --- | --- | --- | --- | --- | --- | --- |
| `프로젝트 상세(완)` | `1617:18786` (섹션 직속, 360×1221) | 진행률 0% 변형 | `ProjectDetailScreen` | `프로젝트 상세 · s01` | ✅ | A(문구) |
| `Task3_03` | `813:15700` | `Set 1` · `Compose 핵심 개념 확인하기` · 설명 · `시작하기` (= `s02`) | `Quiz/LearningSetIntro/LearningSetIntroScreen.swift` | `세트 소개 · s02` | ✅ | A(문구) |
| `객관식 문제` | `1342:18657` | 미선택, 하단 `확인` CTA (= `s03`) | `Quiz/QuestionSolving/QuestionSolvingScreen.swift` + `+ChoiceSection` | `문제 풀이 · 미선택 · s03` | ⚠️ 코드 CTA `제출하기` | A(문구) |
| `객관식-출처` | `1342:18678` (시트 `1342:18699`) | `문제 1 출처` 시트 (= `s04`) | `SubViews/QuestionSolvingScreen+SourceSheet.swift` | `문제 풀이 · 출처 Sheet · s04` | ✅ | A(09-03 인덱스) |
| `객관식-selected` | `1342:18711` | 선택 상태 (= `s05`) | 같은 화면 | `문제 풀이 · 선택 · s05` | ✅ | A(문구) |
| `객관식 문제-스크롤` | `1342:18925`, `1342:18946` | 스크롤 상태 (= 계약상 `s06`·`s07`) | 같은 화면 | `제출 중 · s06`, `제출 실패 · s07` | ⚠️ 프리뷰의 `s06`/`s07`이 계약(스크롤)과 다른 상태에 붙어 있음 | A(문구)·B(025 screen-flow §1) |
| `객관식-정답` | `1374:17084` | `AI 해설` + `다음` CTA (= `s08`) | 같은 화면 + `LabeledCard.accent("AI 해설")` | `문제 풀이 · 정답 · s08` | ✅ CTA는 명세 `advanceActionTitle`(`다음 문제`/`학습 완료`/`완료`) | A(문구)·B |
| `객관식-오답` | `1374:17109` | 오답+정답 동시 표시 (= `s09`) | 같은 화면 | `문제 풀이 · 오답 · s09` | ✅ | A(문구) |
| `Task3_12` | `855:15476` | 서술형 빈 입력, `0 / 300`, CTA `정답 확인` (= `s10`) | `SubViews/QuestionSolvingScreen+AnswerEditor.swift` | `서술형 · 빈 입력 · s10` | ⚠️ 한도 300 vs 코드·명세 400(승인된 차이 B). `정답 확인`은 025가 자료 오류로 판정(B). 코드 CTA는 `제출하기` | A·B |
| `Task3_13` | `855:15454` | 입력 중 `111 / 300` (= `s11`) | 같음 | `서술형 · 입력 중 · s11` | ✅ | A(문구) |
| `Task3_14` | `855:15415` | `나의 답안` · `AI의 답안` 카드 (= `s12`) | `SubViews/QuestionSolvingScreen+EssayResultSection.swift` | `서술형 · 결과 · s12` | ✅ | A(문구) |
| `Task3_24` | `1374:17250` | `학습 완료` 제목, 점수 `7`/`7`, `세트의 모든 문제를 다 맞췄어요!`, CTA `다음` (= `s13`) | `Quiz/LearningCompletion/LearningCompletionScreen.swift` | `학습 완료 · s13` | ⚠️ 코드 문구 `학습을 마쳤어요` / `다음 세트에서 이어서 학습해 보세요.` / `확인` | A(문구) |

### 2.6 Task 4. 저장 (`4113:6396`)

`Task4_06`(`1597:21241`)과 `저장 (Empty)`(`1597:21683`)은 2.1의 Core Page 프레임과 `Toolbar - Top`
높이(99pt Large Title)만 다른 변형이며(`B`, 006 계약), `SavedScreen`의 `.largeTitle` 헤더가 이 변형에
대응한다. 43pt Inline Title 변형(`1597:19231`, `1597:19247`)은 별도 상태로 구현되지 않았다.

## 3. 역방향 인덱스: 구현 화면 → Figma

`Figma 없는 상태` 열은 코드가 렌더하지만 대응 프레임이 없는 상태다. 이 상태들은 Figma를 근거로 교정할 수
없으므로 명세 또는 사용자 승인으로 유지한다.

| 화면 파일 (`Feature/`) | 대응 노드 | Figma 없는 상태 |
| --- | --- | --- |
| `AppEntry/AppEntry/AppEntryScreen.swift` | `2116:31423`(C) | `복구 오류`(`세션을 확인하지 못했어요`) |
| `Home/Home/HomeScreen.swift` | `1542:19610`, `1465:19015`, `1859:21645`(생성 중) | 프로필 실패 배너, 프로젝트 `loading`/`failed` |
| `MainShell/Router/MainShellRouter.swift` | 컴포넌트 `BottomNavigationBar` `1303:15398`(추정) | — |
| `Onboarding/Router/OnboardingRouter.swift` (+`CurationSplashView`) | `2116:31377`, `2116:31380`(C) | 약관 전문 `WebSheet` |
| `Onboarding/Tutorial/TutorialScreen.swift` | `779:33450`, `779:33529`, `779:33564` | `로그인 취소` |
| `Onboarding/LegalAgreement/LegalAgreementScreen.swift` | `786:38332`/`786:38391`, `779:33852`, `805:10982` | — |
| `Onboarding/PositionSelection/PositionSelectionScreen.swift` | `737:10375`(미선택), `737:10367`(선택됨) | `뒤로 가기 실패` 캡션 |
| `Onboarding/CareerSelection/CareerSelectionScreen.swift` | `737:10358`, `737:10349` | `제출 실패` 캡션 |
| `ProjectRegistration/RepositoryLinkInput/RepositoryLinkInputScreen.swift` | `986:13739`, `986:13646`, `986:13693`, `1338:17500`, `1342:20123` | `확인 중…` 버튼 상태 |
| `ProjectRegistration/RepositoryConfirmation/RepositoryConfirmationScreen.swift` | `737:10890` | `아바타 없음` |
| `ProjectRegistration/QuizLevelSelection/QuizLevelSelectionScreen.swift` | `737:10882`, `737:10874` | — |
| `ProjectRegistration/QuizGenerationConfirmation/QuizGenerationConfirmationScreen.swift` | `737:10830` | — |
| `ProjectRegistration/QuizGenerationProgress/QuizGenerationProgressScreen.swift` | `737:10800`, `824:12149`, `2026:29388`, 시트 `824:12536` | `FailureView`(`학습 세트를 만들지 못했어요`) — Figma 메모 `994:15057`은 미결 질문 |
| `ProjectList/ProjectList/ProjectListScreen.swift` | `1542:19495`, `1597:19052`, `1621:23431`/`1621:30561`(편집), `1621:24059`(삭제 확인) | `FailureView`, 당겨서 새로고침 |
| `ProjectDetail/Router/ProjectDetailRouter.swift` | — | 단일 문제 준비 오버레이, 진입 실패 alert |
| `ProjectDetail/ProjectDetail/ProjectDetailScreen.swift` | `1342:19562`, `1342:19609`, `1871:22144`, `1617:18786` (`1342:19659` 미확인) | `ErrorView`, 세트 빈 상태(`sets = []`) |
| `Quiz/Router/QuizRouter.swift` | — | — |
| `Quiz/LearningSetIntro/LearningSetIntroScreen.swift` | `813:15700` | 로딩, `ErrorView`, `아직 풀 수 있는 문제가 없어요.` |
| `Quiz/QuestionSolving/QuestionSolvingScreen.swift` | `1342:18657`, `1342:18711`, `1342:18925`, `1342:18946`, `1342:18678`, `1374:17084`, `1374:17109`, `855:15476`, `855:15454`, `855:15415` | `제출 중`, `제출 실패`, `순번 없는 단일 문제` |
| `Quiz/LearningCompletion/LearningCompletionScreen.swift` | `1374:17250` | `점수 없음` |
| `Saved/Saved/SavedScreen.swift` | `1597:19231`, `1597:21241`, `1597:19247`, `1597:21683` | `ErrorView` |
| `Settings/Router/SettingsRouter.swift` | — | — |
| `Settings/Profile/ProfileScreen.swift` | `1539:19209`, `1539:19358`, `1465:19359` | 로딩, `LoadFailureView` |
| `Settings/Settings/SettingsScreen.swift` (+3 단계 뷰) | `1465:19689`, `1535:18281`, `1535:18378`, `1636:31714` | 프로필 조회 실패·변경 실패·계정 삭제 실패 캡션, `선택 안 함` 값 |

## 4. 컴포넌트 인덱스 변경분

2026-08-26 컴포넌트 인덱스 이후 코드에 생기거나 바뀐 것만 적는다. 경로는 `sources/Projects/UI/Component/` 기준.

| 코드 컴포넌트 | Figma 노드 | 매핑 | 비고 |
| --- | --- | --- | --- |
| `Controls/Chip/Chip.swift` | `Chip` `1559:19998`(`Selected`=False·True), 칩 세트 `1559:20032` | 추정 | 인덱스의 `미대응` 해소. 2026-09-04: `SavedScreen+FilterSection`이 사용하도록 연결됨 |
| `CollectionItems/SelectionCard/SelectionCardStyle.swift` `.compact`(52pt) | `select card` `585:13186` 분야 화면 인스턴스 320×52 | 확정 | 인덱스의 `52pt 축약형 미대응` 해소. `PositionSelectionScreen`이 사용 |
| `CollectionItems/LearningSetRow.swift` | `학습세트 List-item` `997:18550` | 추정 | `Set N` 라벨(subtitle3 blue100) + `ProgressSegments` 세그먼트로 개편됨(025 `s01` 근거). 인덱스의 "라벨 없음·연속 막대" 불일치 기술은 낡음. Figma 노드 직접 대조는 아직 없음 |
| `Indicators/ProgressSegments.swift` | `bar` `1453:18703` | 추정 | `LearningSetRow`가 사용 |
| `CollectionItems/SavedQuestionCard/` | `저장문제` `1391:17400` | 추정 | 2026-09-04: `SavedScreen`이 사용하도록 연결됨(로컬 `QuestionRow`는 제거) |
| `CollectionItems/ProjectRow/` `isDeleting` | `ProjectList` `1621:23606` `Delete`(320×94) | 추정 | 액세서리를 재생→삭제로 바꾸는 편집 플래그. `Delete` variant 높이 94와의 대조 없음 |
| `Overlays/ConfirmationSheet.swift` | `Sheet` `1871:22308` | 확정 | 경로가 폴더(`ConfirmationSheet/`)에서 단일 파일로 바뀜 |
| `Scaffolds/ScreenContainer/ScreenContainer.swift` | — | — | 경로가 폴더 안으로 바뀜 |
| `Scaffolds/OverlayContainer/`, `Scaffolds/ScreenOverlayHeader/`, `Scaffolds/ScreenOverlayFooter/` | `Toolbar - Top` `786:34960`, `Toolbar - Bottom` `739:28772` (헤더·푸터 슬롯) | 추정 | 스크롤 위에 떠 있는 헤더·푸터. `ScreenOverlayHeader`가 `ScreenEdgeScrim.top`(`top dim` `1216:16439`)을 내부에서 사용 |
| `Controls/AppleSignInButton.swift` | 튜토리얼 CTA `Buttons - Centered` `779:33444` 인스턴스 | 추정 | 문구 `Apple로 시작하기` |
| `Controls/BookmarkButton.swift` | 아이콘 `Bookmark` `1617:26313` / `Bookmark-filled` `1617:26314` | 추정 | 문제 풀이 하단 |
| `Displays/LabeledCard.swift` | `객관식-정답` `1374:17084` 안의 `AI 해설` 카드, `Task3_14` `855:15415`의 `나의 답안`/`AI의 답안` 카드 | 미확인 | 원본 컴포넌트 노드 없음(프레임 내부 그룹) |
| `Displays/LaunchLogo.swift` | `Task1_09` `2116:31423` | C | 로고 스플래시 |
| `Displays/SplashView.swift` | `Task1_10` `2116:31377`, `2116:31380` | C | 타이핑 애니메이션 |
| `Overlays/ModalOverlay.swift` | `Sheet Modal` `786:37977`의 Overlay 레이어 | 추정 | dim + 콘텐츠 |
| `Overlays/WebSheet.swift`, `Displays/WebContentView.swift` | 없음 | 미대응 | 약관 전문 표시 |
| `CollectionItems/ChoiceResultRow.swift` | `객관식문항-답안` `1369:17327` | 추정 | **미사용** — 025가 `ChoiceAnswerOption`으로 결과 상태까지 표현하기로 결정 |
| `Controls/SelectableSettingRow/` | `마이페이지` 섹션의 `Option --> 설정` 화살표 `1636:31792`~`31794` | 미확인 | **미사용** — 설정 단계는 `SelectionCardList`를 씀 |
| `Overlays/ActionMenu/` | `Dropdown menu` `1121:15469`(목록)·`1342:19658`(상세, 확정) | 추정 | 2026-09-04: `ProjectDetailScreen`(옛 `MenuSheet`)과 `ProjectListScreen`이 함께 사용하도록 승격. 시각 계약은 `1342:19658` 확정값(폭 160·glassEffect·역할별 색)으로 통일했고 `1121:15469` 기준 181×126pt·불투명 배경은 폐기(FR-029 편차, PR에 기록) |
| `Scaffolds/BottomActionBar/` | `Toolbar - Bottom` `739:28772` | 확정(여백) | **미사용** — 화면들이 `ScreenOverlayFooter`로 이전 |
| `Controls/TextField.swift` | 없음(오매핑 정정 08-31) | 미대응 | **미사용** |

`Icon` 섹션 30개 아이콘과 `Assets.xcassets/icon/` 1:1 대응, 일러스트 7종 대응은 변동 없다.

## 5. 미매칭 체크리스트

각 항목은 **결정 또는 구현이 필요한 단위**다. 결정이 끝나면 근거(명세 FR·승인 대화·조회 노드)를 항목에
남기고 체크한다. 파일 경로는 `sources/Projects/` 기준.

### 5.1 Figma에만 있고 구현이 없는 것

- [ ] **홈 세트 생성 완료 모달** — `737:10726`(렌더 확인), `986:14959`(문구만 확인). `세트 생성이 완료되었습니다`
  제목 + 안드로이드 일러스트 + `프로젝트 확인하기` 버튼. `Feature/Home/**`에 완료 모달과 해당 문구가 없다.
  023 명세가 완료 후 홈 복귀만 정의했는지 확인한 뒤 구현 여부를 결정한다.
- [X] **프로젝트 목록 메뉴 열림 상태** — `1621:30331`. Figma는 헤더 우측 `Button - Liquid Glass - Group` →
  `Dropdown menu`(`1121:15469`)로 `프로젝트 삭제`에 진입한다. 2026-09-04 사용자가 3상태 스크린샷으로 제시해
  구현: `ProjectListFeature.State.Mode`(`browsing`/`menuPresented`/`deleting`)를 새로 두고
  `@State isEditing`을 제거(`overlay-container-migration.md` 결정 9-1 폐기). 헤더 trailing은 햄버거
  `line.3.horizontal`(`IconGlassButton`, `ProjectDetailScreen`과 동일 심볼·레이블로 일관성 확보), 메뉴는
  `Overlays/ActionMenu`(`ProjectListScreen+`가 아니라 UIComponent로 승격)로 렌더한다. `ActionMenu`의 시각
  계약은 이번에 `ProjectDetailScreen`의 옛 `MenuSheet`(폭 160·glassEffect·역할별 색) 기준으로 교정했다 —
  기존 181×126pt(spec 006 A등급 근거)를 새 Figma 조회 없이 덮어썼으므로 FR-029 편차로 PR에 남긴다. 메뉴
  항목 문구("프로젝트 삭제")는 여전히 미조회(C급, 스크린샷 근거).
- [X] **저장한 문제 필터 칩·개수 라벨** — `1597:19231`/`1597:21241`의 `전체·Flask·Now in Android` 칩 세트
  (`1559:20032`)와 `4개` 라벨. 2026-09-04 사용자가 스크린샷으로 제시해 `SavedScreen+FilterSection`으로 구현.
  025 FR-044a-6·D-010(행을 본문+버튼으로 한정)을 슈퍼시드 — 당시 제약의 근거(추가 조회 금지)는 지금도 지키지만
  (DTO가 이미 프로젝트명·세트 라벨·문제 번호를 응답에 포함), FR 문구 자체는 spec 025를 갱신하지 않아 PR에 편차로
  남긴다(사용자 결정, speckit-clarify 생략).
- [X] **저장 문제 카드 메타데이터** — Figma 카드(`저장문제` `1391:17400`)는 `Now in Android · Set 2 · 문제 1` 메타
  행 + 본문 + `문제풀기`다. 2026-09-04 위 항목과 함께 `SavedQuestionCard`로 구현. `SavedScreen+QuestionRow`는 삭제.
- [ ] **프로필 주간 메시지 변형** — `1539:19358` `이번 주도 차근차근 풀고 있어요`, `1465:19359`
  `이번 주 학습을 하루도 놓치지 않았어요`. 코드는 0문제일 때만 Figma 문구를 쓰고 그 외 `이번 주 N문제를 풀었어요`.
  변형 조건(풀이 수·연속 일수)이 Figma에 명시되지 않아 026 명세로 확정해야 한다.
- [X] **프로젝트 삭제 화면 헤더 제목** — `1621:23431`/`1621:30561`은 제목이 `프로젝트 삭제`다. 2026-09-04
  `ProjectListScreen`의 삭제 모드(`Mode.deleting`) 헤더를 `title: "프로젝트 삭제"`, `leading: .back`,
  `trailing: nil`로 교정해 일치시켰다(`ScreenHeader.Style.largeTitle` 그대로, 새 스타일 불필요). 두 프레임
  사이 차이는 여전히 미확인. **미검증**: 같은 스크린샷의 하단 탭바 부재를 `.toolbar(.hidden, for: .tabBar)`로
  구현했으나 이 저장소에 `.toolbar`/`NavigationStack` 선례가 전혀 없어(grep 0건) 시뮬레이터 확인 전까지는
  동작을 보장할 수 없다. spec 006 계약(`screen-inventory.md`)은 원래 `deleting`을 별도 화면이 아니라 같은
  화면의 상태 변형으로만 확정했으므로, 탭바 숨김 자체가 계약 밖의 사용자 직접 지시에 따른 추가 시도다.
- [ ] **저장 화면 Inline Title 헤더 변형** — `1597:19231`, `1597:19247`(43pt). 코드는 `.largeTitle`만. 스크롤 시
  축소 헤더로 볼지, 진입 경로별 변형으로 볼지 결정한다.
- [ ] **학습 완료 점수 표기** — `1374:17250`은 `7`/`7` 큰 숫자 두 개로 표시한다. 코드 점수 블록의 표기 형식은
  이번 조사에서 대조하지 않았다(레이아웃 미대조 범위).
- [ ] **설정 `알림` 섹션** — `1465:19689`의 `세트 생성 완료 알림 · 켜짐` 행. 026 FR-014로 제외한 승인된 차이.
  범위에 다시 넣을 때만 체크한다.

### 5.2 코드에만 있고 Figma 근거가 없는 상태

Figma를 근거로 교정할 수 없다. 각 상태의 근거 명세를 적고, 없으면 승인 대상으로 남긴다.

- [ ] `AppEntryScreen` 복구 오류(`세션을 확인하지 못했어요`) — 016 근거 확인
- [ ] `HomeScreen` 프로필 실패 배너, 프로젝트 `loading`/`failed` — 018 근거 확인
- [ ] `TutorialScreen` 로그인 취소, `LegalAgreement` 약관 전문 `WebSheet` — 016
- [ ] `PositionSelectionScreen` 뒤로 가기 실패, `CareerSelectionScreen` 제출 실패 캡션 — 016/017
- [ ] `RepositoryLinkInputScreen` `확인 중…`, `RepositoryConfirmationScreen` 아바타 없음 — 019
- [ ] `QuizGenerationProgressScreen+FailureView` — Figma 메모 `994:15057`(`오류가 발생하는 경우…`)은 미결 질문. 019/022
- [ ] `ProjectListScreen+FailureView`, 당겨서 새로고침 — 025 후속 작업 3
- [ ] `ProjectDetailScreen` `ErrorView`·세트 빈 상태(`sets = []`), `ProjectDetailRouter` 단일 문제 준비·실패 alert — 025 D-014
- [ ] `LearningSetIntroScreen` 로딩·실패·문제 없음, `QuestionSolvingScreen` 제출 중·제출 실패·단일 문제,
  `LearningCompletionScreen` 점수 없음 — 025
- [ ] `SavedScreen+ErrorView` — 025 FR-044a-7
- [ ] `ProfileScreen` 로딩·조회 실패, `SettingsScreen` 실패 캡션 3종·`선택 안 함` — 026

### 5.3 대응하지만 Figma와 다른 것

- [ ] **홈 생성 중 CTA 문구** — Figma `1859:21645` `문제 생성 중`, 023 명세 FR-006도 `문제 생성 중`, 코드
  `Home/Home/SubViews/HomeScreen+RegistrationPanelView.swift`는 `학습세트 생성 중...`. 명세대로 교정 대상.
- [ ] **객관식 편집 CTA 문구** — Figma `1342:18657` `확인`, 025 명세 `s03`·screen-flow §2.4도 `확인`, 코드
  `Quiz/QuestionSolving/QuestionSolvingScreen.swift:149`는 `제출하기`/`다시 제출하기`. 명세대로 교정 대상.
- [ ] **학습 완료 문구** — Figma `1374:17250` 제목 `학습 완료`, 메시지 `세트의 모든 문제를 다 맞췄어요!`, CTA `다음`.
  코드 `학습을 마쳤어요` / `다음 세트에서 이어서 학습해 보세요.` / `확인`. 025 명세에 문구 확정이 없으므로 결정 필요.
  (Figma 메시지는 전부 정답일 때의 변형일 수 있음 — 부분 정답 문구 미확인)
- [ ] **서술형 글자 수 한도** — Figma `855:15476` `0 / 300`, 코드·025 명세 400. 명세 우선(승인된 차이). 기록만.
- [ ] **결과 상태 CTA `정답 확인`** — Figma `855:15415` 등. 025 명세가 자료 오류로 판정(`advanceActionTitle` 사용). 기록만.
- [ ] **`SettingRow` ↔ `세부설정` `1433:18243`** — 좌측 아이콘 24·높이 56·px 20·값 톤이 다르다. UI 확장 승인 대기(026).
- [ ] **프로필 통계 카드 `Gradient 4`** — DesignSystem 토큰 없음, 색 토큰 조합으로 구현. 토큰 추가 여부 결정.
- [ ] **홈 `전체 보기`/`전체보기`** — Figma 두 프레임 사이에도 표기가 다르다(`1542:19610` 띄어쓰기 있음, `1465:19015` 없음).
  코드는 `전체 보기`. 디자인 측 확정 필요.
- [ ] **`LearningSetRow` ↔ `997:18550`** — 025 사설 렌더 `s01` 기준으로 개편됐고 Figma 노드 직접 대조는 없다. 조회 후
  `추정`→`확정` 갱신.
- [ ] **약관 행 `(필수)` 표기** — Figma 문구 접미어 vs 코드 `PolicyAgreementRow` `필수`/`선택` 배지. 08-27 조회에서 원본
  배치 편차로 판단. 기록만.

### 5.4 추가 조회가 필요한 것

- [ ] `1342:19659` — 프로젝트 상세 4번째 프레임. 나머지 3개(전체·메뉴·삭제)와의 차이
- [ ] `986:14959` — `홈 - 생성 완료` 두 번째 프레임 렌더(`737:10726`과 같은 모달인지)
- [ ] `779:33852` vs `805:10982` vs `786:38332` — 약관 시트 3프레임의 상태 차이(렌더는 앞 두 개가 동일)
- [ ] `1621:24059` — 삭제 모달의 제목·설명 문구(코드 `프로젝트를 삭제할까요?` / `학습 문제와 진도가 모두 삭제되며…`와 대조)
- [ ] `1621:30331` — 프로젝트 목록 메뉴 항목 문구
- [ ] `1621:23431` vs `1621:30561` — 삭제 화면 두 프레임의 차이
- [ ] `2023:28703` `애니메이션 및 앱 에셋` — 개별 노드와 `ResourceAnimation.Asset`(`complete`, `generalLoading`,
  `notification`, `projectEmpty`, `setCreationLoading`, `storageEmpty`) 대응
- [ ] `1374:17250` — 부분 정답일 때의 완료 메시지 변형 존재 여부
- [ ] `Task4_06` 카드의 `해설보기`(튜토리얼 배경 목업 `786:38332`에서만 보임) — 저장 화면 카드 액션이 `문제풀기`와
  `해설보기` 두 종류인지

### 5.5 문서·프리뷰 정비

- [ ] `#Preview` 이름에 노드 ID 부여(스킬 4단계 규칙): `ProjectListScreen`(`1542:19495`, `1597:19052`, `1621:24059`),
  `SavedScreen`(`1597:21241`, `1597:21683`), `AppEntryScreen`(`2116:31423`), `OnboardingRouter` curation(`2116:31380`),
  `LearningSetIntroScreen`(`813:15700`), `QuestionSolvingScreen`(`1342:18657` 등 2.5 표), `LearningCompletionScreen`(`1374:17250`),
  `ProjectDetailScreen`(`1342:19562`, `1342:19609`, `1871:22144`)
- [ ] `PositionSelectionScreenPreviews`의 `미선택` 프리뷰 노드 ID를 `737:10367` → `737:10375`로 정정
- [ ] `QuestionSolvingScreenPreviews`의 `s06`/`s07` 이름을 025 screen-flow §1(스크롤 상태)과 맞추거나 계약을 갱신
- [ ] 스킬 `references/figma-index.md`·`component-index.md` 갱신 — 이번 세션에서 1장·2.3·2.4·2.5·4장의 사실을 반영했다
  (로컬 전용 파일이라 커밋에는 포함되지 않는다)

## 6. 미검증 범위

- 레이아웃·색·타이포 실측 비교는 하지 않았다. `✅`는 상태·문구·구성 요소 대응을 뜻하며 ±0.5pt 검증을 뜻하지 않는다.
- `get_design_context`·`get_variable_defs`는 호출하지 않았다. SF Symbol·자산 이름·토큰 값은 이번 조사로 확정하지 않는다.
- 빌드·테스트·Simulator 렌더는 실행하지 않았다.
