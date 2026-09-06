# Figma UI 디테일 점검

조사일: 2026-09-04 · 브랜치: `feature/my-page` · 기준 인덱스: [figma-ui-coverage-checklist.md](./figma-ui-coverage-checklist.md)

각 화면을 인덱스가 확정한 Figma 노드와 **상수값 수준**으로 대조한다. 비교 대상은 auto-layout 방향·간격·패딩,
고정 표면 크기(버튼·썸네일·아이콘 박스)·모서리 반경, 아이콘 자산·SF Symbol, 색 변수 ↔ DesignSystem 토큰,
텍스트 스타일 ↔ `StyledText`다. 360×800 프레임 크기와 화면 폭에 종속된 값(가로 폭, 절대 좌표)은 비교하지 않는다.

조회 수단은 `use_figma` 읽기 전용 스크립트(auto-layout·fill 변수·텍스트 스타일·인스턴스 원본 추출)이며, 값의 근거
수준은 스킬 규약(`A` 직접 조회 / `B` 확정 계약 / `C` 렌더·추론)을 따른다.

판정 표기: `✅` 일치(±0.5pt) · `⚠️` 차이(Figma 값 / 코드 값 병기) · `❔` 미확인 · `승인` 명세가 우선하는 승인된 차이.

## 점검 목록

- [x] 1. `AppEntryScreen` ↔ `2116:31423`
- [x] 2. `OnboardingRouter+CurationSplashView` ↔ `2116:31377`, `2116:31380`
- [x] 3. `TutorialScreen` ↔ `779:33450`, `779:33529`, `779:33564`
- [x] 4. `LegalAgreementScreen` ↔ `786:38391`
- [x] 5. `PositionSelectionScreen` ↔ `737:10375`, `737:10367`
- [x] 6. `CareerSelectionScreen` ↔ `737:10358`, `737:10349`
- [x] 7. `RepositoryLinkInputScreen` ↔ `986:13646`, `1338:17500`
- [x] 8. `RepositoryConfirmationScreen` ↔ `737:10890`
- [x] 9. `QuizLevelSelectionScreen` ↔ `737:10882`, `737:10874`
- [x] 10. `QuizGenerationConfirmationScreen` ↔ `737:10830`
- [x] 11. `QuizGenerationProgressScreen` (+`GenerationReminderSheet`) ↔ `2026:29388`, `824:12536`
- [x] 12. `HomeScreen` ↔ `1465:19015`, `1542:19610`, `1859:21645`
- [x] 13. `ProjectListScreen` ↔ `1542:19495`, `1597:19052`, `1621:23431`, `1621:24059`
- [x] 14. `ProjectDetailScreen` ↔ `1342:19562`, `1342:19609`, `1871:22144`
- [x] 15. `LearningSetIntroScreen` ↔ `813:15700`
- [x] 16. `QuestionSolvingScreen` ↔ `1342:18657`, `1342:18711`, `1374:17084`, `1374:17109`, `855:15476`, `855:15415`, `1342:18699`
- [x] 17. `LearningCompletionScreen` ↔ `1374:17250`
- [x] 18. `SavedScreen` ↔ `1597:21241`, `1597:21683`
- [x] 19. `ProfileScreen` ↔ `1539:19209`
- [x] 20. `SettingsScreen` (+분야·수준·계정 삭제) ↔ `1465:19689`, `1535:18281`, `1535:18378`, `1636:31714`
- [x] 21. `MainShellRouter`/`TabShell` ↔ `BottomNavigationBar` `1303:15398`

## 화면별 점검

공통으로 확인한 Figma 컴포넌트 값(`A`): `Toolbar - Top/Default` 360×50 = 컨트롤 행 40 + 하단 패딩 10, 좌우 패딩 20,
`Button - Liquid Glass - Icon/MD` 40×40(패딩 8, 아이콘 24, r99, `Opacity/white 5`, GLASS 20).
`Button/LG` 320×54 r12 패딩 15/12, 라벨 `Body 1`; Primary = `Blue100` 배경 + `Grey700` 라벨, Secondary = `Grey500` +
`Grey100`, Primary Disabled = `Grey500` + `Opacity/white 30`, Primary Text = 배경 없음 + `Blue100` 라벨.
`Toolbar - Bottom` 패딩 4/20/24/20, 버튼 간격 8. 코드 대응: `ScreenHeader.Style.default` 50(컨트롤 40 + 하단 10),
`IconGlassButton.medium` 40/아이콘 24, `ActionButton.large` 54·r12·`body1`, `BottomActionBar` 상단 4·하단 24. 이 공통값은
모두 `✅`이며 화면별 표에서는 반복하지 않는다.

### 1. `AppEntryScreen` ↔ `2116:31423` (로고 스플래시)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 배경 | `Grey/Grey700` | `ScreenContainer` `.screenBackground`(grey700 `#141414`) | ✅ |
| 로고 표면 | Vector 94×97, 프레임 중앙(x133/y343) | `LaunchLogo` `app-logo-image` 120×120, 중앙 | ⚠️ 94×97 / 120×120. 자산 여백 포함 여부 미확인 |
| 배경 장식 | 하단 Rect 455×620(y427) `LINEAR #a5c4f0 0%→100%`, 불투명도 0.2 | 로고 뒤 `RadialGradient` `blue300`(`#7E94BB`) 0.18→0, 220pt 원, blur 24 | ⚠️ 형태·색·위치 모두 다름(하단 선형 `#a5c4f0` / 로고 주변 방사형 `#7E94BB`) |
| 복구 오류 상태 | 없음 | `+ErrorView` subtitle2·body2 grey400·`ActionButton.primary`, 간격 16 | ❔ Figma 근거 없음 |

### 2. `OnboardingRouter+CurationSplashView` ↔ `2116:31377`, `2116:31380`

| 항목 | Figma (`A`) | 코드 (`SplashView`) | 판정 |
| --- | --- | --- | --- |
| `Hello World` | Plus Jakarta Sans **SemiBold** 22, lh 140%, `Grey/Grey400` | `.splashSubtitle` **bold** 22 / 140%, `grey400` | ⚠️ 굵기 SemiBold / Bold. 번들 폰트가 Regular·Medium·Bold뿐이라 SemiBold 부재 |
| `Let's Git-it!` | Plus Jakarta Sans Bold 44, lh 140%, 세그먼트별 색(`Git-it!` 파랑, 렌더 C) | `.splashTitle` bold 44 / 140%, `Let's ` grey100 + `Git-it!` blue100, 자간 −0.98 | ✅ 크기·굵기·색 / ❔ 자간(Figma 미조회) |
| 두 줄 간격 | 329+31 → 363 = **3** | `VStack(spacing: 4)` | ⚠️ 3 / 4 |
| 정렬 | 두 텍스트 모두 center | `HStack` `.frame(alignment: .leading)` 안에서 중앙 `VStack` | ✅(렌더 기준) |
| 커서 막대 | 없음(정적 프레임) | 1.65×20.24 / 3.3×40.48 커서 | ❔ 애니메이션 요소, Figma 근거 없음 |

### 3. `TutorialScreen` ↔ `779:33564` (1·2면은 같은 chassis, 08-26 `A`)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 상단 영역 배경 | Frame 360×569 `Blue/Blue500` | `TabView` 배경 `blue500`(`#2F3853`) | ✅ |
| 제목 | `Subtitle 1` `Grey100` center, y121(상태바 53 → 68) | `subtitle1` center, `.padding(.top, 68)` | ✅ |
| 제목→목업 간격 | 187 → 225 = 38 | `Spacer(minLength: 20)` 가변 | ❔ 기기 높이 종속 |
| 목업 | 212×471 r12, `#141414` fill, `#ffffff@10%` 6pt OUTSIDE stroke | `OnboardingMockup` PNG 448×700, 폭 212 고정, 베젤 없음(`bezelWidth 8` 미사용) | ⚠️ 테두리·반경이 PNG에 포함됐는지 미확인 |
| 페이지 점 | 44×8, 점 8, 간격 10, y582 | `PageIndicator` 점 8, 간격 10, `.padding(12)` | ✅ 크기·간격 / ❔ 점 색(Figma `🧰/Dots` 미조회, 코드 white·grey500) |
| 툴팁 `3초만에 가입하기` | 126×36, 패딩 8/12, r8, `Grey600` fill + `Grey500` 1pt stroke, DROP_SHADOW r4 ×2, Noto Sans KR Regular 14 lh140% `Grey100`, beak | `caption1`(regular 12) `grey400` 평문, 말풍선 없음 | ⚠️ 말풍선·굵기·크기·색 모두 다름(08-26 인덱스 "토큰 미확정") |
| 점→버튼 세로 구성 | 점 y582 → 버튼 y641 (59) | `VStack` 기본 간격(≈8) + 패딩 12 + 캡션 + 8 | ⚠️ 기본 간격 의존, 실측 없음 |
| Apple 버튼 | `Buttons - Centered` 321×54 r12 `#ffffff`, 패딩 0/15, 아이콘-라벨 간격 5, 애플 글리프 SF Pro Semibold 19, 라벨 `Body 1` `#000` | `AppleSignInButton` 54·r12·white, `applelogo` 16pt, 간격 6(`iconSpacing`), `body1` black | ⚠️ 글리프 19 / 16, 간격 5 / 6 |
| 버전 문구 | `Body 2` `Grey/Grey500`, 버튼 하단 695 → 716 = 21, 프레임 하단 여백 63(홈 인디케이터 34 + 29) | `body2` `grey500`, `.padding(.top, 21)`, `.padding(.bottom, 29)` | ✅ |

### 4. `LegalAgreementScreen` ↔ `786:38391` (`Sheet Modal` 인스턴스)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 오버레이 | `Opacity/Black 70` | `ModalOverlay` black 70%(`OpacityToken.scrim`) | ✅ |
| 시트 배경·모서리 | `Grey/Grey600`, 반경 값 미조회 | `SheetSurface` `cardBackground`(grey600), 상단 반경 16 | ✅ 색 / ❔ 반경 |
| 그래버 | 58×4 r100 `Grey/Grey500`, 상단 5 | 58×4, 상단 5, 하단 7, **`grey400`** | ⚠️ 색 Grey500 / grey400 (`SemanticColorToken.grabber` = grey500 미사용) |
| 그래버→제목 | 9 → 28 = 19 | 7 + 제목 상단 12 = 19 | ✅ |
| 제목 | `Toolbar - Top/Inline Title` 43 = 33 + 하단 10, `Subtitle 1` `Grey100` left, 좌우 20 | `subtitle1` leading, 상·하 12, 좌우 20 | ⚠️ 제목 하단 10 / 12 |
| 전체 동의 행 | 320×54 r10 `Grey500`, 패딩 11/22/12/17, 체크 24 + 간격 12, 텍스트 Noto Sans KR **Medium 14** lh31 `Grey100` | 54·r10·`raisedBackground`(grey500), 좌우 17, 체크 24 + 12, **`body1`(16)** | ⚠️ 글자 크기 14 / 16 |
| 전체 동의 → 첫 문서 행 | 137 → 144 = 7 | `VStack(spacing: 0)` | ⚠️ 7 / 0 |
| 문서 행 | 320×54 r10 `Grey600`(시트와 동일), 패딩 12/0/12/17, 행 간격 0, 체크 24 + 12, 텍스트 Medium 14, 우측 `Liquid Glass Icon/SM·Text` 36 | `PolicyAgreementRow` 54, 좌측 19(화면 파일 하드코딩), 체크 24 + 12, `body1`(16), 우측 SF `chevron.right` `grey300` 44×44 | ⚠️ 좌측 17 / 19, 글자 14 / 16, 우측 컨트롤 36 글래스 / 44 평문 chevron(색 미조회) |
| 체크 아이콘 | `Check/status=Check`(`ic-status-check`) | `ic-checkmark-checked`(파일 `ic-status-check.svg`) / 미선택 `ic-checkmark-disable` | ✅ 선택 / ❔ 미선택(Figma 프레임은 전부 선택 상태). 두 imageset 모두 template 렌더링이 아니라 `.designSystemForeground` 틴트가 적용되지 않음 |
| 버튼 | `Toolbar - Bottom/Horizen`: 마지막 행 252 → 버튼 277 = 25, 156×54 ×2 간격 8, 취소 Secondary + 다음 Primary, 하단 24 | 상단 25, `HStack(spacing: 8)`, `ActionButton.secondary`/`.primary`, `SheetSurface` 하단 24 | ✅ |

### 5. `PositionSelectionScreen` ↔ `737:10375`(미선택), `737:10367`(선택됨)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Default` 50, 좌측 글래스 아이콘 40 | `ScreenOverlayHeader(.default)` 50, `IconGlassButton.medium` 40, SF `xmark` 24 | ✅ (Figma 아이콘 종류는 미조회) |
| 제목 | `Subtitle 1` `Grey100` center, 헤더 하단 103 → 123 = 20 | `subtitle1` center, `.padding(.top, 20)` | ✅ |
| 제목→목록 | 189 → 253 = 64 | `titleToOptionsSpacing` 64 | ✅ |
| 목록 간격 | 8 | `SelectionCardList` 8 | ✅ |
| 카드 표면 | 320×52, 패딩 14, r12 | `.compact` minHeight 52, 패딩 14, r12 | ✅ |
| 카드 배경 | `Grey/Grey600` | `SelectionCard` `.screenBackground`(**grey700**) | ⚠️ Grey600 / grey700 |
| 카드 테두리(미선택) | 없음 | `BorderToken.default` grey500 1pt | ⚠️ 없음 / grey500 |
| 카드 테두리(선택) | `Blue/Blue200` 1pt OUTSIDE | `BorderToken.focus` **blue100** 1pt + `selectedSurface` white5 채움 | ⚠️ Blue200 / blue100, 선택 채움 white5는 Figma에 없음 |
| 카드 제목 | `Subtitle 3` `Grey100` | `subtitle3` grey100 | ✅ |
| 하단 버튼 | Primary LG y688, 하단 여백 24 | `ScreenOverlayFooter` + `ActionButton.primary`, 하단 24 | ✅ |
| 오류 캡션 | 없음 | `caption1` `.error` | ❔ Figma 근거 없음 |

### 6. `CareerSelectionScreen` ↔ `737:10358`(미선택), `737:10349`(선택됨)

5번과 같은 헤더·제목·간격·카드 표면·테두리 판정을 공유한다(카드 배경 Grey600 / grey700, 선택 테두리 Blue200 / blue100 ⚠️).

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 카드 높이 | 320×80 | `.detailed` minHeight 80 | ✅ |
| 썸네일 | 52×52 r8, 배경 `Grey/Grey500` + 일러스트 벡터 | 52×52 r8, `illust_level_*` 이미지 + `gradient3` 0.2 오버레이 | ⚠️ 배경 Grey500·오버레이 없음 / gradient3 0.2 오버레이(자산 자체는 미대조) |
| 썸네일→텍스트 | 16 | `thumbnailSpacing` 16 | ✅ |
| 제목/보조 | `Subtitle 3` `Grey100` / `Caption 1` `Grey/Grey300`, 간격 3 | `subtitle3` / `caption1` grey300, `titleSpacing` 3 | ✅ |
| 안내 문구 | `Caption 1` `Grey/Grey400`, 문구 하단 676 → 버튼 688 = 12 | `caption1` grey400, 푸터 `VStack(spacing: 12)` | ✅ |
| 일러스트 자산 | `Illust_Levels_Beginner/Junior/Mid/Senior` | `illust_level_entry/junior/middle/senior` | ✅ 대응(내용 미대조) |

### 7. `RepositoryLinkInputScreen` ↔ `986:13646`(Secondary 버튼), `1338:17500`(Primary Disabled)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더·제목 위치 | 콘텐츠 Frame y121 = 상태바 53 + 68 | `ScreenHeader(.largeTitle)` 99(제목 없음) + 상단 32 = 131 | ⚠️ 68 / 131 |
| 제목 | `Subtitle 1` `Grey100` left | `subtitle1` leading | ✅ |
| 제목→필드 | 16 | `titleFieldSpacing` 16 | ✅ |
| 텍스트 필드 | 320×56, 하단 인디케이터 1px `Blue100`, 라벨 구분선 1×20 r10 `Grey300`(x42) | `LabeledTextField` 높이 56, 밑줄 1 `blue100`, 라벨 `body2` + 간격 16, 구분선 없음 | ✅ 높이·밑줄 / ⚠️ 라벨 구분선 없음 |
| 오류 상태 | 인디케이터 `State/Error`, 트레일링 아이콘 48×48, 보조문 `Caption 1` `State/Error` 패딩 4/16/0/47 | 밑줄·라벨 `error`, 지우기 44×44(아이콘 20 `ic-cancel`), `caption1` error 상단 4·좌측 47 | ✅ 색·보조문 / ⚠️ 트레일링 48 / 44 |
| 필드→안내 카드 | 32 | `fieldGuideSpacing` 32 | ✅ |
| 안내 카드 표면 | 320×206 r12 `Grey600` | `cardBackground` r12 | ✅ |
| 카드 헤더 | 56, 패딩 10/10/10/20, `Body 2` `Blue100`, 우측 36 박스 안 `ChevronUp1` 16 | 높이 54, 좌우 20·상하 12, `body2` blue100, `ic-chevron-up-1` 12 | ⚠️ 56 / 54, 우측 패딩 10 / 20, 셰브론 16 / 12 |
| 카드 본문 | 패딩 10/20/10/20, 단계 간격 10, 행 H 간격 12, 불릿 16 원 `Grey500` + `Caption 1` `Grey100` | 좌우 20·하단 20·상단 0, 10, 12, 원 16 grey500 + `caption2` grey300 번호 + `caption1` grey100 | ✅ 간격·불릿 / ⚠️ 상단 10 / 0, 하단 10 / 20 |
| 하단 버튼 | `986:13646` Secondary(`Grey500`, 라벨 **`Grey300`**) · `1338:17500` Primary Disabled(`Grey500`, `white 30`) | `ActionButton.primary` 비활성 = grey500 + white30 | ✅ `1338:17500` / ⚠️ `986:13646` 라벨 Grey300(Figma 두 프레임이 서로 다름) |
| 버튼 하단 여백 | 24(+홈 인디케이터 34) | `.padding(.bottom, 34)` + 안전영역 | ⚠️ 24 / 34 |

### 8. `RepositoryConfirmationScreen` ↔ `737:10890`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 제목 | `Subtitle 1` `Grey100` center, y225 | `subtitle1` center, Spacer로 수직 중앙 | ✅ 스타일 / ❔ 위치 |
| 제목→썸네일 | 291 → 336 = 45 | `VStack(spacing: 16)` + `thumbnailTopPadding` 40 = 56 | ⚠️ 45 / 56 |
| 썸네일 | 80×80 r10 IMAGE | 80×80 `.medium`(10), 자리표시 grey600 + `gradient3` 0.2 | ✅ 크기·반경 / ❔ 오버레이 |
| 썸네일→텍스트 | 21 | `thumbnailSpacing` 12 | ⚠️ 21 / 12 |
| 소유자 | Plus Jakarta Sans **Regular** 14, `Grey100` 불투명도 0.5 | `body2`(Medium 14) `white70` | ⚠️ 굵기 Regular / Medium, 불투명도 50 / 70 |
| 저장소 이름 | Plus Jakarta Sans Bold 16 lh148% | `subtitle3` | ✅ |
| 버튼 | Toolbar-Bottom Vertical: Primary "다음" + Secondary, 간격 8, 하단 24 | `VStack(spacing: 8)` primary + secondary, 하단 34 | ✅ 구성 / ⚠️ 하단 24 / 34 |

### 9. `QuizLevelSelectionScreen` ↔ `737:10882`(미선택), `737:10874`(선택됨)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 제목 위치 | `Subtitle 1` **left**, y123 = 상태바 53 + Toolbar 50 + 20 | `.largeTitle` 99 + `titleTopPadding` 24 = 123 아래 | ⚠️ 70 / 123 (헤더 50 / 99) |
| 제목→목록 | 189 → 235 = 46 | `listTopPadding` 32 | ⚠️ 46 / 32 |
| 카드 | 6번과 동일(80, 패딩 14, 간격 16, r12, `Grey600`, on = `Blue200` 1 OUTSIDE, 썸네일 52 r8 `Grey500`) | `SelectionCardList(.detailed)` | ⚠️ 배경 Grey600 / grey700, 선택 테두리 Blue200 / blue100, 미선택 테두리 없음 / grey500 |
| 일러스트 자산 | `Illust_Knowledge_*` | `illust_knowledge_basic/intermediate/advanced` | ✅ 대응 |
| 버튼 | Primary, 하단 24 | primary, 하단 34 | ⚠️ 24 / 34 |

### 10. `QuizGenerationConfirmationScreen` ↔ `737:10830`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| Text Set | V 간격 16 center: `Subtitle 1` `Grey100` + `Body 2` `Grey400` | `VStack(spacing: 16)` `subtitle1` center + `body2` grey400 center | ✅ |
| 위치 | y322 고정 | Spacer 중앙 정렬 | ❔ |
| 버튼 | Primary "시작하기", 하단 24 | primary, 하단 34 | ⚠️ 24 / 34 |

### 11. `QuizGenerationProgressScreen` ↔ `2026:29388`, `GenerationReminderSheet` ↔ `824:12536`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 배경 그라데이션 | Rect 455×620 y457, LINEAR `#141414` 0% → `#a5c4f0` 100% (프레임 기준 0.57 → 1.35) | `gradient2` 색 + start y 0.6868 / end y 1.792 | ✅ 색 / ⚠️ 시작·끝 위치 |
| 로딩 그래픽 | 200×200, y97 | Lottie `set-creation-loading` 200, `Spacer(minLength: 97)` + 방사형 마스크 | ✅ 크기 / ❔ 안전영역 기준 여부, 마스크 |
| 그래픽→Text Set | 297 → 322 = 25 | `loadingGraphicBottomSpacing` 25 | ✅ |
| Text Set | 간격 16, `Subtitle 1` + `Body 2` `Grey400` | 16, `subtitle1` + `body2` grey400 | ✅ |
| Text Set→체크리스트 | 392 → 445 = 53 | `.padding(.vertical)` 기본값 | ⚠️ 53 / 시스템 기본(≈16) |
| 체크리스트 | V 간격 19, 행 H 간격 **14**, 아이콘 24, `Body 2` 완료·진행 `Grey100` / 대기 `Grey400` | 19, 행 간격 **12**, 24, `body2` grey100 / grey400 | ⚠️ 행 간격 14 / 12 |
| 상태 아이콘 | Check / Loading(ANGULAR `#b9d6fe`→`Blue400`, stroke 4 INSIDE) / disable(stroke `Grey400` 4) | `ic-status-check` / Lottie `general-loading` / `ic-status-loading-disable` | ✅ 자산 대응 / ❔ 진행 아이콘 형태 |
| 하단 버튼 | Primary Text "홈에서 기다리기", 라벨 **`Blue100`**, 하단 24 | `ActionButton.text` 라벨 **grey100**, `.padding(.bottom, 58)` | ⚠️ 라벨 Blue100 / grey100, 하단 24 / 58 |
| 시트 표면 | 360×460 `Grey600`, DROP_SHADOW 34·6 | `SheetSurface` grey600, 그림자 없음(`EffectToken.sheetElevation` 미적용) | ⚠️ 그림자 |
| 그래버 | 58×4 `Grey500` | 58×4 grey400 | ⚠️ 색 |
| 그래버→알림 그래픽 | 9 → 37 = 28 | 7 + `contentTopPadding` 16 = 23 | ⚠️ 28 / 23 |
| 알림 그래픽 | 120×120 | Lottie `notification` 120 | ✅ |
| 그래픽→Text Set | 157 → 188 = 31 | `contentSpacing` 24 | ⚠️ 31 / 24 |
| Text Set | 간격 8, `Subtitle 1` + `Caption 1` `Grey400` | 8, `subtitle1` + `caption1` grey400 | ✅ |
| 버튼 | Primary LG + **SM Text**(36, `Body 2` `Grey100`), 간격 8, 하단 24 | primary large + `.text(size: .medium)`(40, `body1`), 8, 24 | ⚠️ 보조 버튼 36·Body 2 / 40·body1 |
| 실패 상태 | 없음 | `+FailureView` | ❔ Figma 근거 없음 |

### 12. `HomeScreen` ↔ `1465:19015`(카드 있음), `1542:19610`(빈 덱), `1859:21645`(생성 중)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 사용자 헤더 | `Toolbar - Top/Inline User` 74 at y53(안전영역 바로 아래), 패딩 22/0/10/0, 아바타 40 + 간격 11, 이름 `Subtitle 3`, 역할 `Body 3` `#a1a1a1`@0.6 | `ScreenHeader(.inlineUser)` 74, 상단 22, 아바타 40, 간격 11, `subtitle3`, `body3` grey400 + 추가 `.padding(.top, 12)` | ✅ 구조 / ⚠️ 추가 상단 12, 역할 색 `#a1a1a1`@60% / grey400 |
| 인사말 | Frame 패딩 12/20/20/20, 한 텍스트 노드 Plus Jakarta Sans Bold 30(= Headline 1) | 헤더 아래 16, `headline1` 두 줄(grey400 / grey100), `VStack(spacing: 0)` | ⚠️ 상단 12 / 16 · ❔ 두 줄 색(Figma fill 미조회, 렌더 C) |
| 인사말→등록 패널 | 20(프레임 하단 패딩) | `.padding(.top, 24)` | ⚠️ 20 / 24 |
| 등록 패널 | 320×133 r12 `Grey600`, 패딩 13/12/12/16 | minHeight 133, r12, grey600, `EdgeInsets(13, 16, 12, 12)` | ✅ |
| 패널 텍스트 | V 간격 5: `Caption 1` `#919191` + `Subtitle 3` `#ffffff` | 5: `caption1` grey400 + `subtitle3` grey100 | ✅ |
| 패널 버튼 | 104×37 r10 `Blue100`, `Body 2` `Grey700`, 텍스트 바로 아래(간격 0) | 104×37 `.medium`(10) blue100 `body2` grey700, `Spacer(minLength: 12)` | ✅ 표면 / ⚠️ 텍스트→버튼 0 / ≥12 |
| 패널→섹션 헤더 | 366 → 391 = 25 | `projectSectionTopPadding` 32 | ⚠️ 25 / 32 |
| 섹션 헤더 | 좌우 20, `Subtitle 3` `#ffffff`, 우측 SM Text 92×36 패딩 7/8/8/8: `Body 2` `Blue100` + `ChevronRight1` 16, 간격 8 | 좌우 20, `subtitle3`, `body2` blue100 + `ic-chevron-right-1` **12**, 간격 8, 패딩 8 | ⚠️ 셰브론 16 / 12 |
| 섹션 헤더→카드 | 427 → 452 = 25 | `sectionHeaderSpacing` 16(+회전 여유) | ⚠️ 25 / 16 |
| 카드 좌측 여백 | 콘텐츠 x20 | `ProjectSection.screenMargin` **16** (헤더는 20) | ⚠️ 20 / 16 |
| 카드 표면 | 154×192 r12, `Purple300` / `Blue100` / `Blue500` | 154×192 r12, purple300 / blue100 / blue500 | ✅ |
| 카드 헤더 | 패딩 18/10/0/14, 텍스트 열 V 간격 6, `Play1` 36(패딩 2 → 32) | 상단 18·좌 14·우 46(=10+36), 6, 원 32 in 36 | ✅ |
| 카드 진행 바 | 높이 5, 좌우 14, 헤더 아래 12; `Blue500` 카드 트랙 `Purple300` | 5, 14, 12; darkBlue 트랙 purple300 | ✅ |
| 카드 푸터 | 패딩 0/10/18/12, 내부 V 간격 3, 세트 칩 19 r99 `Blue400` 패딩 2/5, `Caption 1` `Grey100` | 좌 12·우 10·하 18, 3, 캡슐 19 패딩 5 blue400(darkBlue), `caption1` grey100 | ✅ |
| 카드 제목·기술 | 텍스트 열 94×80(스타일 미조회) | `Constant.titleStyle` bold 18/120%, `caption2` | ❔ |
| 덱 회전 | 12° / −16° / 0° | `HomeCardScrollLayout` ±16, −12 | ✅ 근사 |
| 빈 덱 | Union 501×237 `Blue500` fill + `Blue300` 1 INSIDE stroke, 문구 `Body 2` `Purple200` | `EmptyDeckShape` 501.331×236.627 blue500 + blue300 **lineWidth 4**, `body2` purple200 | ✅ 색·문구 / ⚠️ 선 1 / 4 |
| 생성 중 카드 | 라벨 문구 불일치(`학습세트 생성 중...` / `문제 생성 중`, 커버리지 §5.3) | pill 37 grey500 r10 + Lottie 20 + `body2` grey300 | ⚠️ 문구 / ❔ 상수 미조회 |

### 13. `ProjectListScreen` ↔ `1542:19495`, `1597:19052`(빈 상태), `1621:23431`·`1621:24059`(삭제 모드·시트)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Inline Title` 50: 제목 `Subtitle 1` + 트레일링 Liquid Glass **Group** 40; 삭제 모드는 `Large Title` 99 "프로젝트 삭제" + 리딩 글래스 아이콘 | `ScreenOverlayHeader(.largeTitle)` 99 "프로젝트", 리딩 없음, 편집 시 트레일링 `checkmark`/`trash` | ⚠️ 기본 50 / 99, 삭제 모드 제목·리딩 |
| 목록 | y103, V 간격 **8**, 패딩 8/20/0/20 | `VStack(spacing: 12)`, 좌우 20, 상하 16 | ⚠️ 간격 8 / 12, 상단 8 / 16 |
| 행 표면 | 320×150 V 간격 12 패딩 16/18/18/18 r12 `Grey600` | `ProjectRow` 12, 16/18/18, minHeight 150, r12, grey600 | ✅ |
| 행 헤더 | H 간격 14, 썸네일 60 r8, 텍스트 열 상단 4, 이름 Plus Jakarta Sans **Bold 18** lh128% `#ffffff`, 기술 `ENG/Body 3`(Medium 12) `Grey400`, V 간격 4 | 14, 60 r8, 상단 0, `subtitle3`(Bold 16), `caption1`(Regular 12) grey400, 2 | ⚠️ 이름 18 / 16, 기술 Medium / Regular, 간격 4 / 2, 상단 4 / 0 |
| 재생 버튼 | `Play3` 40(글리프 36) | `IconPlainButton` `ic-play-1` 36 | ✅ |
| 진행 바 | 284×6 r12 `Grey500` / `Blue200` | `ContinuousProgressBar` 6 grey500 / blue200 | ✅ |
| 세트 행 | H 간격 8: 칩 패딩 4/10 r99 `Grey500` `ENG/Body 3` `Grey300` + `Body 2` `Grey300` | 8: `TagBadge.neutral` pill 패딩 10/3/4 grey500 **`body2` blue100** + `body2` grey300 | ⚠️ 칩 글자 12·Grey300 / 14·blue100 |
| 삭제 모드 행 | 320×94(진행 블록 없음), 트레일링 Liquid Glass Icon MD 40 | `deletingMinimumHeight` 94, `IconGlassButton.destructive("minus")` 40 | ✅ 크기 / ❔ 아이콘 |
| 빈 상태 | y275 V 간격 **16** 패딩 0/20/24/20: 일러스트 128, Text Set 간격 8, "projects = []" `Subtitle 1` **`Grey200`**, `Body 2` `Grey400` | `EmptyState` 일러스트 128 + 간격 **20**, 8, `subtitle1` **grey100**, `body2` grey400 | ⚠️ 16 / 20, 제목 Grey200 / grey100 · ❔ 일러스트(정적 도형 / Lottie) |
| 삭제 시트 | 360×475 `Grey600`, 그래버 `Grey500`, 썸네일 128 r8 (그래버 아래 29), Text Set 22 아래 간격 8, 버튼 상단 30, Error Primary "삭제" + Text "취소", 간격 8, 하단 24 | `ConfirmationSheet` 128 r8 상단 22(+7 = 29), 22, 8, 버튼 상단 26, destructive + text, 8, 24 | ✅ 대부분 / ⚠️ 버튼 상단 30 / 26, 그래버 색, 그림자(§14 참조) |

### 14. `ProjectDetailScreen` ↔ `1342:19562`, `1342:19609`(메뉴), `1871:22144`(삭제 시트)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 히어로 배경 | 360×179 **RADIAL** `#56718a` 0% → `#3b3749` 100% | 179, **LINEAR** `#56718A`@0 → `#485469`@0.5 → `#3B3749`@1 | ⚠️ 방사형 / 선형, 중간 stop |
| 헤더 | `Toolbar - Top/Default` 50, 트레일링 Liquid Glass Group | `ScreenOverlayHeader(.default)` 50, `line.3.horizontal` | ✅ 높이 / ❔ 트레일링 형태 |
| 콘텐츠 시작 | y130 = 헤더 하단 103 + 27 | `summaryTopSpacing` 24 | ⚠️ 27 / 24 |
| 배너 | 99×99 r10 | 99, `.medium`(10) | ✅ |
| 배너→이름 블록 | 31 | `bannerToContentSpacing` 31 | ✅ |
| 이름 행 | H 간격 12, 텍스트 열 V 간격 5, 이름 `ENG/Headline 2`, 메타 H 간격 9 · 별 그룹 간격 5 · `Star` 16 · `ENG/Caption 1` `Blue100` · 구분선 1×16 `Grey500` · 기술 `ENG/Caption 1` `Blue100`, `Play3` 40 | 12, 5, `headline2`, 9, 5, `ic-star` 16, `caption1` blue100, 1×16 grey500, `caption1` blue100, `ic-play-3` 40 | ✅ |
| 이름 블록→진행률 | 28 | `contentSpacing` 28 | ✅ |
| 진행률 | 라벨 행 `Caption 1` `Grey400` + `Caption 1` `Blue100`, 라벨→바 10, 바 320×**10** r12 `Grey400` | `LabeledProgressBar` caption1 grey400 / blue100, 8, `ContinuousProgressBar` **6** grey500 / blue200 | ⚠️ 간격 10 / 8, 바 높이 10 / 6, 색 |
| 요약→세트 목록 | 53 | `setListTopSpacing` 54 | ⚠️ 53 / 54 |
| 세트 섹션 | 제목 `Subtitle 2` `Grey100`, 제목→목록 16, 항목 간격 **6** | `subtitle2`, 12, 12 | ⚠️ 16 / 12, 6 / 12 |
| 세트 행 | 320×130 패딩 20/18/20/18 r12 `Grey700` + `Grey500` 1, 내용 H 간격 12, 텍스트 V 간격 10, `Set 1` `ENG/Subtitle 3` `Blue100`, 제목 `Body 1`, 내용→세그먼트 25 | `LearningSetRow` 130, 패딩 18 전체, grey700 + grey500 1 r12, H 8, V 12, `subtitle3` blue100, `body1`, 외부 `VStack` 기본 간격 | ⚠️ 상하 20 / 18, H 12 / 8, V 10 / 12, 25 / 기본값 |
| 세트 재생 버튼 | `Play2` 36: 원 32 `Blue400` + 삼각 `Blue100` | 원 32 **blue300** + `play.fill` 12 **grey100** | ⚠️ 색 |
| 세그먼트 | H 간격 4, 37×10 r3, `Blue100` / `Grey500` | `ProgressSegments` 4, 높이 10, `.micro`(3), blue100 / grey500 | ✅ |
| 드롭다운 메뉴 | 160×128, x180(우측 여백 20)/y103, 패딩 4, r12, `white 5` + GLASS 20, 행 152×40 패딩 9/10/10/10 r12 `Body 2` `Grey100` | 160, 트레일링 20, offset 50, 패딩 4, r12, glass tint white5, 행 9/10/10 `body2` grey100(삭제 error) | ✅ / ❔ 삭제 행 색 |
| 삭제 시트 | 13번 시트와 동일 + DROP_SHADOW 34·6 | `ConfirmationSheet`, 그림자 없음 | ⚠️ 그림자, 버튼 상단 30 / 26, 그래버 색 |
| 빈 세트·오류 | 없음 | `EmptyState`(상하 32), `+ErrorView` | ❔ Figma 근거 없음 |

### 15. `LearningSetIntroScreen` ↔ `813:15700`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Default` 50 | `ScreenOverlayHeader(.largeTitle)` 99 | ⚠️ 50 / 99 |
| 배경 | Gradient Rect y457 `#141414` → `#a5c4f0` | 배경 그라데이션 없음(`screenBackground`) | ⚠️ 그라데이션 미구현 |
| Text Set | x20/y322, V 간격 16 left; 내부 간격 8: `Set 1` Plus Jakarta Sans **Bold 16** lh150% `Blue100`, 제목 `Subtitle 1`; 설명 `Body 2` `Grey400` | 간격 8, `subtitle2`(**Bold 18**) blue100, `subtitle1`, `body2` grey400 상단 **10** | ⚠️ 세트 라벨 16 / 18, 설명 간격 16 / 10 · ❔ y322 |
| 버튼 | Primary "시작하기", Toolbar-Bottom 하단 24 | `ActionButton.primary` + `ScreenOverlayFooter`(하단 24) | ✅ |

### 16. `QuestionSolvingScreen` ↔ `1342:18657`(객관식), `855:15476`(객관식 정답), `1374:17084`(서술형), `855:15415`(서술형 결과), `1342:18699`(출처 시트); `1342:18711`·`1374:17109`(선택됨 변형) 미조회

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Default` 50 | `ScreenOverlayHeader(.default)` 50 | ✅ |
| 문제 헤더 | Container 패딩 20/20/32/20, V 간격 10: Tag Accent 58×28 패딩 3/10/4/10 r8 `Blue400` `Body 2` `Blue100`, 문제 `Subtitle 3` `#ffffff` | 상하 16, 간격 8, `TagBadge.accent`(10/3/4, r8, blue400, body2 blue100), `subtitle2`(Bold 18) | ✅ 태그 / ⚠️ 상단 20 / 16, 간격 10 / 8, 문제 16 / 18, 헤더→선택지 32 / 24 |
| 선택지 목록 | V 간격 **10**(풀이) · **8**(정답) | `VStack(spacing: 8)` | ⚠️ 풀이 10 / 8 · ✅ 정답 |
| 선택지 카드 | 320×111 V 간격 4 패딩 14/18/18/18 r12 `Grey600`, 글자 `ENG/Subtitle 2` `Blue200`, 본문 `Subtitle 3` `Grey100`, 셰브론 16(풀이 시 op 0) | `ChoiceAnswerOption` 4, 14/18/18, r12, grey600, `subtitle2` blue200, `subtitle3` grey100, 셰브론 **10**(36 박스) | ✅ / ⚠️ 셰브론 16 / 10 |
| 정답 상태 | Correct fill `#3e85ff` + 글자 `Grey100`, 나머지 접힘 59 `Grey600` | `.correct` `#3E85FF` grey100, 접힘 토글 | ✅ / ❔ 오답 선택 변형 미조회(`incorrect` `#FF5656`) |
| 선택됨 상태 | `1374:17109` 미조회 | `.selected` = focus 테두리 blue100 1 | ❔ |
| 출처 버튼 | 68×36 H 간격 2 패딩 4/8/4/16 r**8** `Grey600`, `Body 2` `Blue100` + 셰브론 16 | 간격 2, 좌 16·우 8·상하 **8**, r**12**, grey600, `body1` blue100 + 셰브론 10 | ⚠️ 상하 4 / 8, r8 / 12, 글자 14 / 16, 셰브론 |
| 선택지→출처 / 선택지→AI 해설 | 16 / 28 | `sectionSpacing` 24 / 24 | ⚠️ |
| AI 해설 카드 | 320×151 V 간격 8 패딩 18/20/20/20 r12 `Blue500`, 라벨 `Blue100`(mixed), 본문 `Grey100`(mixed) | `LabeledCard.accent` 8, 패딩 16, r12, blue500, `caption1` blue100, `body2` grey100 | ✅ 색·간격 / ⚠️ 패딩 18·20 / 16 · ❔ 서체(mixed) |
| 하단 바 | Horizen 패딩 4/20/24/20 간격 **8**: 북마크 Secondary **40×54** `Grey500` r12 아이콘 16, Primary 272 "확인"/"다음" | `HStack(spacing: 12)`: `BookmarkButton` **54×54** grey600 r12 SF `bookmark`, primary "제출하기" | ⚠️ 간격 8 / 12, 북마크 40·Grey500·16 / 54·grey600·SF, 문구 |
| 서술형 입력 카드 | 320×262 r**12** `Grey500`, 안내 `Body 2` `Grey400`(22,14), 글자수 `ENG/Body 2` 카드 안 우하단, 테두리 없음, 문제→카드 29 | `AnswerEditor` min 160/max 240, r**8**, grey600, `body1` grey400 inset 16, `caption2` 카드 밖, 테두리 grey500/blue100 1, 24 | ⚠️ 반경·배경·안내 서체·글자수 위치·테두리·간격 |
| 서술형 하단 버튼 | "정답 확인" | "제출하기" | ⚠️ 문구 |
| 서술형 결과 | Container V 간격 **8**: "나의 답안" 320×106 V 12 패딩 14/22 r12 `Grey500` DROP_SHADOW 15, 제목 **Pretendard SemiBold 14** `Grey200`, 본문 `Body 2` `#919191`; "AI의 답안" `Blue500` 같은 구조 | `EssayResultSection` 간격 **20**, `LabeledCard` 8·패딩 16, 라벨 `caption1` blue100, neutral grey600 + grey300, accent blue500 + grey100, "AI 해설" | ⚠️ 간격·패딩·라벨 서체·배경·본문 색·그림자·문구("AI의 답안") — Figma 라벨이 비DS 폰트(Pretendard) |
| 출처 시트 | 360×328 상단 r16 `Grey600`, 그래버 5/4/7, 제목 상단 12, 제목→설명 **8**, 설명 `Body 2` `Grey100`, 설명→링크 **27**, 링크 = Secondary LG 320×54 `Grey500` r12 `Body 1` `white 70` + `Link` 16, 링크→버튼 24, Primary "닫기", 하단 24 | `SheetSurface` r16 grey600 5/4/7, 12, 목록 상하 **20**, `body2`, **8**, 칩 grey500 r12 12/15 `body1` white70 + `ic-link` 16, 20 + 4, primary, 24 | ✅ 칩·버튼 / ⚠️ 제목→설명 8 / 20, 설명→링크 27 / 8 |

### 17. `LearningCompletionScreen` ↔ `1374:17250`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 제목 | 제목 프레임 y103 패딩 100/10/20/10, "학습 완료" `Subtitle 1` `#ffffff` center(화면 상단 고정) | "학습을 마쳤어요" `subtitle1` center, 애니메이션 **아래** | ⚠️ 문구·위치 |
| 완료 그래픽 | 200×200, y247 | Lottie `complete` **180** | ⚠️ 200 / 180 |
| 점수 | 프레임 하단 패딩 12, H 간격 5: `7` `ENG/Subtitle 1` `Blue200` · 구분 벡터 8×22 `Grey400` 1 · `7` `ENG/Subtitle 1` `Grey400` | `headline2`(Bold 28) grey100 "N / M" 한 텍스트 | ⚠️ 22·색 분리 / 28·단색 |
| 메시지 | `Body 1` `Grey400` center, 점수 아래 12 | `body2` grey400, 간격 16 | ⚠️ 16 / 14, 12 / 16 |
| 버튼 | LG **Secondary** "다음", 하단 24 | `ActionButton.primary` "확인", 하단 34 | ⚠️ 스타일·문구·하단 |
| 헤더 | 미조회(제목 프레임이 y103부터) | `ScreenHeader(.largeTitle, .close)` 99 | ❔ |

### 18. `SavedScreen` ↔ `1597:21241`, `1597:21683`(빈 상태)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Large Title` 99 "저장한 문제", 리딩 글래스 아이콘 | `ScreenOverlayHeader(.largeTitle)`(리딩 back) / 탭 진입 `ScreenHeader(title:)` | ✅ |
| 필터 칩 | y152 패딩 10/20, 칩 36 패딩 7/8/8/8 r8, 선택 `Blue100` + `Body 2` `Grey700`, 미선택 `Grey600` + `Grey100`, 간격 8 | 없음 | ⚠️ 미구현 |
| 개수 문구 | y208 패딩 10/20 "4개" `Body 2` `Grey400` | 없음 | ⚠️ 미구현 |
| 목록 | y249 V 간격 **8** 패딩 0/20 | `VStack(spacing: 12)`, 상하 16 | ⚠️ 8 / 12, 상단 0 / 16 |
| 카드 표면 | 320×185 r12 `Grey600`, 상단 14·좌우 18·하단 16 | `QuestionRow` 패딩 16 전체, r12, grey600 | ⚠️ 14/18/16 / 16 |
| 메타 행 | "Now in Android · Set 2" `Body 2` `Grey300` | 없음 | ⚠️ 미구현 |
| 문제 | `Subtitle 3` `Grey100`, 메타 아래 10 | `subtitle3` grey100 | ✅ 스타일 |
| 액션 행 | 문제 아래 16, 북마크 24(selected) + SM Primary 84×**36** 패딩 7/16/8/16 r8 `Blue100` | 간격 16, 북마크 없음, 버튼 높이 **44** maxWidth 120 r8 blue100 `body2` grey700 | ⚠️ 북마크 없음, 36 / 44 |
| 빈 상태 | y275 V 간격 **16** 패딩 0/20/24/20: 일러스트 128(Union ×2), "Nothing saved yet." `Subtitle 1` **`Grey200`** center, 메시지 `Body 2` `Grey400` center; 상단에 칩 1개 | `EmptyState` 20, Lottie `storage-empty` 128, `subtitle1` **grey100**, `body2` grey400, 칩 없음 | ⚠️ 16 / 20, 제목 Grey200 / grey100, 칩 · ❔ 일러스트 형태 |

### 19. `ProfileScreen` ↔ `1539:19209`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Toolbar - Top/Inline Title` **50**(컨트롤 40 + 10), "마이" `Subtitle 1`, 트레일링 Liquid Glass Group 40 | `ScreenHeader(.inlineTitle)` **43**, `gearshape` `IconGlassButton` | ⚠️ 50 / 43 · ❔ 트레일링 형태 |
| 프로필 카드 | H 간격 15, 패딩 20, 아바타 78 원형 | 15, 20, 78 원형 | ✅ |
| 정보 열 | V 간격 8, 이름 `Subtitle 2` `#ffffff`, 이메일 `ENG/Caption 1` `Grey400` | 8, `subtitle2` grey100, `caption1` grey400 | ✅ |
| 태그 | H 간격 6, 패딩 3/10/4/10 r8, Accent `Blue400`+`Blue100`, Normal `Grey500`+`Blue100`, 글자 `Body 3`(12) | 6, `TagBadge` 10/3/4 r8, 같은 색, **`body2`(14)** | ⚠️ 글자 12 / 14 |
| 섹션 제목 | 패딩 20/20/10/20 `Caption 2` `Grey400` | 상단 20·하단 10 `caption2` grey400 | ✅ |
| 통계 카드 | 320×88 r12, LINEAR `Blue500` 0% → `#2f3853`@50% 100%, 열 V 간격 4: `Caption 2` `Grey300` + `Subtitle 2` `Blue100` center | 88, r12, blue500 → blue500@50% leading→trailing(로컬 그라데이션), 4, `caption2` grey300 + `subtitle2` blue100 | ✅ 값 / ❔ 방향 · 토큰 부재(`gradient4` 없음) |
| 카드 간격 | 16 | `cardSpacing` 16 | ✅ |
| 주간 차트 카드 | 320×223 V 간격 26 패딩 14/16/14/16 r12 `Grey600`, 헤더 V 간격 1: 제목 **`Body 3`** `Grey400` + `Subtitle 3` `Grey100`, 차트 126 (막대→라벨 7) | 223, 26, 14/16, r12, grey600, 1, **`caption2`**(10) grey400 + `subtitle3`, 126, 7 | ⚠️ 제목 Body 3(12) / caption2(10) |
| 막대 | 미조회 | `gradient3`/`gradient1`, 상단 r4, 간격 12 | ❔ |

### 20. `SettingsScreen` ↔ `1465:19689`, `1535:18281`(분야), `1535:18378`(경력), `1636:31714`(계정 삭제)

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 헤더 | `Large Title` 99, 리딩 글래스 아이콘 | `ScreenOverlayHeader(.largeTitle, .back)` | ✅ |
| 섹션 제목 | 패딩 20/20/10/20 `Caption 2` `Grey400` | `SectionView` 20 / 10 `caption2` grey400 | ✅ |
| 옵션 컨테이너 | 좌우 20, `Grey600`, r12, 행 간격 0 | 좌우 20, grey600, r12, 0 | ✅ |
| 설정 행 | 320×**56**, 패딩 0/20, 좌측 아이콘 24 + 간격 10 + `Body 2` `#ffffff`, 우측 `Body 2` `Grey400` + 간격 6 + `ChevronRight1` 16, 하단 stroke `Grey500` | `SettingRow` minHeight **52**, 좌우 **18**, 아이콘 없음, `body1`(16), `body2` grey400, 간격 8, SF `chevron.right` 크기 미지정, 구분선 1 grey500 | ⚠️ 56 / 52, 20 / 18, 아이콘 없음, 제목 14 / 16, 셰브론 |
| 분야 선택 | 목록 y164(헤더 아래 12), compact 52 카드 `Grey600`, on `Blue200` 1 | `contentTopPadding` 8, `SelectionCardList(.compact)` grey700, focus blue100 | ⚠️ 12 / 8, 카드 색·테두리(5번과 동일) |
| 경력 선택 | 목록 y164, detailed 80 카드 | 8, `.detailed` | ⚠️ 12 / 8, 카드 색·테두리 |
| 계정 삭제 | 본문 y152 패딩 10/20 `Body 1` `Grey100`; 하단 LG Primary Text "계정 삭제" 라벨 `State/Error`, y688 | 본문 `body1` grey100 상단 8, `ActionButton.text` body1 error center, 푸터 하단 24 | ✅ 버튼 / ⚠️ 본문 상단 10 / 8 |
| 계정 행 색 | 미조회 | 로그아웃 = error, 계정 삭제 = grey100 | ❔ |

### 21. `MainShellRouter` / `TabShell` ↔ `1303:15398`

| 항목 | Figma (`A`) | 코드 | 판정 |
| --- | --- | --- | --- |
| 바 표면 | 360×92 패딩 4/20/24/20, 필 298×64 패딩 6/8 r999 `#7e94bb`@10% + `#7e94bb`@24% 1 INSIDE, GLASS 4 | 시스템 `TabView`(커스텀 바 없음; `blue300Alpha10/24` 토큰은 미사용) | 승인 후보: 시스템 소유 표면(스킬 4단계) — ❔ 명시 승인 기록 없음 |
| 탭 항목 | 70×50 패딩 4/15/3/14 r99, 선택 fill `#919191`@30% | 시스템 | ❔ |
| 아이콘·라벨 | 아이콘 24 + 간격 4 + Noto Sans Regular 10 lh150% `Blue100`; 선택·기본 모두 아이콘·라벨 `Blue100` | `ic-home`/`ic-file-text`/`ic-bookmark`/`ic-user`, `.padding(.bottom, 4)`, `tabItem` regular 10/150%, tint blue100(선택), 미선택 = 시스템 기본색(`TabShellItem.tabColor` 미사용) | ✅ 서체·간격 / ⚠️ 미선택 색 Blue100 / 시스템 기본 |
| 라벨 문구 | 홈 · 프로젝트 · 저장 · 마이 | **Home** · 프로젝트 · 저장 · 마이 | ⚠️ "홈" / "Home" |

## 교차 발견 (여러 화면에 반복되는 항목)

- **선택 카드(`SelectionCard`)**: 배경 `Grey600` / grey700, 선택 테두리 `Blue200` 1 OUTSIDE / blue100 1(+white5 채움), 미선택 테두리 없음 / grey500 1 — 5·6·9·20번 공통.
- **시트 그래버**: Figma 전부 `Grey500`, 코드 `SheetSurface` grey400(`SemanticColorToken.grabber` = grey500 미사용) — 4·11·13·14·16번.
- **시트 그림자**: Figma DROP_SHADOW 34·6, 코드 미적용(`EffectToken.sheetElevation` 존재) — 11·13·14번.
- **하단 버튼 여백**: 등록 플로우 5개 화면과 완료 화면이 `bottomButtonPadding 34`, Figma Toolbar-Bottom은 24 — 7·8·9·10·17번(`BottomActionBar`를 쓰는 화면은 24로 일치).
- **헤더 유형**: 링크 입력·이해도 선택·세트 소개는 Figma `Default` 50인데 코드 `.largeTitle` 99(제목 없음) — 7·9·15번. 프로젝트 목록·마이는 Figma `Inline Title`(50)인데 코드 99 / 43 — 13·19번.
- **셰브론 크기**: Figma 인라인 셰브론 16, 코드 10~12 — 7·12·16·20번.
- **글자 크기 한 단계 차이**: 약관 행 14 / 16, 프로젝트 행 이름 18 / 16, 세트 소개 라벨 16 / 18, 태그 12 / 14, 설정 행 14 / 16, 문제 16 / 18, 출처 버튼 14 / 16, 완료 메시지 16 / 14.
- **문구·상태 차이**(커버리지 체크리스트 §5.3 재확인): 홈 생성 중 라벨, 문제 풀이 CTA(`확인`/`정답 확인` vs `제출하기`), 완료 화면 제목·버튼, 서술형 결과 라벨(`AI의 답안` vs `AI 해설`), 탭 라벨 `홈`/`Home`.

## 조회 메모

- `use_figma` 응답이 `Failed to parse SSE message … EOF while parsing a string`으로 끝난 원인 두 가지를 확인했다. (1) 응답이 약 20KB를 넘는 경우 — 노드 수 상한과 `children.slice`로 해결. (2) 반환 문자열에 줄바꿈이 포함된 경우 — 텍스트 노드의 `name`·`characters`에 개행이 있으면 크기와 무관하게 실패하므로 모든 문자열을 `replace(/\s+/g, ' ')`로 정리해야 한다(`1597:21683` 저장 빈 상태에서 재현).
- 미조회로 남긴 노드: `1342:18711`·`1374:17109`(객관식·서술형 선택됨 변형), 홈 생성 중 카드 `1859:21645` 상수, 마이 주간 차트 막대, 설정 계정 행 색, 완료 화면 툴바 유형.

## 교정 반영 (2026-09-04)

점검 결과 중 Figma 값이 명확하고 코드가 그 값을 벗어난 항목을 `sources/Projects/UI/**`와
`sources/Projects/Feature/**` 범위에서 교정했다. 48개 Swift 파일을 수정한 뒤 프로젝트 포맷 진입점
(`tools/githooks/swift-format/bin/run.sh format`)으로 정리했고 린트 위반은 0건이다.

### 공통 컴포넌트

| 대상 | 교정 |
| --- | --- |
| `SelectionCard` | 배경 `screenBackground`(grey700) → `cardBackground`(grey600), 선택 테두리 `focus`(blue100) → `highlight`(blue200), 미선택 테두리 제거, Figma에 없는 `selectedSurface` 채움 제거 |
| `SheetSurface` | 그래버 색 grey400 → `SemanticColorToken.grabber`(grey500), 시트 표면에 `EffectToken.sheetElevation` 적용 |
| `ScreenHeader.Style.inlineTitle` | 높이 43 → 50 (컨트롤 행 40 + 하단 패딩 10과 일치) |
| `ActionButton` | Figma `Style=Primary Text`에 대응하는 `.primaryText` 추가(배경 없음 + `blue100` 라벨) |
| `TagBadge` | `.muted` 스타일(grey500 배경 + grey300 라벨)과 `Size.compact`(`body3`) 추가 |
| `ContinuousProgressBar` | 표면 높이를 `Height.row`(6) / `Height.detail`(10)로 분리 |
| `LabeledProgressBar` | 라벨-바 간격 8 → 10, 바 높이 `.detail` |
| `EmptyState` | 일러스트-텍스트 간격 20 → 16, 제목 색 grey100 → grey200 |
| `ProjectRow` | 이름 `subtitle3` → `subtitle2`, 보조 텍스트 `caption1` → `body3`, 제목 간격 2 → 4, 텍스트 열 상단 4, 세트 칩 `neutral` → `muted` |
| `LearningSetRow` | 상하 패딩 18 → 20, 내용 간격 8 → 12, 텍스트 간격 12 → 10, 내용-세그먼트 간격 25, 재생 원 blue300 → blue400, 글리프 grey100 → blue100 |
| `SettingRow` | 최소 높이 52 → 56, 좌우 패딩 18 → 20, 제목 `body1` → `body2` |
| `PolicyAgreementRow` | 제목 `body1` → `body2`, 링크 컨트롤 표면 36(터치 44 유지) |
| `BookmarkButton` | 54×54 grey600 → 40×54 `raisedBackground`(grey500), 글리프 16 |
| `AppleSignInButton` | 글리프 16 → 19 semibold, 아이콘-라벨 간격 6 → 5 |
| `SplashView` | 두 줄 간격 4 → 3 |
| `ChoiceAnswerOption` | 셰브론 글리프 10 → 16 |

### 화면

| 화면 | 교정 |
| --- | --- |
| 제목 없는 헤더 6곳 | `.largeTitle`(99) → `.default`(50): 링크 입력·레포 확인·이해도 선택·생성 확정·생성 실패·세트 소개·세트 소개 오류·학습 완료 |
| 하단 버튼 여백 11곳 | 34(진행 화면 58) → Figma Toolbar-Bottom의 24 |
| 약관 동의 | 제목 하단 12 → 10, 전체 동의 행과 문서 목록 사이 7, 문서 행 좌측 19 → 17 |
| 링크 입력 | 헤더-콘텐츠 32 → 18, 안내 카드 헤더 54 → 56·우측 패딩 10·셰브론 16(36 박스), 본문 하단 20 → 10 |
| 레포 확인 | 제목-썸네일 56 → 45, 썸네일-텍스트 12 → 21 |
| 이해도 선택 | 제목 상단 24 → 20, 제목-목록 32 → 46 |
| 생성 진행 | 체크리스트 상단 시스템 기본 → 53, 행 간격 12 → 14, "홈에서 기다리기" `.text` → `.primaryText` |
| 리마인드 시트 | 콘텐츠 간격 24 → 31, 상단 16 → 21, "다시 보지 않기" `.medium`(40) → `.small`(36) |
| 세트 소개 | 세트 라벨 `subtitle2` → `subtitle3`, 설명 상단 10 → 8 |
| 문제 풀이 | 문제 `subtitle2` → `subtitle3`, 태그-문제 간격 8 → 10, 콘텐츠 상하 16 → 20, 출처 버튼 `body2`·반경 12 → 8·상하 8 → 4·셰브론 16, 하단 바 간격 12 → 8 |
| 학습 완료 | 완료 그래픽 180 → 200, 점수 `headline2` 단색 → `subtitle1` blue200 + grey400 구분선 표현, 메시지 `body2` → `body1` |
| 프로젝트 목록·저장 | 목록 간격 12 → 8 |
| 프로젝트 상세 | 요약 상단 24 → 27, 세트 목록 상단 54 → 53, 섹션 제목-목록 12 → 16, 카드 간격 12 → 6 |
| 마이 | 태그 `body2` → `body3`(compact), 주간 차트 섹션 라벨 `caption2` → `body3` |
| 저장한 문제 | 아래 별도 절 참고 |

### 교정하지 않고 남긴 항목

결정이 필요하거나 명세·시스템 소유 영역이라 임의로 흡수하지 않았다.

- **문구 차이**: 홈 생성 중 라벨, 문제 풀이 CTA(`확인`/`정답 확인` vs `제출하기`), 학습 완료 제목·버튼
  (Figma는 Secondary "다음"), 서술형 결과 라벨(`AI의 답안` vs `AI 해설`), 탭 라벨 `홈`/`Home`. 명세가
  우선하므로 제품 결정을 받아야 한다.
- **레포 확인 소유자 텍스트**: Figma는 Plus Jakarta Sans Regular 14 · `Grey100` 50%. 대응하는 굵기·불투명도
  토큰(`white50`)이 없어 `body2` + `white70`을 유지했다. 토큰 추가 여부 결정이 필요하다.
- **프로젝트 상세 히어로 배경**: Figma는 RADIAL, `GradientToken`은 선형만 지원한다. 방사형 지원을
  DesignSystem에 추가할지 결정이 필요하다.
- **탭 바**: Figma의 커스텀 필(298×64, `#7e94bb` 10%/24%, GLASS 4)은 시스템 `TabView`가 소유하는 표면이라
  재현하지 않았다. 미선택 탭 색만 `TabShellItem.tabColor`로 연결할 수 있으나 시스템 기본색 사용 여부를
  확인해야 한다.
- **서술형 입력·결과 카드**: Figma가 비디자인시스템 폰트(Pretendard)와 다른 배경(`Grey500`)을 쓰고 있어
  디자인 확정이 필요하다.
- **미조회 노드**: `1342:18711`·`1374:17109` 선택됨 변형, 홈 생성 중 카드, 마이 주간 차트 막대,
  설정 계정 행 색, 프로젝트 상세 진행 바 트랙 색(`Grey400` 표기).

### 저장한 문제 화면 (`1597:21241`)

점검 시점에는 필터 칩·개수·메타 행이 없다고 기록했으나, 확인 결과 `SavedScreen.FilterSection`과
`SavedQuestionCard`로 이미 구현돼 있었다(`SavedScreen+FilterSection.swift`와 `BookmarkedProject.swift`는
아직 커밋되지 않은 작업 트리 파일이다). 18번 항목의 "미구현" 판정을 철회하고 상수 차이만 교정했다.

| 항목 | Figma (`A`) | 교정 전 | 교정 |
| --- | --- | --- | --- |
| 필터 칩 좌우 패딩 | 8 | 14 | 8 |
| 미선택 칩 배경 | `Grey/Grey600` | `raisedBackground`(grey500) | `cardBackground`(grey600) |
| 미선택 칩 라벨 | `Grey/Grey100` | `blue100` | `grey100` |
| 칩 행 여백 | 상하 10, 좌우 20 | 섹션 간격 12 | 상하 10, 스크롤 콘텐츠에 좌우 20 |
| 칩 스크롤 폭 | 화면 폭 전체(칩이 우측 끝까지 이어짐) | 좌우 20 여백 안에서만 스크롤 | 전체 폭 + 콘텐츠 여백 20 |
| 개수 문구 | `Body 2` `Grey400`, 상하 10 | `caption2`(10) | `body2`, 상하 10 |
| 카드 메타 행 | `Body 2` `Grey300` | `caption1`(12) | `body2` |
| 카드 북마크 아이콘 | 24, 카드 좌측 패딩(18)에 정렬 | 크기 지정 없음 + 좌우 10 추가 여백 | 24 고정, 추가 여백 제거 |
| 카드 액션 행 | 아이콘-버튼 간격 6, 상하 16 | 기본 간격 | 간격 6, 상하 16 |
| 카드 세로 구성 | 14 / 메타 / 10 / 문제 / 16 / 액션 36 / 16 = 185 | `VStack` 기본 간격이 누적 | `spacing: 0`으로 Figma 합계와 일치 |

### 검증

- 실행함: 프로젝트 포맷 진입점 `format`(린트 위반 0), `project-build compile`(7개 scheme 전부 성공).
- 실행하지 않음: Simulator 렌더와 Figma 렌더의 상태별 육안 비교.
- 테스트: `UI`·`Composition`·`Infrastructure`·`Data`·`Domain` 5개 scheme 통과, `AppTests`·`Feature`
  2개 실패. 시뮬레이터를 정리하고 재실행해도 같은 결과가 재현되므로 시뮬레이터 상태 문제가 아니다.
  - `AppTests` 4 통과 / 44 실패. 전부 `makeAppRootStore(...)` 지점의 `Test crashed with signal trap.`이다.
  - `Feature` 95 통과 / 159 실패. 대부분 각 Suite의 `makeStore(...)`(TCA `TestStore` 생성) 크래시이고,
    `HomeFeatureLoadTests` 2건만 상태 단언 실패다(`_generationOutcomeObservation` 기대 `.idle` / 실제
    `.observing`).
  - 이번 교정은 화면·컴포넌트의 레이아웃·색·서체 상수만 바꿨고 reducer·의존성·Composition은 건드리지
    않았다. 실패한 `HomeFeature`와 그 테스트 파일은 이번 변경에 포함되지 않은 HEAD 상태다. 다만 작업
    트리에는 이번 교정과 무관한 미커밋 변경(북마크 Domain 모델, `BookmarkRepositoryAdapter`,
    `ProjectListFeature`, 테스트 픽스처 등)이 함께 있어, 두 scheme 실패를 HEAD 기준 기존 실패로
    확정하려면 해당 변경을 제외한 baseline 실행이 필요하다.
