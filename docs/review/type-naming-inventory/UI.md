# UI 패키지 타입 목록

[인덱스로 돌아가기](README.md) · [단어 사전](glossary.md)

타입 139개, 관심사 폴더 24개. 항목은 파일 경로와 선언 줄 순서다. 각 항목은 `이름` 종류 · 접근 수준 · 파일 링크, 한 줄 설명, 그리고 이름을 이루는 단어와 정의로 구성된다.

| 종류 | 개수 |
|---|---|
| enum | 68 |
| protocol | 1 |
| struct | 67 |
| typealias | 3 |

## Component/CollectionItems

- **`ChoiceResultRow`** `struct` · public · [ChoiceResultRow.swift:6](../../../sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift#L6) · 채택: View  
  퀴즈 선택지 하나의 정답·오답 판정 결과를 보여주는 행 컴포넌트. judgement(정답/오답)에 따라 배경색을 바꾸고, isExpanded면 해설(explanation)을 펼쳐 보여주며 탭 시 onTap을 호출한다.  
  단어: `Choice` 선택·선택지. 여기서는 객관식 문제의 보기 하나 · `Result` 결과. 여기서는 그 선택지에 대한 정답·오답 판정 결과 · `Row` 행·줄. 여기서는 목록에 세로로 쌓이는 한 줄짜리 UI 컴포넌트
- **`ChoiceResultRow.Judgement`** `enum` · public · [ChoiceResultRow.swift:26](../../../sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift#L26) · 채택: Sendable, Equatable  
  ChoiceResultRow에 전달되는 정답 여부 판정 값으로 correct·incorrect 두 케이스를 가진다. 케이스별 배경 ColorToken(backgroundColor)과 접근성 레이블 접미사("정답"/"오답")를 제공한다.  
  단어(단일): `Judgement` 판정·판단. 여기서는 선택지가 정답인지 오답인지에 대한 판정
- **`ChoiceResultRow.Constant`** `enum` · private · [ChoiceResultRow.swift:85](../../../sources/Projects/UI/Component/CollectionItems/ChoiceResultRow.swift#L85)  
  ChoiceResultRow 레이아웃 상수를 모아 둔 네임스페이스 열거형. 접힘 높이(59), 펼침 높이(111), 가로 패딩(16)을 static let으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 ChoiceResultRow의 고정 레이아웃 수치 모음
- **`LearningSetRow`** `struct` · public · [LearningSetRow.swift:6](../../../sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift#L6) · 채택: View  
  학습 세트 하나를 보여주는 높이 130의 행 컴포넌트. 세트 라벨·제목, ProgressSegments로 문제 수 대비 완료 수를 표시하고 재생 아이콘의 학습 시작 버튼(onStart)을 제공하며 completedCount를 0~total로 클램프한다.  
  단어: `Learning` 학습. 여기서는 사용자가 퀴즈를 푸는 학습 활동 · `Set` 집합·묶음. 여기서는 프로젝트 하나에서 생성된 퀴즈 묶음(학습 세트) · `Row` 행·줄. 여기서는 목록에 세로로 쌓이는 한 줄짜리 UI 컴포넌트
- **`LearningSetRow.Constant`** `enum` · private · [LearningSetRow.swift:79](../../../sources/Projects/UI/Component/CollectionItems/LearningSetRow.swift#L79)  
  LearningSetRow의 레이아웃 상수 네임스페이스. 행 높이(130), 가로·세로 패딩, 콘텐츠·제목 간격, 시작 버튼 심볼·표면·터치 크기를 static let으로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 LearningSetRow의 고정 레이아웃 수치 모음
- **`SettingRow`** `struct` · public · [SettingRow.swift:6](../../../sources/Projects/UI/Component/CollectionItems/SettingRow.swift#L6) · 채택: View  
  설정 화면의 한 행을 그리는 제네릭(Content: View) 컴포넌트. 왼쪽에 임의 content를, 오른쪽에 선택적 value 텍스트와 settingChevron 아이콘을 두고 전체를 Button으로 감싸 탭 시 onTap을 호출한다.  
  단어: `Setting` 설정. 여기서는 앱 설정 화면의 항목 · `Row` 행·줄. 여기서는 설정 목록에 세로로 쌓이는 한 줄짜리 UI 컴포넌트
- **`SettingRow.Constant`** `enum` · private · [SettingRow.swift:45](../../../sources/Projects/UI/Component/CollectionItems/SettingRow.swift#L45)  
  SettingRow의 레이아웃 상수 네임스페이스. 셰브런 아이콘 크기(16), 가로 패딩(20), 세로 패딩(8), 최소 높이(40)를 static 계산 프로퍼티로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 SettingRow의 고정 레이아웃 수치 모음

## Component/CollectionItems/HomeProjectCard

- **`HomeProjectCard`** `struct` · public · [HomeProjectCard.swift:6](../../../sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  홈 화면에서 프로젝트 하나를 154x192 크기 카드로 보여주는 컴포넌트. 제목·기술 스택·진행률 바·현재 세트 배지·세트 제목을 표시하고, 카드 탭(onSelect)과 학습 시작 재생 버튼(onStart)을 제공하며 Variant로 색 조합을 정한다.  
  단어: `Home` 홈·시작 화면. 여기서는 앱 홈 탭 화면 · `Project` 프로젝트. 여기서는 사용자가 등록한 GitHub 학습 프로젝트 · `Card` 카드. 여기서는 모서리가 둥근 고정 크기 카드형 UI 컴포넌트
- **`HomeProjectCard.Constant`** `enum` · fileprivate · [HomeProjectCard.swift:181](../../../sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift#L181)  
  HomeProjectCard의 레이아웃 상수 네임스페이스로 extension 안에 선언된다. 카드 높이, 헤더·푸터 패딩, 진행률 바 높이, 세트 배지 크기, 시작 버튼의 시각·터치 크기와 파생 패딩, 제목 TextStyleToken을 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 HomeProjectCard의 고정 레이아웃 수치와 제목 텍스트 스타일 모음
- **`HomeProjectCard.Variant`** `enum` · public · [HomeProjectCard.swift:220](../../../sources/Projects/UI/Component/CollectionItems/HomeProjectCard/HomeProjectCard.swift#L220) · 채택: Sendable, Equatable  
  HomeProjectCard의 색 조합 변형으로 purple·lightBlue·darkBlue 세 케이스를 가지며 init(index:)로 index % 3에 따라 순환 선택된다. 케이스별 카드·제목·기술·트랙·진행률·세트 제목 ColorToken을 제공한다.  
  단어(단일): `Variant` 변형·변종. 여기서는 같은 카드 레이아웃의 색상 테마 변형

## Component/CollectionItems/ProjectRow

- **`ProjectRow`** `struct` · public · [ProjectRow.swift:6](../../../sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift#L6) · 채택: View  
  프로젝트 목록의 한 행을 그리는 제네릭(Thumbnail: View) 컴포넌트. 썸네일·이름·보조 텍스트와 ContinuousProgressBar, 현재 세트 TagBadge·세트 제목을 표시하고, isDeleting이면 진행률 영역을 숨기고 삭제 IconGlassButton을, 아니면 학습 시작 IconPlainButton을 액세서리로 보여준다.  
  단어: `Project` 프로젝트. 여기서는 사용자가 등록한 GitHub 학습 프로젝트 · `Row` 행·줄. 여기서는 프로젝트 목록에 세로로 쌓이는 한 줄짜리 UI 컴포넌트
- **`ProjectRow.Constant`** `enum` · private · [ProjectRow.swift:73](../../../sources/Projects/UI/Component/CollectionItems/ProjectRow/ProjectRow.swift#L73)  
  ProjectRow의 레이아웃 상수 네임스페이스. 썸네일 크기·간격, 제목 간격, 텍스트 열 상단 패딩, 상하좌우 패딩, 기본 최소 높이(150)와 삭제 모드 최소 높이(94)를 static 계산 프로퍼티로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 ProjectRow의 고정 레이아웃 수치 모음

## Component/CollectionItems/SavedQuestionCard

- **`SavedQuestionCard`** `struct` · public · [SavedQuestionCard.swift:6](../../../sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  저장(북마크)한 문제 하나를 카드로 보여주는 컴포넌트. 메타데이터·문제 지문을 표시하고, isBookmarked에 따라 아이콘·색·접근성 레이블이 바뀌는 북마크 토글 버튼(onBookmarkTap)과 actionTitle을 가진 액션 버튼(onActionTap)을 제공한다.  
  단어: `Saved` 저장된. 여기서는 사용자가 북마크해 보관한 상태 · `Question` 문제·질문. 여기서는 퀴즈의 개별 문제 · `Card` 카드. 여기서는 모서리가 둥근 카드형 UI 컴포넌트
- **`SavedQuestionCard.Constant`** `enum` · fileprivate · [SavedQuestionCard.swift:96](../../../sources/Projects/UI/Component/CollectionItems/SavedQuestionCard/SavedQuestionCard.swift#L96)  
  SavedQuestionCard의 레이아웃 상수 네임스페이스로 extension 안에 선언된다. 콘텐츠 패딩, 지문 상단 패딩, 액션 행 간격·세로 패딩, 북마크 아이콘 크기, 액션 버튼 높이·최대 너비를 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 SavedQuestionCard의 고정 레이아웃 수치 모음

## Component/CollectionItems/SelectionCard

- **`SelectionCard`** `struct` · public · [SelectionCard.swift:6](../../../sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  선택 가능한 항목을 카드로 보여주는 제네릭(Thumbnail: View) 컴포넌트. 제목·보조 텍스트·TagBadge를 표시하고 isSelected면 highlight 테두리와 isSelected 접근성 트레이트를 더하며, SelectionCardStyle로 썸네일 노출과 최소 높이를 정한다. Thumbnail == EmptyView 전용 init은 compact 스타일을 사용한다.  
  단어: `Selection` 선택. 여기서는 온보딩 등에서 사용자가 항목을 고르는 행위 · `Card` 카드. 여기서는 모서리가 둥근 카드형 UI 컴포넌트
- **`SelectionCard.Constant`** `enum` · private · [SelectionCard.swift:68](../../../sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCard.swift#L68)  
  SelectionCard의 레이아웃 상수 네임스페이스. 썸네일 크기·간격, 제목 간격, 배지 간격, 콘텐츠 패딩, 테두리 두께를 static 계산 프로퍼티로 보유한다.  
  단어(단일): `Constant` 상수. 여기서는 SelectionCard의 고정 레이아웃 수치 모음
- **`SelectionCardStyle`** `enum` · public · [SelectionCardStyle.swift:4](../../../sources/Projects/UI/Component/CollectionItems/SelectionCard/SelectionCardStyle.swift#L4) · 채택: Sendable, Equatable  
  SelectionCard의 표시 형태를 정하는 열거형으로 detailed·compact 두 케이스를 가진다. 케이스별 최소 높이(80/52)와 썸네일 표시 여부(detailed만 true)를 제공한다.  
  단어: `Selection` 선택. 여기서는 SelectionCard가 다루는 항목 선택 · `Card` 카드. 여기서는 SelectionCard 컴포넌트 · `Style` 스타일·형태. 여기서는 카드의 상세/간결 표시 형태

## Component/Controls

- **`ActionButton`** `struct` · public · [ActionButton.swift:5](../../../sources/Projects/UI/Component/Controls/ActionButton.swift#L5) · 채택: View  
  제목 문자열 또는 StyledText 라벨을 받아 Style(primary·secondary·destructive·text·primaryText)과 Size(large·medium·small)에 따라 배경색·글자색·높이를 결정하는 공용 버튼 View. 탭 시 UIImpactFeedbackGenerator 햅틱을 울린 뒤 action을 실행하며 primary/secondary 등 정적 팩토리 메서드를 제공한다.  
  단어: `Action` 동작·행위. 여기서는 사용자가 눌러 어떤 동작을 실행시키는 주요 행동 버튼 · `Button` 누름 버튼. 여기서는 SwiftUI Button을 감싼 UI 컴포넌트
- **`ActionButton.Style`** `enum` · public · [ActionButton.swift:39](../../../sources/Projects/UI/Component/Controls/ActionButton.swift#L39) · 채택: Sendable, Equatable  
  ActionButton의 시각 스타일(primary·secondary·destructive·text·primaryText)을 나타내며 isEnabled 여부에 따른 backgroundColor와 titleColor 토큰을 계산한다.  
  단어(단일): `Style` 양식·스타일. 여기서는 ActionButton의 배경·글자색 조합을 결정하는 시각 변형
- **`ActionButton.Size`** `enum` · public · [ActionButton.swift:83](../../../sources/Projects/UI/Component/Controls/ActionButton.swift#L83) · 채택: Sendable, Equatable  
  ActionButton의 크기(large·medium·small)를 나타내며 surfaceHeight, minimumHitArea, touchHeight 값을 제공한다.  
  단어(단일): `Size` 크기. 여기서는 ActionButton의 표면 높이와 터치 영역 높이를 정하는 크기 단계
- **`ActionButton.Label`** `enum` · private · [ActionButton.swift:268](../../../sources/Projects/UI/Component/Controls/ActionButton.swift#L268) · 채택: Sendable, Equatable  
  ActionButton 내부에서 라벨 내용이 일반 문자열 제목(title)인지 이미 스타일된 텍스트(styled)인지를 구분하는 private 열거형이며 content 계산에서 분기된다.  
  단어(단일): `Label` 라벨·표시 문구. 여기서는 버튼 안에 표시할 텍스트 내용의 종류
- **`AppleSignInButton`** `struct` · public · [AppleSignInButton.swift:7](../../../sources/Projects/UI/Component/Controls/AppleSignInButton.swift#L7) · 채택: View  
  applelogo 시스템 심볼과 'Apple로 시작하기' 문구를 흰 배경 위에 배치한 Apple 로그인 진입 버튼 View. action 클로저 하나만 받는다.  
  단어: `Apple` 외부 고정 명칭(Apple 사). 여기서는 Apple 계정 로그인 제공자 · `SignIn` Sign + In, 로그인. 여기서는 Apple 계정으로 로그인 흐름을 시작하는 행위 · `Button` 누름 버튼. 여기서는 로그인 흐름을 시작하는 버튼 컴포넌트
- **`AppleSignInButton.Constant`** `enum` · private · [AppleSignInButton.swift:37](../../../sources/Projects/UI/Component/Controls/AppleSignInButton.swift#L37)  
  AppleSignInButton의 horizontalSpacing(5), surfaceHeight(54), fontSize(19) 레이아웃 상수를 모아 둔 private 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스
- **`BookmarkButton`** `struct` · public · [BookmarkButton.swift:6](../../../sources/Projects/UI/Component/Controls/BookmarkButton.swift#L6) · 채택: View  
  isSaved 여부에 따라 bookmark / bookmark.fill 시스템 심볼과 색을 바꿔 보여주는 북마크 토글 버튼 View. accessibilityLabel과 onTap 클로저를 받으며 저장 상태일 때 isSelected 접근성 트레이트를 추가한다.  
  단어: `Bookmark` 책갈피·즐겨찾기. 여기서는 항목을 저장(북마크)하는 기능 · `Button` 누름 버튼. 여기서는 북마크 상태를 토글하는 버튼 컴포넌트
- **`BookmarkButton.Constant`** `enum` · private · [BookmarkButton.swift:49](../../../sources/Projects/UI/Component/Controls/BookmarkButton.swift#L49)  
  BookmarkButton의 surfaceWidth(40), surfaceHeight(ControlSizeToken.action), glyphSize(16) 상수를 모아 둔 private 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스
- **`ChoiceAnswerOption`** `struct` · public · [ChoiceAnswerOption.swift:6](../../../sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift#L6) · 채택: View  
  객관식 퀴즈의 선택지 하나를 letter(보기 기호)와 text로 카드 형태로 그리는 View. State(default·selected·correct·incorrect)로 채움·테두리 색을 정하고 ExpansionControl로 본문 펼침/접힘과 셰브런 토글 버튼을 제어하며 onTap으로 선택을 알린다.  
  단어: `Choice` 선택·선택지. 여기서는 객관식 문제의 보기 · `Answer` 답·정답. 여기서는 문제에 대한 답변 후보 · `Option` 선택 항목. 여기서는 사용자가 고를 수 있는 보기 항목 하나
- **`ChoiceAnswerOption.State`** `enum` · public · [ChoiceAnswerOption.swift:26](../../../sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift#L26) · 채택: Sendable, Equatable  
  선택지의 표시 상태(default·selected·correct·incorrect)를 나타내며 fillToken, borderToken, letterColor, textColor와 접근성 접미사('정답'/'오답')를 계산한다.  
  단어(단일): `State` 상태. 여기서는 선택지가 기본·선택됨·정답·오답 중 어느 표시 상태인지
- **`ChoiceAnswerOption.ExpansionControl`** `enum` · public · [ChoiceAnswerOption.swift:85](../../../sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift#L85)  
  선택지 본문의 펼침 방식을 fixed(isExpanded)와 toggleable(isExpanded, onToggleExpand) 두 케이스로 나타내며 공통 isExpanded 값을 제공한다. toggleable일 때만 셰브런 토글 버튼이 그려진다.  
  단어: `Expansion` 펼침·확장. 여기서는 선택지 본문을 펼치거나 접는 동작 · `Control` 제어·제어 방식. 여기서는 펼침이 고정인지 토글 가능한지의 제어 방식
- **`ChoiceAnswerOption.Constant`** `enum` · private · [ChoiceAnswerOption.swift:133](../../../sources/Projects/UI/Component/Controls/ChoiceAnswerOption.swift#L133)  
  ChoiceAnswerOption의 패딩(horizontal 18, top 14, bottom 18), rowSpacing(4), chevronIconSize(16), chevronTapSize(36) 상수를 모아 둔 private 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스
- **`IconGlassButton`** `struct` · public · [IconGlassButton.swift:4](../../../sources/Projects/UI/Component/Controls/IconGlassButton.swift#L4) · 채택: View  
  ResourceImage 아이콘을 원형 glassEffect 배경 위에 그리는 아이콘 전용 버튼 View. Style(neutral·accent·destructive)로 틴트·배경 토큰을, Size(medium·small)로 표면·아이콘 크기를 정하고 접근성 라벨과 action을 받으며 neutral/accent/destructive 정적 팩토리를 제공한다. ScreenControlBar가 사용한다.  
  단어: `Icon` 아이콘·기호 이미지. 여기서는 텍스트 없이 아이콘만 표시하는 버튼임을 뜻함 · `Glass` 유리. 여기서는 iOS glassEffect(리퀴드 글래스) 배경 스타일 · `Button` 누름 버튼. 여기서는 SwiftUI Button을 감싼 UI 컴포넌트
- **`IconGlassButton.Icon`** `typealias` · public · [IconGlassButton.swift:24](../../../sources/Projects/UI/Component/Controls/IconGlassButton.swift#L24) · 그래프 미수집(grep 보강)  
  ResourceImage.Asset.Icon에 대한 typealias로, IconGlassButton의 icon 파라미터 타입을 짧게 지칭한다.  
  단어(단일): `Icon` 아이콘·기호 이미지. 여기서는 디자인 시스템 리소스 아이콘 에셋 열거형의 별칭
- **`IconGlassButton.Style`** `enum` · public · [IconGlassButton.swift:26](../../../sources/Projects/UI/Component/Controls/IconGlassButton.swift#L26) · 채택: Sendable, Equatable  
  IconGlassButton의 시각 스타일(neutral·accent·destructive)을 나타내며 tintColor와 backgroundColor ColorToken을 제공한다.  
  단어(단일): `Style` 양식·스타일. 여기서는 아이콘 틴트와 배경색을 결정하는 시각 변형
- **`IconGlassButton.Size`** `enum` · public · [IconGlassButton.swift:48](../../../sources/Projects/UI/Component/Controls/IconGlassButton.swift#L48) · 채택: Sendable, Equatable  
  IconGlassButton의 크기(medium 40 / small 36)를 나타내며 surfaceSize, iconSize, touchSize(최소 터치 크기)를 제공한다.  
  단어(단일): `Size` 크기. 여기서는 버튼 표면과 아이콘 크기를 정하는 크기 단계
- **`IconPlainButton`** `struct` · public · [IconPlainButton.swift:4](../../../sources/Projects/UI/Component/Controls/IconPlainButton.swift#L4) · 채택: View  
  ResourceImage 아이콘을 원형 배경(기본 clear) 위에 그리는 단순 아이콘 버튼 View. tintColor, backgroundColor, iconSize, size를 직접 CGFloat·ColorToken으로 받고 최소 터치 크기를 보장하며 접근성 라벨과 action을 받는다.  
  단어: `Icon` 아이콘·기호 이미지. 여기서는 아이콘만 표시하는 버튼임을 뜻함 · `Plain` 평범한·장식 없는. 여기서는 glass 효과 없이 단색 원형 배경만 쓰는 스타일 · `Button` 누름 버튼. 여기서는 SwiftUI Button을 감싼 UI 컴포넌트
- **`IconPlainButton.Icon`** `typealias` · public · [IconPlainButton.swift:28](../../../sources/Projects/UI/Component/Controls/IconPlainButton.swift#L28) · 그래프 미수집(grep 보강)  
  ResourceImage.Asset.Icon에 대한 typealias로, IconPlainButton의 icon 파라미터 타입을 짧게 지칭한다.  
  단어(단일): `Icon` 아이콘·기호 이미지. 여기서는 디자인 시스템 리소스 아이콘 에셋 열거형의 별칭
- **`IconPlainButton.Constant`** `enum` · private · [IconPlainButton.swift:52](../../../sources/Projects/UI/Component/Controls/IconPlainButton.swift#L52)  
  IconPlainButton의 minimumTouchSize(ControlSizeToken.minimumTouch) 상수를 담은 private 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스
- **`TextField`** `struct` · public · [TextField.swift:4](../../../sources/Projects/UI/Component/Controls/TextField.swift#L4) · 채택: View  
  placeholder와 text Binding을 받아 grey600 배경의 둥근 입력 상자를 그리는 UI 패키지 자체 텍스트 필드 View. isSecure면 SecureField를 쓰고, errorMessage·포커스·입력 유무로 State(default·active·filled·error)를 계산해 테두리를 바꾸며 onSubmit 시 onCommit을 호출한다. SwiftUI.TextField와 이름이 같아 내부에서는 SwiftUI.TextField로 구분한다.  
  단어(단일): `TextField` 외부 고정 명칭(SwiftUI TextField)과 동일한 이름. 여기서는 문자열을 입력받는 UI 패키지 고유의 텍스트 필드 컴포넌트
- **`TextField.State`** `enum` · internal · [TextField.swift:47](../../../sources/Projects/UI/Component/Controls/TextField.swift#L47) · 채택: Sendable, Equatable  
  TextField의 표시 상태(default·active·filled·error)를 나타내며 borderToken에서 파생한 borderColor·borderWidth와 backgroundColor(grey600)를 제공한다.  
  단어(단일): `State` 상태. 여기서는 텍스트 필드가 기본·활성·입력됨·오류 중 어느 표시 상태인지
- **`TextField.Constant`** `enum` · internal · [TextField.swift:88](../../../sources/Projects/UI/Component/Controls/TextField.swift#L88)  
  TextField의 horizontalPadding(16), surfaceHeight(52), errorSpacing(4) 상수를 모아 둔 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/Chip

- **`Chip`** `struct` · public · [Chip.swift:6](../../../sources/Projects/UI/Component/Controls/Chip/Chip.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  label 문자열을 한 줄로 표시하는 선택형 칩 버튼 View. isSelected에 따라 배경(blue100/grey600)과 글자색(grey700/grey100)을 바꾸고 onTap을 호출하며 최소 터치 크기를 보장한다.  
  단어(단일): `Chip` 작은 조각·칩 UI. 여기서는 필터·태그를 고르는 작은 알약형 선택 버튼
- **`Chip.Constant`** `enum` · internal · [Chip.swift:56](../../../sources/Projects/UI/Component/Controls/Chip/Chip.swift#L56)  
  Chip의 height(36), horizontalPadding(8), labelLineLimit(1) 상수를 모아 둔 extension 안의 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/LabeledTextField

- **`LabeledTextField`** `struct` · public · [LabeledTextField.swift:6](../../../sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  앞에 label 텍스트를 붙인 밑줄형 텍스트 입력 View. text Binding, placeholder, supportingText, isError, 키보드 옵션, 외부 FocusState Binding을 받고 입력값이 있으면 '입력 지우기' 버튼을 보여주며 에러 시 밑줄·라벨·보조문을 error 색으로 바꾼다.  
  단어: `Labeled` 라벨이 붙은. 여기서는 입력 필드 앞에 이름 라벨이 표시됨 · `TextField` 외부 고정 명칭(SwiftUI TextField). 여기서는 문자열을 입력받는 텍스트 필드 컴포넌트
- **`LabeledTextField.Constant`** `enum` · private · [LabeledTextField.swift:108](../../../sources/Projects/UI/Component/Controls/LabeledTextField/LabeledTextField.swift#L108)  
  LabeledTextField의 fieldHeight(56), underlineHeight(1), contentSpacing, trailingIconSpacing, clearIconSize, clearButtonTouchSize(44), supportingText 패딩 상수를 모아 둔 extension 안의 private 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/PolicyAgreementRow

- **`PolicyAgreementRow`** `struct` · public · [PolicyAgreementRow.swift:6](../../../sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  약관 동의 행 하나를 그리는 View. title, isRequired, isSelected를 받아 체크 아이콘+제목 토글 버튼(onToggle)과 우측 chevron 링크 버튼(onOpenLink)을 배치하고 '필수/선택, 제목' 접근성 라벨과 accessibilityIdentifier를 부여한다.  
  단어: `Policy` 정책·약관. 여기서는 개인정보 처리방침·이용약관 같은 정책 문서 · `Agreement` 동의. 여기서는 약관에 대한 사용자 동의 여부 · `Row` 행·줄. 여기서는 목록의 한 줄 UI
- **`PolicyAgreementRow.Constant`** `enum` · fileprivate · [PolicyAgreementRow.swift:89](../../../sources/Projects/UI/Component/Controls/PolicyAgreementRow/PolicyAgreementRow.swift#L89)  
  PolicyAgreementRow의 checkSize(24), linkSurfaceSize(36), checkboxSpacing(8), minimumTouchSize(44) 상수를 모아 둔 extension 안의 fileprivate 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/ScreenControlBar

- **`ScreenControlBar.Control`** `struct` · public · [ScreenControlBar+Control.swift:5](../../../sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar+Control.swift#L5) · 채택: Sendable, Equatable  
  ScreenControlBar의 좌·우 버튼 하나를 기술하는 값 타입으로 icon과 접근성 label을 가진다. back(chevronLeftWhite, '뒤로 가기')과 close(close, '닫기') 정적 프리셋을 제공한다.  
  단어(단일): `Control` 제어 요소·컨트롤. 여기서는 화면 상단 바에 놓이는 버튼 하나의 아이콘·라벨 정의
- **`ScreenControlBar.Control.Icon`** `typealias` · public · [ScreenControlBar+Control.swift:19](../../../sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar+Control.swift#L19) · 그래프 미수집(grep 보강)  
  ResourceImage.Asset.Icon에 대한 typealias로, Control의 icon 프로퍼티 타입을 짧게 지칭한다.  
  단어(단일): `Icon` 아이콘·기호 이미지. 여기서는 디자인 시스템 리소스 아이콘 에셋 열거형의 별칭
- **`ScreenControlBar`** `struct` · public · [ScreenControlBar.swift:6](../../../sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  화면 상단에 leading(기본 .back)·trailing Control을 IconGlassButton.neutral(medium)로 좌우 배치하는 내비게이션 바 View. onLeadingTap·onTrailingTap 클로저를 받고 높이 40에 하단 패딩 10을 둔다.  
  단어: `Screen` 화면. 여기서는 앱의 한 화면 단위 · `Control` 제어 요소·컨트롤. 여기서는 뒤로 가기·닫기 같은 화면 제어 버튼 · `Bar` 막대·바 UI. 여기서는 화면 상단에 가로로 놓인 버튼 바
- **`ScreenControlBar.Constant`** `enum` · fileprivate · [ScreenControlBar.swift:62](../../../sources/Projects/UI/Component/Controls/ScreenControlBar/ScreenControlBar.swift#L62)  
  ScreenControlBar의 controlRowHeight(40), bottomPadding(10) 상수를 모아 둔 extension 안의 fileprivate 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/SelectableSettingRow

- **`SelectableSettingRow`** `struct` · public · [SelectableSettingRow.swift:6](../../../sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  설정 목록의 선택 가능한 행 View. title을 body1로 표시하고 isSelected일 때 우측에 checkmark를 보여주며 행 전체가 onTap 버튼이고 isSelected 접근성 트레이트를 추가한다.  
  단어: `Selectable` 선택 가능한. 여기서는 탭으로 고를 수 있는 행 · `Setting` 설정. 여기서는 설정 화면의 옵션 항목 · `Row` 행·줄. 여기서는 목록의 한 줄 UI
- **`SelectableSettingRow.Constant`** `enum` · fileprivate · [SelectableSettingRow.swift:54](../../../sources/Projects/UI/Component/Controls/SelectableSettingRow/SelectableSettingRow.swift#L54)  
  SelectableSettingRow의 horizontalPadding(18), minimumHeight(52), minimumTrailingSpacing(4) 상수를 모아 둔 extension 안의 fileprivate 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Controls/SelectionCardList

- **`SelectionCardList.Item`** `struct` · public · [SelectionCardList+Item.swift:5](../../../sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList+Item.swift#L5) · 채택: Identifiable, Sendable, Equatable  
  SelectionCardList가 그릴 카드 하나의 데이터로 id, title, supportingText, illust(ResourceImage.Asset.Illust), isSelected를 가진다.  
  단어(단일): `Item` 항목. 여기서는 선택 카드 목록의 카드 하나를 나타내는 데이터
- **`SelectionCardList`** `struct` · public · [SelectionCardList.swift:6](../../../sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  Item 배열을 세로로 나열해 각 항목을 SelectionCard로 그리는 선택 카드 목록 View. SelectionCardStyle(기본 detailed)의 showsThumbnail에 따라 illust 썸네일에 gradient3 오버레이를 얹고 탭 시 onSelect(item.id)를 호출한다.  
  단어: `Selection` 선택. 여기서는 여러 카드 중 하나를 고르는 동작 · `Card` 카드 UI. 여기서는 제목·보조문·이미지를 담은 카드형 항목 · `List` 목록. 여기서는 카드들을 세로로 나열한 컬렉션
- **`SelectionCardList.Constant`** `enum` · fileprivate · [SelectionCardList.swift:77](../../../sources/Projects/UI/Component/Controls/SelectionCardList/SelectionCardList.swift#L77)  
  SelectionCardList의 itemSpacing(8), thumbnailOverlayOpacity(0.2) 상수를 모아 둔 extension 안의 fileprivate 네임스페이스 열거형.  
  단어(단일): `Constant` 상수·불변값. 여기서는 해당 컴포넌트의 레이아웃 치수(높이·간격·크기)를 모아 둔 네임스페이스

## Component/Displays

- **`LabeledCard`** `struct` · public · [LabeledCard.swift:6](../../../sources/Projects/UI/Component/Displays/LabeledCard.swift#L6) · 채택: View  
  caption1 라벨과 body2 본문을 세로로 쌓고 배경·모서리를 입힌 카드 View. accent(파란 배경)·neutral(회색 배경) 정적 팩토리로만 생성하며 label·text·Style을 보유한다.  
  단어: `Labeled` 라벨이 붙은. 여기서는 본문 위에 작은 제목 라벨(예: 'AI 해설')이 표시되는 것 · `Card` 카드. 여기서는 배경색과 큰 모서리 반경을 가진 박스형 컨테이너 View
- **`LabeledCard.Style`** `enum` · private · [LabeledCard.swift:38](../../../sources/Projects/UI/Component/Displays/LabeledCard.swift#L38) · 채택: Sendable, Equatable  
  LabeledCard의 시각 변형(accent, neutral)을 나타내는 enum. 각 case에 대응하는 background·textColor ColorToken을 계산 프로퍼티로 제공한다.  
  단어(단일): `Style` 양식·스타일. 여기서는 LabeledCard의 배경색·글자색 조합을 결정하는 시각 변형
- **`LabeledCard.Constant`** `enum` · private · [LabeledCard.swift:59](../../../sources/Projects/UI/Component/Displays/LabeledCard.swift#L59)  
  LabeledCard의 titleSpacing(8)·padding(16) 레이아웃 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`LaunchLogo`** `struct` · public · [LaunchLogo.swift:6](../../../sources/Projects/UI/Component/Displays/LaunchLogo.swift#L6) · 채택: View  
  앱 로고 ResourceImage를 120pt 크기로 표시하며 등장 시 페이드인·스케일 애니메이션을 실행한 뒤 대기 시간 후 onCompletion 콜백을 호출하는 View. isVisible 상태와 onCompletion 클로저를 보유한다.  
  단어: `Launch` 실행·시작. 여기서는 앱이 처음 켜질 때의 런치(실행) 화면 단계 · `Logo` 로고. 여기서는 앱 로고 이미지 애셋(.logo(.app))
- **`LaunchLogo.Constant`** `enum` · private · [LaunchLogo.swift:27](../../../sources/Projects/UI/Component/Displays/LaunchLogo.swift#L27)  
  LaunchLogo의 logoSize·initialScale·glow 관련 치수와 fadeInSeconds·holdSeconds 시간 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`ResourceAnimation`** `struct` · public · [ResourceAnimation.swift:5](../../../sources/Projects/UI/Component/Displays/ResourceAnimation.swift#L5) · 채택: View  
  Lottie 애니메이션 애셋을 LottieView로 재생하는 View. asset·isLooping·speed·contentMode·onCompletion을 보유하며 루프 여부·속도·완료 콜백을 설정한다.  
  단어: `Resource` 자원·리소스. 여기서는 UI 모듈 번들에 포함된 애니메이션 파일 자원 · `Animation` 애니메이션. 여기서는 Lottie로 재생하는 동영상형 애니메이션
- **`ResourceAnimation.Asset`** `enum` · public · [ResourceAnimation.swift:25](../../../sources/Projects/UI/Component/Displays/ResourceAnimation.swift#L25) · 채택: String, Sendable, Equatable, CaseIterable  
  번들에 포함된 Lottie 애니메이션 이름(complete, general-loading, notification, project-empty, set-creation-loading, storage-empty)을 rawValue로 갖는 enum. animation 계산 프로퍼티로 LottieAnimation을 로드한다.  
  단어(단일): `Asset` 자산·애셋. 여기서는 번들에 담긴 Lottie 애니메이션 파일 식별자
- **`ResourceImage`** `struct` · public · [ResourceImage.swift:6](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L6) · 채택: View  
  Asset으로 지정한 번들 이미지를 resizable Image로 만들고 contentMode(fit/fill)를 적용해 표시하는 View. asset·contentMode를 보유한다.  
  단어: `Resource` 자원·리소스. 여기서는 UI 모듈 번들에 포함된 이미지 자원 · `Image` 이미지. 여기서는 SwiftUI Image로 그려지는 정적 그림
- **`ResourceImage.Asset`** `enum` · public · [ResourceImage.swift:20](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L20) · 채택: Sendable, Equatable  
  이미지 애셋 분류(icon, illust, logo, onboarding)를 연관값으로 감싸는 enum. fileprivate resourceName으로 하위 enum의 rawValue(번들 리소스 이름)를 꺼낸다.  
  단어(단일): `Asset` 자산·애셋. 여기서는 번들에 담긴 이미지 리소스의 분류별 식별자
- **`ResourceImage.Asset.Logo`** `enum` · public · [ResourceImage.swift:28](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L28) · 채택: String, Sendable, Equatable, CaseIterable  
  로고 이미지 리소스 이름을 갖는 enum. 현재 app('app-logo-image') 하나만 있다.  
  단어(단일): `Logo` 로고. 여기서는 앱 로고 이미지 리소스 식별자
- **`ResourceImage.Asset.Icon`** `enum` · public · [ResourceImage.swift:32](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L32) · 채택: String, Sendable, Equatable, CaseIterable  
  'ic-' 접두 아이콘 이미지 리소스 이름(bookmark, chevron, close, setting 계열, status 계열 등 34개)을 rawValue로 갖는 enum.  
  단어(단일): `Icon` 아이콘. 여기서는 작은 픽토그램 이미지 리소스 식별자
- **`ResourceImage.Asset.Illust`** `enum` · public · [ResourceImage.swift:69](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L69) · 채택: String, Sendable, Equatable, CaseIterable  
  'illust_' 접두 일러스트 이미지 리소스 이름(knowledge 3단계, level 4단계)을 rawValue로 갖는 enum.  
  단어(단일): `Illust` Illustration의 축약, 삽화. 여기서는 지식·레벨 단계를 나타내는 일러스트 이미지 리소스 식별자
- **`ResourceImage.Asset.Onboarding`** `enum` · public · [ResourceImage.swift:79](../../../sources/Projects/UI/Component/Displays/ResourceImage.swift#L79) · 채택: String, Sendable, Equatable, CaseIterable  
  온보딩 목업 이미지 리소스 이름(onboarding-mockup-1~3)을 rawValue로 갖는 enum. OnboardingMockup에서 사용된다.  
  단어(단일): `Onboarding` 탑승·적응 절차. 여기서는 온보딩 화면용 이미지 리소스 분류
- **`ScreenHeaderTitle`** `struct` · public · [ScreenHeaderTitle.swift:4](../../../sources/Projects/UI/Component/Displays/ScreenHeaderTitle.swift#L4) · 채택: View  
  선택적 title(subtitle1)과 subtitle(body2, white30)을 세로로 쌓아 화면 상단 제목 영역을 그리는 View. 둘 다 nil이면 아무것도 그리지 않는다.  
  단어: `Screen` 화면. 여기서는 앱의 한 화면(페이지) · `Header` 머리글·상단부. 여기서는 화면 맨 위 제목 영역 · `Title` 제목. 여기서는 헤더에 표시되는 제목·부제목 텍스트
- **`SplashView`** `struct` · public · [SplashView.swift:6](../../../sources/Projects/UI/Component/Displays/SplashView.swift#L6) · 채택: View  
  'Hello World'와 'Let’s Git-it!'을 타자 효과로 한 글자씩 드러내고 커서를 깜빡이는 스플래시 화면 View. 시퀀스 종료 후 onCompletion을 호출하고 커서 깜빡임을 계속한다.  
  단어: `Splash` 튀김·첫 화면. 여기서는 앱 시작 시 잠시 보여 주는 스플래시 화면 · `View` SwiftUI 화면 요소. 여기서는 스플래시를 렌더링하는 View 타입
- **`SplashView.Cursor`** `enum` · private · [SplashView.swift:40](../../../sources/Projects/UI/Component/Displays/SplashView.swift#L40) · 채택: Equatable  
  타자 커서의 상태(hidden, solid, blinking(isVisible))를 나타내는 enum. opacity 계산 프로퍼티로 커서 막대 불투명도를 결정한다.  
  단어(단일): `Cursor` 커서. 여기서는 타자 효과 끝에 표시되는 세로 막대 커서의 표시 상태
- **`SplashView.Constant`** `enum` · private · [SplashView.swift:54](../../../sources/Projects/UI/Component/Displays/SplashView.swift#L54)  
  SplashView의 lineSpacing, 타이핑·딜레이·깜빡임·페이드 Duration 상수와 제목·부제목 TextStyleToken을 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`StyledText`** `struct` · public · [StyledText.swift:4](../../../sources/Projects/UI/Component/Displays/StyledText.swift#L4) · 채택: View, Sendable, Equatable  
  text·TextStyleToken·ColorToken·TextAlignment를 보유하고 디자인 시스템 스타일·행간·색을 적용한 Text를 그리는 View. headline1~caption2 정적 팩토리를 제공하며 UI 패키지 전반에서 텍스트 표시에 쓰인다.  
  단어: `Styled` 스타일이 적용된. 여기서는 디자인 시스템 TextStyleToken이 적용된 상태 · `Text` 텍스트. 여기서는 SwiftUI Text로 그려지는 문자열
- **`TagBadge`** `struct` · public · [TagBadge.swift:4](../../../sources/Projects/UI/Component/Displays/TagBadge.swift#L4) · 채택: View  
  짧은 문자열을 배경색과 작은 모서리 반경이 있는 배지로 그리는 View. Style(neutral, accent, selected, muted)과 Size(regular, compact)를 보유하며 각 스타일별 정적 팩토리를 제공한다.  
  단어: `Tag` 태그·꼬리표. 여기서는 항목을 분류하는 짧은 키워드 문자열 · `Badge` 배지. 여기서는 배경이 있는 작은 알약형 라벨 View
- **`TagBadge.Style`** `enum` · public · [TagBadge.swift:20](../../../sources/Projects/UI/Component/Displays/TagBadge.swift#L20) · 채택: Sendable, Equatable  
  TagBadge의 시각 변형(neutral, accent, selected, muted)을 나타내는 enum. backgroundColor·textColor ColorToken을 계산 프로퍼티로 제공한다.  
  단어(단일): `Style` 양식·스타일. 여기서는 TagBadge의 배경색·글자색 조합을 결정하는 시각 변형
- **`TagBadge.Size`** `enum` · public · [TagBadge.swift:47](../../../sources/Projects/UI/Component/Displays/TagBadge.swift#L47) · 채택: Sendable, Equatable  
  TagBadge의 크기 변형(regular=body2, compact=body3)을 나타내는 enum. textStyle 계산 프로퍼티로 TextStyleToken을 제공한다.  
  단어(단일): `Size` 크기. 여기서는 TagBadge 글자 스타일로 결정되는 배지 크기 단계
- **`TagBadge.Constant`** `enum` · private · [TagBadge.swift:104](../../../sources/Projects/UI/Component/Displays/TagBadge.swift#L104)  
  TagBadge의 horizontalPadding(10)·topPadding(3)·bottomPadding(4) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`WebContentView`** `struct` · public · [WebContentView.swift:7](../../../sources/Projects/UI/Component/Displays/WebContentView.swift#L7) · 채택: View  
  주어진 URL을 WebKit WebView로 로드하고 콘텐츠 배경을 숨긴 뒤 grey600 배경을 깔아 표시하는 View. url을 보유한다.  
  단어: `Web` 웹. 여기서는 URL로 불러오는 웹 페이지 · `Content` 내용·콘텐츠. 여기서는 웹 페이지의 표시 내용 · `View` SwiftUI 화면 요소. 여기서는 웹 콘텐츠를 렌더링하는 View 타입

## Component/Displays/OnboardingMockup

- **`OnboardingMockup`** `struct` · public · [OnboardingMockup.swift:6](../../../sources/Projects/UI/Component/Displays/OnboardingMockup/OnboardingMockup.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  page 번호(1, 2, 그 외)에 따라 온보딩 목업 이미지 애셋(mockup1~3)을 골라 fill 모드 ResourceImage로 전체 크기에 표시하는 View.  
  단어: `Onboarding` 탑승·적응 절차. 여기서는 앱 최초 진입 시 안내하는 온보딩 화면 · `Mockup` 실물 모형·시안. 여기서는 온보딩 화면에 보여 주는 앱 화면 목업 이미지
- **`OnboardingMockup.Constant`** `enum` · fileprivate · [OnboardingMockup.swift:38](../../../sources/Projects/UI/Component/Displays/OnboardingMockup/OnboardingMockup.swift#L38)  
  OnboardingMockup의 확장에 선언된 상수 enum으로 bezelWidth(8) 하나를 가진다. 현재 본문에서는 참조되지 않는다.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum

## Component/Displays/RubricView

- **`RubricView`** `struct` · public · [RubricView.swift:6](../../../sources/Projects/UI/Component/Displays/RubricView/RubricView.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  선택적 overallFeedback 본문과 criteria 문자열 목록을 checkmark.circle 아이콘과 함께 나열해 회색 카드로 보여 주는 View. 채점 기준 표시에 쓰인다.  
  단어: `Rubric` 평가 기준표·루브릭. 여기서는 답안 평가 기준 항목과 총평 · `View` SwiftUI 화면 요소. 여기서는 루브릭을 렌더링하는 View 타입
- **`RubricView.Constant`** `enum` · fileprivate · [RubricView.swift:53](../../../sources/Projects/UI/Component/Displays/RubricView/RubricView.swift#L53)  
  RubricView의 확장에 선언된 상수 enum으로 contentPadding(18)을 가진다.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum

## Component/Indicators

- **`ContinuousProgressBar`** `struct` · public · [ContinuousProgressBar.swift:4](../../../sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift#L4) · 채택: View  
  0~1로 클램프한 progress 비율만큼 캡슐 트랙 위에 채움 캡슐을 그리는 진행률 막대 View. Height(row 6pt, detail 10pt)를 보유하고 접근성 라벨 '학습 진행률'과 퍼센트 값을 제공한다.  
  단어: `Continuous` 연속적인. 여기서는 구간이 나뉘지 않고 비율로 매끄럽게 채워지는 방식 · `Progress` 진행. 여기서는 학습 진행률 비율 · `Bar` 막대. 여기서는 가로 캡슐 형태의 막대 View
- **`ContinuousProgressBar.Height`** `enum` · public · [ContinuousProgressBar.swift:18](../../../sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift#L18) · 채택: Sendable, Equatable  
  ContinuousProgressBar의 높이 변형(row, detail)을 나타내는 enum. value 계산 프로퍼티로 Constant의 rowHeight·detailHeight CGFloat를 반환한다.  
  단어(단일): `Height` 높이. 여기서는 진행률 막대의 세로 두께 단계
- **`ContinuousProgressBar.Constant`** `enum` · private · [ContinuousProgressBar.swift:73](../../../sources/Projects/UI/Component/Indicators/ContinuousProgressBar.swift#L73)  
  ContinuousProgressBar의 rowHeight(6)·detailHeight(10)와 trackColorToken(grey500)·fillColorToken(blue200)을 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`LabeledProgressBar`** `struct` · public · [LabeledProgressBar.swift:6](../../../sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift#L6) · 채택: View  
  label과 valueText를 caption1로 좌우에 배치하고 그 아래 detail 높이의 ContinuousProgressBar를 그리는 View. label·progress·valueText·valueColor를 보유한다.  
  단어: `Labeled` 라벨이 붙은. 여기서는 막대 위에 이름 라벨과 값 텍스트가 표시되는 것 · `Progress` 진행. 여기서는 학습 진행률 비율 · `Bar` 막대. 여기서는 내부에 포함된 ContinuousProgressBar
- **`LabeledProgressBar.Constant`** `enum` · private · [LabeledProgressBar.swift:39](../../../sources/Projects/UI/Component/Indicators/LabeledProgressBar.swift#L39)  
  LabeledProgressBar의 labelSpacing(10) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`PageIndicator`** `struct` · public · [PageIndicator.swift:6](../../../sources/Projects/UI/Component/Indicators/PageIndicator.swift#L6) · 채택: View  
  totalPages 개의 점을 가로로 나열하고 currentPage 점만 흰색으로 칠하는 페이지 위치 표시 View. 접근성 라벨 '페이지 안내'와 'N페이지 중 M번째' 값을 제공한다.  
  단어: `Page` 페이지. 여기서는 온보딩처럼 가로로 넘기는 화면의 한 장 · `Indicator` 표시기. 여기서는 현재 페이지 위치를 점으로 나타내는 표시 View
- **`PageIndicator.Constant`** `enum` · private · [PageIndicator.swift:44](../../../sources/Projects/UI/Component/Indicators/PageIndicator.swift#L44)  
  PageIndicator의 dotSpacing(10)·dotSize(8) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`ProgressSegments`** `struct` · public · [ProgressSegments.swift:4](../../../sources/Projects/UI/Component/Indicators/ProgressSegments.swift#L4) · 채택: View  
  total 개의 둥근 사각형 조각을 가로로 나열하고 completed 개수만큼 blue100으로 칠하는 문항 진행 표시 View. 접근성 라벨 'N문항 중 M문항 완료'를 제공한다.  
  단어: `Progress` 진행. 여기서는 퀴즈 문항 완료 진행 정도 · `Segments` 구간·조각들. 여기서는 문항 하나당 하나씩 나뉜 막대 조각
- **`ProgressSegments.Constant`** `enum` · private · [ProgressSegments.swift:32](../../../sources/Projects/UI/Component/Indicators/ProgressSegments.swift#L32)  
  ProgressSegments의 segmentSpacing(4)·segmentHeight(10) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum

## Component/Indicators/EmptyState

- **`EmptyState`** `struct` · public · [EmptyState.swift:6](../../../sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift#L6) · 채택: View  
  제네릭 Illustration View를 128pt로 그리고 그 아래 title(subtitle1)·message(body2)를 가운데 정렬로 보여 주는 빈 상태 안내 View. title·message·illustration을 보유한다.  
  단어: `Empty` 비어 있는. 여기서는 표시할 데이터가 없는 상태 · `State` 상태. 여기서는 목록이 비었을 때 화면이 보여 주는 안내 상태
- **`EmptyState.Constant`** `enum` · private · [EmptyState.swift:52](../../../sources/Projects/UI/Component/Indicators/EmptyState/EmptyState.swift#L52)  
  EmptyState의 illustrationSize(128)·illustrationSpacing(16)·textSpacing(8)·textMaxWidth(320)를 계산 프로퍼티로 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·색·시간 등 고정 수치를 모아 둔 네임스페이스 enum

## Component/Overlays/ActionMenu

- **`ActionMenu.Item`** `struct` · public · [ActionMenu+Item.swift:5](../../../sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu+Item.swift#L5) · 채택: Identifiable, Sendable, Equatable  
  ActionMenu의 한 행을 표현하는 값 타입. id·title·role·accessibilityLabel을 보유하며 선택 시 id가 onSelect 콜백으로 전달된다.  
  단어(단일): `Item` 항목. 여기서는 ActionMenu에 나열되는 선택 가능한 메뉴 행 하나
- **`ActionMenu.Item.Role`** `enum` · public · [ActionMenu+Item.swift:23](../../../sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu+Item.swift#L23) · 채택: Sendable, Equatable  
  메뉴 행의 성격(normal, destructive)을 나타내는 enum. case별로 제목 글자색 ColorToken(grey100, error)을 titleColor로 제공한다.  
  단어(단일): `Role` 역할. 여기서는 메뉴 행이 일반 동작인지 파괴적 동작인지 구분하는 의미 분류
- **`ActionMenu`** `struct` · public · [ActionMenu.swift:6](../../../sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  Item 목록을 세로로 나열하고 행 탭 시 onSelect(Item.ID)를 호출하는 글래스 효과 팝업 메뉴 View. 폭 160의 고정 너비로 그려지며 destructive 행은 error 색 제목으로 표시된다.  
  단어: `Action` 동작·행위. 여기서는 사용자가 선택해 실행하는 삭제·이동 같은 명령 · `Menu` 메뉴. 여기서는 동작 항목들을 세로로 나열한 선택 목록 View
- **`ActionMenu.Constant`** `enum` · fileprivate · [ActionMenu.swift:78](../../../sources/Projects/UI/Component/Overlays/ActionMenu/ActionMenu.swift#L78)  
  ActionMenu의 menuWidth(160)·containerPadding(4)·행 좌우/상하 패딩 상수를 담는 네임스페이스 enum. ActionMenu의 internal static 프로퍼티로 테스트에 노출된다.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum

## Component/Overlays

- **`ConfirmationSheet`** `struct` · public · [ConfirmationSheet.swift:5](../../../sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift#L5) · 채택: View  
  SheetSurface 위에 썸네일 이미지·제목·메시지와 파괴적 확인 버튼·텍스트 취소 버튼을 배치한 확인 시트 View. imageURL이 없거나 잘못되면 grey500 자리표시 사각형을 보여 준다.  
  단어: `Confirmation` 확인. 여기서는 삭제처럼 되돌릴 수 없는 동작을 실행하기 전 사용자에게 받는 최종 동의 · `Sheet` 시트. 여기서는 화면 하단에서 올라오는 모달 패널
- **`ConfirmationSheet.Constant`** `enum` · private · [ConfirmationSheet.swift:52](../../../sources/Projects/UI/Component/Overlays/ConfirmationSheet.swift#L52)  
  ConfirmationSheet의 thumbnailSize(128)와 썸네일·텍스트·버튼 간 상단 패딩, textSpacing(8) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`ModalOverlay`** `struct` · public · [ModalOverlay.swift:6](../../../sources/Projects/UI/Component/Overlays/ModalOverlay.swift#L6) · 채택: View  
  isPresented일 때 scrim 불투명도의 검은 배경과 하단에서 올라오는 콘텐츠를 겹쳐 보여 주는 제네릭 오버레이 View. 배경 탭 시 onDismiss를 호출하고 0.25초 easeInOut 전환을 적용한다.  
  단어: `Modal` 모달. 여기서는 뒤 화면 상호작용을 막고 앞에 띄우는 표시 방식 · `Overlay` 덮어씌우는 층. 여기서는 기존 화면 위에 scrim과 콘텐츠를 겹쳐 올리는 View
- **`ModalOverlay.Constant`** `enum` · private · [ModalOverlay.swift:41](../../../sources/Projects/UI/Component/Overlays/ModalOverlay.swift#L41)  
  ModalOverlay의 transitionDuration(0.25초) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`PushedScreenOverlay`** `struct` · public · [PushedScreenOverlay.swift:6](../../../sources/Projects/UI/Component/Overlays/PushedScreenOverlay.swift#L6) · 채택: View  
  isPresented일 때 콘텐츠를 오른쪽 가장자리에서 밀려 들어오게 겹쳐 보여 주는 제네릭 오버레이 View. 내비게이션 push와 비슷한 0.3초 전환을 적용한다.  
  단어: `Pushed` 밀어 넣어진. 여기서는 내비게이션 push처럼 오른쪽에서 들어오는 전환 · `Screen` 화면. 여기서는 오버레이로 올라오는 전체 화면 콘텐츠 · `Overlay` 덮어씌우는 층. 여기서는 기존 화면 위에 콘텐츠를 겹쳐 올리는 View
- **`PushedScreenOverlay.Constant`** `enum` · private · [PushedScreenOverlay.swift:32](../../../sources/Projects/UI/Component/Overlays/PushedScreenOverlay.swift#L32)  
  PushedScreenOverlay의 transitionDuration(0.3초) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`ScreenEdgeScrim`** `struct` · public · [ScreenEdgeScrim.swift:4](../../../sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift#L4) · 채택: View  
  화면 위·아래 가장자리에 topEdgeScrim/bottomEdgeScrim GradientToken 그라데이션을 지정 높이로 깔아 주는 View. top(height:)·bottom(height:) 정적 팩토리로 생성하며 히트 테스트와 접근성에서 제외된다.  
  단어: `Screen` 화면. 여기서는 스크림이 붙는 앱 화면 전체 · `Edge` 가장자리. 여기서는 화면의 상단 또는 하단 경계 · `Scrim` 스크림(콘텐츠를 흐리게 가리는 반투명 막). 여기서는 가장자리 콘텐츠를 어둡게 덮는 그라데이션 층
- **`ScreenEdgeScrim.Constant`** `enum` · private · [ScreenEdgeScrim.swift:31](../../../sources/Projects/UI/Component/Overlays/ScreenEdgeScrim.swift#L31)  
  ScreenEdgeScrim의 allowsHitTesting(false) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`WebSheet`** `struct` · public · [WebSheet.swift:6](../../../sources/Projects/UI/Component/Overlays/WebSheet.swift#L6) · 채택: View  
  SheetSurface 안에 제목과 닫기 IconGlassButton 헤더, URL을 표시하는 WebContentView를 배치한 웹 문서 시트 View. 닫기 탭 시 onDismiss를 호출한다.  
  단어: `Web` 웹. 여기서는 URL로 불러오는 웹 페이지 콘텐츠 · `Sheet` 시트. 여기서는 화면 하단에서 올라오는 모달 패널

## Component/Overlays/SheetSurface

- **`SheetSurface`** `struct` · public · [SheetSurface.swift:6](../../../sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift#L6) · 채택: View  
  상단 그래버 캡슐, 콘텐츠, 선택적 footer를 grey600 배경·상단 extraLarge 모서리·sheetElevation 그림자 위에 그리는 시트 바탕 View. isScrollable이면 콘텐츠 높이만큼만 커지는 ScrollView로 감싼다.  
  단어: `Sheet` 시트. 여기서는 화면 하단에서 올라오는 모달 패널 · `Surface` 표면·바탕. 여기서는 시트 콘텐츠를 얹는 배경·모서리·그림자가 적용된 판
- **`SheetSurface.Constant`** `enum` · private · [SheetSurface.swift:64](../../../sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift#L64)  
  SheetSurface의 그래버 크기(58×4)·그래버 상하 패딩·bottomPadding(24) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`ContentHeightPreferenceKey`** `struct` · private · [SheetSurface.swift:96](../../../sources/Projects/UI/Component/Overlays/SheetSurface/SheetSurface.swift#L96) · 채택: PreferenceKey  
  SheetSurface의 스크롤 콘텐츠 높이(CGFloat?)를 GeometryReader에서 상위로 전달하는 PreferenceKey. reduce는 nil이 아닌 최신 값을 택한다.  
  단어: `Content` 내용물. 여기서는 SheetSurface 안의 스크롤 콘텐츠 · `Height` 높이. 여기서는 측정된 콘텐츠의 세로 크기 · `PreferenceKey` SwiftUI 프로토콜 이름(외부 고정 명칭). 하위 View 값을 상위로 전달하는 키

## Component/Scaffolds

- **`BottomActionBar`** `struct` · public · [BottomActionBar.swift:6](../../../sources/Projects/UI/Component/Scaffolds/BottomActionBar.swift#L6) · 채택: View  
  하단 버튼 등 콘텐츠를 가로로 채우고 상단 4, 하단은 safe area 하단 여백과 최소 24 중 큰 값만큼 패딩을 주는 제네릭 하단 영역 View.  
  단어: `Bottom` 아래쪽. 여기서는 화면 하단에 고정되는 위치 · `Action` 동작. 여기서는 계속하기 같은 주요 동작 버튼 · `Bar` 막대 영역. 여기서는 버튼을 담는 가로 띠 형태 컨테이너
- **`BottomActionBar.Constant`** `enum` · private · [BottomActionBar.swift:27](../../../sources/Projects/UI/Component/Scaffolds/BottomActionBar.swift#L27)  
  BottomActionBar의 topPadding(4)·bottomPadding(24)·minimumBottomInset(24) 상수를 담는 네임스페이스 enum.  
  단어(단일): `Constant` 상수·고정값. 여기서는 부모 View의 레이아웃 치수·시간 등 고정 수치를 모아 둔 네임스페이스 enum
- **`FlowNavigationStack`** `struct` · public · [FlowNavigationStack.swift:3](../../../sources/Projects/UI/Component/Scaffolds/FlowNavigationStack.swift#L3) · 채택: View  
  외부에서 받은 Screen 배열 path로 읽기 전용 NavigationStack을 구성하고 root와 destination 화면의 내비게이션 바와 뒤로 버튼을 숨기는 제네릭 View.  
  단어: `Flow` 흐름. 여기서는 온보딩처럼 여러 화면을 순서대로 거치는 화면 진행 · `NavigationStack` SwiftUI 타입 이름(외부 고정 명칭). 경로 기반 push 내비게이션 컨테이너
- **`OverlayContainer`** `struct` · public · [OverlayContainer.swift:6](../../../sources/Projects/UI/Component/Scaffolds/OverlayContainer.swift#L6) · 채택: View · 그래프 미수집(grep 보강)  
  스크롤 콘텐츠 위에 header와 footer를 overlayHeaderScrim/overlayFooterScrim 그라데이션과 함께 겹쳐 두고, 콘텐츠 앞뒤에 같은 크기의 숨김 여백을 넣어 가려지지 않게 하는 화면 컨테이너 View. 배경 View 또는 ColorToken 배경을 받는다.  
  단어: `Overlay` 덮어씌우는 층. 여기서는 header·footer가 스크롤 콘텐츠 위에 겹쳐 떠 있는 배치 · `Container` 담는 그릇. 여기서는 화면 전체 레이아웃을 구성하는 스캐폴드 View
- **`ScreenContainer`** `struct` · public · [ScreenContainer.swift:4](../../../sources/Projects/UI/Component/Scaffolds/ScreenContainer.swift#L4) · 채택: View  
  콘텐츠를 화면 전체 크기로 펼치고 ColorToken 배경(기본 grey700)과 다크 색상 체계를 적용하는 제네릭 화면 컨테이너 View.  
  단어: `Screen` 화면. 여기서는 앱의 한 화면 전체 · `Container` 담는 그릇. 여기서는 화면 콘텐츠에 공통 배경·크기를 입히는 스캐폴드 View

## Component/Scaffolds/TabShell

- **`TabShell`** `struct` · public · [TabShell.swift:5](../../../sources/Projects/UI/Component/Scaffolds/TabShell/TabShell.swift#L5) · 채택: View  
  TabShellItem의 모든 case로 TabView를 구성하고 선택 상태를 Binding으로 받아 각 탭 콘텐츠·아이콘·제목을 그리는 제네릭 탭 컨테이너 View. 탭 색은 blue100 tint로 지정한다.  
  단어: `Tab` 탭. 여기서는 하단 탭 바의 탭 · `Shell` 껍데기. 여기서는 탭별 화면을 담는 최상위 틀 View
- **`TabShellItem`** `protocol` · public · [TabShellItem.swift:5](../../../sources/Projects/UI/Component/Scaffolds/TabShell/TabShellItem.swift#L5) · 채택: CaseIterable, Hashable, Identifiable, Sendable · 그래프 미수집(grep 보강)  
  TabShell에 들어갈 탭 종류가 채택하는 프로토콜. tabTitle·tabSystemImage를 요구하고 선택 여부에 따른 tabColor(isSelected:) 기본 구현을 제공한다.  
  단어: `Tab` 탭. 여기서는 하단 탭 바의 탭 · `Shell` 껍데기. 여기서는 TabShell 틀 · `Item` 항목. 여기서는 TabShell에 나열되는 탭 하나를 나타내는 타입
- **`TabShellPreviewItem`** `enum` · internal · [TabShellPreviewItem.swift:1](../../../sources/Projects/UI/Component/Scaffolds/TabShell/TabShellPreviewItem.swift#L1) · 채택: String, TabShellItem  
  TabShell 프리뷰용 탭 enum(home, project, saved, profile). case마다 한국어 탭 제목과 아이콘 이미지 이름을 제공한다.  
  단어: `Tab` 탭. 여기서는 하단 탭 바의 탭 · `Shell` 껍데기. 여기서는 TabShell 틀 · `Preview` 미리보기. 여기서는 Xcode #Preview에서만 쓰는 용도 · `Item` 항목. 여기서는 TabShell에 나열되는 탭 하나

## DesignSystem/Extensions

- **`FontRegistration`** `enum` · internal · [FontRegistration.swift:4](../../../sources/Projects/UI/DesignSystem/Extensions/FontRegistration.swift#L4)  
  번들의 NotoSansKR·PlusJakartaSans ttf 폰트를 CTFontManager로 프로세스 범위에 한 번만 등록하는 registerBundledFonts 정적 지연 값을 가진 네임스페이스 enum. TextStyleResolver가 폰트 생성 전에 참조한다.  
  단어: `Font` 글꼴. 여기서는 번들에 포함된 사용자 정의 ttf 폰트 · `Registration` 등록. 여기서는 폰트 파일을 시스템 폰트 관리자에 등록하는 처리
- **`TextStyleResolver`** `enum` · internal · [TextStyleResolver.swift:5](../../../sources/Projects/UI/DesignSystem/Extensions/TextStyleResolver.swift#L5)  
  TextStyleToken과 문자로부터 SwiftUI Font를 결정하는 네임스페이스 enum. 영문자는 plusJakartaSans, 그 외는 notoSans 패밀리를 고르고 lineHeightPercent로 추가 행간을 계산한다.  
  단어: `Text` 글자. 여기서는 화면에 표시할 문자열 · `Style` 양식. 여기서는 TextStyleToken이 정의한 글꼴 굵기·크기·행간 · `Resolver` 해석기. 여기서는 토큰과 문자를 실제 Font·행간 값으로 변환하는 역할
- **`DesignSystemEffectModifier`** `struct` · private · [View+EffectToken.swift:11](../../../sources/Projects/UI/DesignSystem/Extensions/View+EffectToken.swift#L11) · 채택: ViewModifier  
  EffectToken의 layers를 차례로 SwiftUI shadow로 적용하는 ViewModifier. View.designSystemEffect(_:)가 사용한다.  
  단어: `DesignSystem` 디자인 시스템. 여기서는 이 앱의 토큰 기반 디자인 규칙과 모듈명 · `Effect` 효과. 여기서는 EffectToken이 정의한 그림자 효과 · `Modifier` 수정자. 여기서는 SwiftUI ViewModifier 프로토콜(외부 고정 명칭)에서 온 결합 부분

## DesignSystem/Tokens

- **`BorderToken`** `struct` · public · [BorderToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/BorderToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  테두리 스타일 토큰. name·width·colorToken을 보유하고 default·focus·highlight·error·loadingTrack 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Border` 테두리. 여기서는 컴포넌트 외곽선의 두께와 색 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`ColorToken`** `struct` · public · [ColorToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/ColorToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  색 토큰. name·group·hex·opacityPercent를 보유하고 blue·purple·grey·opacity·state 계열 정적 색 인스턴스를 제공한다.  
  단어: `Color` 색. 여기서는 hex와 불투명도로 정의된 디자인 색 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`ColorToken.Group`** `enum` · public · [ColorToken.swift:25](../../../sources/Projects/UI/DesignSystem/Tokens/ColorToken.swift#L25) · 채택: String, Sendable, CaseIterable  
  색 토큰의 계열(Blue, Purple, Grey, Opacity, State)을 문자열 원시값으로 나타내는 enum.  
  단어(단일): `Group` 묶음. 여기서는 색 토큰이 속한 색상 계열 분류
- **`ControlSizeToken`** `struct` · public · [ControlSizeToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/ControlSizeToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  컨트롤 크기 토큰. name·value를 보유하고 action(54)·minimumTouch(44) 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Control` 조작 요소. 여기서는 버튼처럼 사용자가 누르는 UI 요소 · `Size` 크기. 여기서는 컨트롤의 높이·터치 영역 치수 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`CornerRadiusToken`** `struct` · public · [CornerRadiusToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/CornerRadiusToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  모서리 반경 토큰. name·value를 보유하고 micro(3)부터 pill(999)까지 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Corner` 모서리. 여기서는 사각형 View의 꼭짓점 · `Radius` 반경. 여기서는 모서리를 둥글게 깎는 반지름 값 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`DesignTokenSet`** `struct` · public · [DesignTokenSet.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/DesignTokenSet.swift#L3) · 채택: Sendable · 그래프 미수집(grep 보강)  
  색·그라데이션·폰트 패밀리·텍스트 스타일·불투명도·모서리 반경·테두리·효과·컨트롤 크기 토큰 목록을 한데 묶은 값 타입. current 정적 인스턴스와 이름 중복·범위·색 참조를 검사하는 validate()를 제공한다.  
  단어: `Design` 디자인. 여기서는 앱의 시각 디자인 체계 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 단위 · `Set` 집합. 여기서는 모든 종류의 토큰 목록을 모은 묶음
- **`DesignTokenSet.ValidationError`** `enum` · public · [DesignTokenSet.swift:61](../../../sources/Projects/UI/DesignSystem/Tokens/DesignTokenSet.swift#L61) · 채택: Error, Equatable  
  DesignTokenSet.validate()가 반환하는 검증 오류 enum. duplicateName·outOfRange·danglingReference case가 토큰 분류·이름과 상세 정보를 담는다.  
  단어: `Validation` 검증. 여기서는 토큰 집합의 이름 중복·값 범위·참조 무결성 검사 · `Error` 오류. 여기서는 검증에서 발견된 위반 항목
- **`EffectToken`** `struct` · public · [EffectToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/EffectToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  그림자 효과 토큰. name·kind·layers를 보유하고 sheetElevation·cardElevation 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Effect` 효과. 여기서는 그림자 같은 시각 효과 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`EffectToken.Kind`** `enum` · public · [EffectToken.swift:26](../../../sources/Projects/UI/DesignSystem/Tokens/EffectToken.swift#L26) · 채택: Sendable, Equatable  
  효과 종류(dropShadow, innerShadow)를 나타내는 enum.  
  단어(단일): `Kind` 종류. 여기서는 그림자가 바깥(drop)인지 안쪽(inner)인지의 구분
- **`EffectToken.Offset`** `struct` · public · [EffectToken.swift:31](../../../sources/Projects/UI/DesignSystem/Tokens/EffectToken.swift#L31) · 채택: Sendable, Equatable  
  그림자 레이어의 x·y 이동량(Double)을 담는 값 타입.  
  단어(단일): `Offset` 오프셋·이동량. 여기서는 그림자가 원래 위치에서 밀려나는 x·y 거리
- **`EffectToken.Layer`** `struct` · public · [EffectToken.swift:44](../../../sources/Projects/UI/DesignSystem/Tokens/EffectToken.swift#L44) · 채택: Sendable, Equatable  
  효과를 구성하는 그림자 한 겹. colorToken·offset·blur·spread를 보유한다.  
  단어(단일): `Layer` 층. 여기서는 여러 겹으로 쌓이는 그림자 중 한 겹
- **`FontFamilyToken`** `struct` · public · [FontFamilyToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/FontFamilyToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  폰트 패밀리 토큰. name·selectionRole·굵기별 postScriptNames를 보유하고 notoSans·plusJakartaSans 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Font` 글꼴. 여기서는 텍스트 렌더링에 쓰는 서체 · `Family` 계열. 여기서는 굵기 변형을 묶은 하나의 서체 집합 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`FontFamilyToken.FontSelectionRole`** `enum` · public · [FontFamilyToken.swift:22](../../../sources/Projects/UI/DesignSystem/Tokens/FontFamilyToken.swift#L22) · 채택: Sendable  
  폰트 패밀리가 선택되는 문자 조건(default, englishAlphabet)을 나타내는 enum. TextStyleResolver가 문자별 패밀리 선택에 사용한다.  
  단어: `Font` 글꼴. 여기서는 폰트 패밀리 · `Selection` 선택. 여기서는 문자에 따라 어떤 폰트 패밀리를 쓸지 고르는 것 · `Role` 역할. 여기서는 폰트 패밀리가 담당하는 문자 범위 분류
- **`GradientToken`** `struct` · public · [GradientToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/GradientToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  선형 그라데이션 토큰. name·start·end·stops를 보유하고 gradient1~3·backgroundGradient·가장자리/오버레이 스크림 등 정적 인스턴스를 제공한다.  
  단어: `Gradient` 그라데이션. 여기서는 여러 색 정지점을 잇는 선형 색 변화 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`GradientToken.UnitPointRatio`** `struct` · public · [GradientToken.swift:23](../../../sources/Projects/UI/DesignSystem/Tokens/GradientToken.swift#L23) · 채택: Sendable, Equatable  
  그라데이션 시작·끝 지점을 View 크기 대비 x·y 비율(Double)로 담는 값 타입.  
  단어: `UnitPoint` SwiftUI 타입 이름(외부 고정 명칭). View 내부의 정규화 좌표 · `Ratio` 비율. 여기서는 UnitPoint로 변환될 x·y 비율 값
- **`GradientToken.Stop`** `struct` · public · [GradientToken.swift:36](../../../sources/Projects/UI/DesignSystem/Tokens/GradientToken.swift#L36) · 채택: Sendable, Equatable  
  그라데이션 색 정지점. position(0~1)·hex·opacity를 보유한다.  
  단어(단일): `Stop` 정지점. 여기서는 그라데이션에서 특정 위치의 색을 지정하는 지점
- **`LayoutToken`** `enum` · public · [LayoutToken.swift:5](../../../sources/Projects/UI/DesignSystem/Tokens/LayoutToken.swift#L5)  
  margin(20)·gutter(12)·compactSpacing·tightSpacing·iconSpacing·카드 패딩 등 레이아웃 간격 CGFloat 상수를 담는 네임스페이스 enum.  
  단어: `Layout` 배치. 여기서는 화면 여백과 요소 간 간격 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`OpacityToken`** `struct` · public · [OpacityToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/OpacityToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  불투명도 토큰. name·percent를 보유하고 subtleSurface(5)부터 scrim(70)까지 정적 인스턴스와 all 목록을 제공한다.  
  단어: `Opacity` 불투명도. 여기서는 백분율로 정의한 투명도 값 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`TextStyleToken`** `struct` · public · [TextStyleToken.swift:3](../../../sources/Projects/UI/DesignSystem/Tokens/TextStyleToken.swift#L3) · 채택: Sendable, Equatable · 그래프 미수집(grep 보강)  
  텍스트 스타일 토큰. name·weight·size·lineHeightPercent·letterSpacing·paragraphSpacing·paragraphIndent를 보유하고 headline·subtitle·body·caption·tabItem·splashTitle 등 정적 인스턴스를 제공한다.  
  단어: `Text` 글자. 여기서는 화면에 표시되는 텍스트 · `Style` 양식. 여기서는 굵기·크기·행간 등 글자 표현 규칙 · `Token` 토큰. 여기서는 디자인 값을 이름 붙여 정의한 디자인 시스템 단위
- **`TextStyleToken.Weight`** `enum` · public · [TextStyleToken.swift:40](../../../sources/Projects/UI/DesignSystem/Tokens/TextStyleToken.swift#L40) · 채택: Sendable, Equatable, Hashable  
  텍스트 굵기(bold, medium, regular)를 나타내는 enum. FontFamilyToken.postScriptNames의 키와 SwiftUI Font.Weight 변환에 쓰인다.  
  단어(단일): `Weight` 무게·굵기. 여기서는 글꼴의 획 굵기 단계
