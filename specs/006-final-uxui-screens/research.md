# 조사: 최종 UXUI 화면 구현 기반

**대상 기능**: `006-final-uxui-screens` · **작성일**: 2026-08-19

**원천**: Figma `mCRt0ejmzI4EFW3UnC9Bzb` › 페이지 `📌 서비스 설계`(`86:761`), 저장소
`sources/docs/**`, `sources/Projects/**`, `.specify/memory/constitution.md`

이 문서는 명세가 계획 단계로 넘긴 미확정 항목을 해소한다. 각 항목은 결정, 근거, 검토한
대안 순으로 기록하며 Figma에서 직접 조회하지 못한 값은 확정값으로 기록하지 않는다.

## 근거 수준 정의

`005-figma-layout-audit`의 구분을 이어받아 이 기능에서도 같은 기호를 사용한다.

- `A`: 이 세션에서 Figma Plugin API로 직접 조회한 값
- `B`: 저장소 문서가 Figma 실측이라고 명시한 값
- `C`: 현재 구현에만 존재하는 회귀 기준선. Figma 확정값으로 보고하지 않는다
- `보류`: 조회하지 못했거나 판단 근거가 부족해 목표값을 확정하지 않은 항목

## R-01. 참조 화면은 `프로젝트`(프로젝트 목록) 화면 계열이다

**결정**: 참조 화면을 `프로젝트` 화면으로 정하고 화면 식별자를 `screen.project.list`로
둔다. 상태 변형은 목록(`1542:19495`), 메뉴 열림(`1621:30331`), 빈 상태(`1597:19052`),
삭제 모드(`1621:23431`, `1621:30561`), 삭제 확인 모달(`1621:24059`) 다섯 가지다.

**근거**:

- 공용 컴포넌트를 가장 많이 사용한다. 조회 결과 이 계열 프레임 하나에 `Toolbar - Top`,
  `ProjectList`, `BottomNavigationBar`, `top dim`, `bottom dim`, `Dropdown menu`,
  `Overlay`, `Sheet`, `Toolbar - Bottom`, `Button`, `Button - Liquid Glass - Icon`이
  함께 등장한다.
- 명세가 요구하는 상호작용 종류(선택, 펼침·접힘, 모드 전환, 확인)를 한 화면에서 모두
  실증할 수 있다. 메뉴 펼침 → 삭제 모드 진입 → 항목 삭제 → 모달 확인이 하나의 흐름이다.
- 화면이 의존하는 Use Case가 이미 문서로 정의되어 있다.
  `sources/docs/git-it-domain-usecases/fetch-learning-projects.md`와
  `delete-learning-project.md`가 입력·출력·제외 책임을 확정한다. Use Case 계약을 새로
  발명하지 않고 문서 근거 위에서 정의할 수 있다.
- 빈 상태가 별도 프레임으로 정의되어 있어 시나리오 2 수용 2를 검증할 수 있다.
- Lottie 재생에 의존하지 않는다. 빈 상태 일러스트는 128×128 정적 표현으로 대체할 수
  있고 저장소에 `ResourceImage.Asset.emptyState`가 이미 있다.

**검토한 대안**:

- `저장 (Empty)`·`Task4_06`: 사용 컴포넌트가 적고 `Filter Chip Set`이 미구현이라 기반
  실증 범위가 좁다.
- `홈화면 (완)`: `Card`(HomeProjectCard) 중심이라 리스트·시트·모달 계열을 실증하지
  못한다.
- `설정`: 미구현 리스트 컴포넌트 의존이 크고 대응 Use Case 문서가 없다.
- `스플래시`·`로딩(완)`: Lottie 재생 수단에 묶여 있어 R-10의 보류 항목을 참조 화면의
  차단 요인으로 끌어들인다.

## R-02. 여백·간격의 원천은 화면 프레임이 아니라 내부 컨테이너다

**결정**: 화면 여백·간격은 최상위 화면 프레임의 auto-layout 속성이 아니라 (1) 화면 안
컨테이너 프레임의 auto-layout 패딩·항목 간격과 (2) 형제 노드 사이의 절대 좌표 차이에서
확정한다. 계약에는 측정 대상 노드 식별자를 함께 남긴다.

**근거**: 조회한 기기 크기 프레임 66개 전부가 `layoutMode = NONE`이다. 예를 들어
`프로젝트`(`1542:19495`)는 좌표 배치이고, 실제 여백은 자식 컨테이너
`Frame 2147238565`의 `padding [8, 20, 0, 20]`, `itemSpacing 8`에서 나온다. 명세 FR-018은
"각 화면 프레임의 auto-layout 속성"을 원천으로 적었으나 파일 구조가 그렇지 않으므로 측정
경로를 한 단계 내려 잡아야 한다. 값의 원천이 Figma라는 점은 그대로다.

**검토한 대안**: 화면 프레임에 auto-layout을 부여해 측정하는 방법은 Figma 파일을
변경하므로 채택하지 않았다. 이 기능은 디자인 파일을 쓰지 않는다.

## R-03. 색 변수 25개는 저장소 토큰과 값이 모두 일치한다

**결정**: Figma 색 변수 25개 전부를 `ColorToken`과 이름·값·불투명도 기준으로 대조했고
불일치가 없음을 확인했다. 저장소에만 있는 토큰 4개(`Clear`, `White`, `Correct`,
`Incorrect`)는 삭제하지 않고 "변수 없는 저장소 전용 토큰"으로 분류해 근거 수준을 함께
기록한다.

**근거**: `figma.variables.getLocalVariableCollectionsAsync()` 조회 결과 컬렉션 1개,
COLOR 변수 25개, FLOAT 변수 0개다. 25개의 이름·hex·alpha는
`contracts/design-token-alignment.md`의 대조표에 그대로 옮겼으며 모두 일치했다.
`Correct`(`#3E85FF`)와 `Incorrect`(`#FF5656`)는 변수가 아니라 객관식 답안 컴포넌트의
직접 채우기에서 온 값이므로 변수 대조표에 등장하지 않는다.

**SC-014에 대한 해석**: "한쪽에만 존재하는 항목 0건"은 *Figma 변수 25개*를 기준으로
판정한다. Figma 변수 중 저장소에 없는 항목 0건, 값이 어긋난 항목 0건이 판정 대상이며,
저장소 전용 토큰 4개는 근거 수준과 사유를 기록한 상태로 유지한다. 근거 수준 없이 남은
저장소 전용 토큰이 있으면 실패로 판정한다.

**검토한 대안**: 저장소 전용 토큰 삭제는 `Correct`·`Incorrect`가 미구현 객관식 답안
컴포넌트의 확정 자산이므로 기각했다. 반대로 이 4개를 Figma 변수로 승격하는 것은 디자인
파일 쓰기이므로 이 기능의 범위 밖이다.

## R-04. 텍스트 스타일에는 실제 불일치가 있다

**결정**: 다음 세 항목을 텍스트 스타일 정합 대상으로 확정한다.

1. `TextStyleToken.caption2`의 크기 10pt는 Figma `Caption 2`(한국어) 12pt와 다르다.
   현재 값은 `ENG/Caption 2`(10pt)에 해당한다. 한국어·영문 스타일이 크기까지 갈리므로
   `FontFamilyToken.selectionRole`만으로는 표현할 수 없다.
2. Figma `ENG/Subtitle 3`의 행간은 120%로 한국어 `Subtitle 3`의 148%와 다르다. 저장소는
   단일 `subtitle3`(148%)만 가진다.
3. `TextStyleToken.tabItem`(10pt Regular)에 대응하는 Figma 텍스트 스타일이 없다.
   `BottomNavigationBar-item`의 라벨은 10pt이지만 텍스트 스타일이 아니라 직접 지정값이다.

세 항목은 계약에 불일치와 근거만 기록하고 이번 기능에서는 값을 수정하지 않는다. 참조
화면은 어느 항목도 사용하지 않으므로 구현·완료 조건에서 제외한다. 한국어·영문 토큰 구조와
`tabItem`의 승격 여부는 디자이너 확인, 영향 화면 목록과 회귀 기준을 갖춘 후속 명세가
소유한다.

**근거**: `figma.getLocalTextStylesAsync()`가 스타일 20종(한국어 10 + `ENG/` 10)을
반환했고 위 세 지점에서 저장소 정의와 값이 달랐다. 참조 화면은 `Body 2`(14pt),
`Subtitle 1`(22pt), `Subtitle 3`(16pt), `Body 1`(16pt), `Caption 1`(12pt)만 사용하므로
1·2번 항목이 참조 화면 검증을 막지 않는다.

**검토한 대안**: 저장소 값을 그대로 Figma 확정값으로 승격하는 방법은 명세의 경계 사례가
금지한 순환 검증이므로 기각했다.

## R-05. 신규 토큰은 반복 사용이 확인된 값만 승격한다

**결정**:

| 대상 | 결정 | 근거 |
| --- | --- | --- |
| 간격 8pt | `LayoutToken`에 승격한다 | 리스트 항목 간격, 텍스트 블록 간격, 하단 액션 버튼 간격 세 곳에서 같은 역할로 반복(`A`) |
| 간격 14·16·18·24·25pt | 승격하지 않는다 | 각각 한 컴포넌트 안에서만 의미를 가지므로 View 컨벤션 §5.1의 `Constant` |
| 완전 라운드(99·100·999) | 숫자 토큰을 만들지 않고 `Capsule()`로 표현한다 | 세 값 모두 "완전히 둥근 형태"를 뜻하며 숫자를 토큰화하면 의미 없는 상수가 남는다(`A`) |
| 컨트롤 높이 40·36pt | `ControlSizeToken`으로 승격하지 않는다 | `DesignTokenSet.validate()`가 44pt 미만을 오류로 판정하고, View 컨벤션 §4.3이 그런 값을 컴포넌트 로컬 상수로 두도록 이미 정한다 |
| 상·하단 dim 그라데이션 | 방향·정지점·불투명도를 포함해 `GradientToken`에 추가한다 | 참조 화면 6개가 `top dim`의 `문제풀이용` 변형과 `bottom dim`을 사용하며 `gradientTransform`까지 직접 조회(`A`) |
| 진행 바 트랙·채움 색 | `SemanticColorToken`에 승격한다 | `ProjectList`와 `학습세트 List-item` 두 컴포넌트가 같은 역할로 사용(`A`) |

**부수 변경**: `GradientToken.Stop`은 현재 `position`과 `hex`만 소유해 불투명도를 표현할
수 없다. dim 그라데이션은 같은 색의 불투명도 변화이므로 `Stop`에 기본값 있는 불투명도
프로퍼티를 더한다. 기존 세 그라데이션은 기본값으로 동작이 유지된다.

**방향 근거**: `top dim`의 참조 화면 변형 내부 Rectangle `1216:16441`은
`gradientTransform = [[0, -1, 1], [12.2160425, 0, -5.6080213]]`로 아래→위이며,
정지점은 0에서 alpha 0, 0.25에서 alpha 0.5다. `bottom dim` 내부 Rectangle
`1216:16399`는 `[[0, 1, 0], [-9.6313915, 0, 5.3156958]]`로 위→아래이며,
정지점은 0.7에서 alpha 0.6, 1에서 alpha 0다. 두 값은 Figma Plugin API에서 2026-08-19에
읽기 전용으로 조회했다.

**검토한 대안**: dim을 화면에서 `LinearGradient`로 직접 구성하는 방법은 FR-005의
"화면 코드에 색 값을 직접 적지 않는다"를 위반하므로 기각했다.

## R-06. 컴포넌트 교정 대상과 기준선 갱신을 구분했다

**결정**: `005`가 `C`로 남긴 항목을 이번 조회로 재판정했다. 값이 같으면 근거 수준만
`A`로 승격하고, 다르면 기준선을 Figma 값으로 갱신한 뒤 컴포넌트를 교정한다. 전체 표는
`contracts/component-correction.md`가 소유한다. 요약은 다음과 같다.

- **근거 수준만 승격(값 동일)**: `tag.radius`(8pt, 현재 `.small`),
  `header.default.row`(40pt), `header.large.spacing`(제목
  간격 16pt·아래 10pt), `bottomAction.insets`(좌우 20·위 4·아래 24), `tag.padding`(좌우
  10·위 3·아래 4), `projectRow.thumbnail`(60pt·간격 14pt), `action.large.height`(54pt),
  `action.radius`(12pt), `iconGlass.medium.surface`(40pt), `iconGlass.small.surface`(36pt),
  `layout.margin`(20pt), `tab.adaptive`의 아이콘 아래 4pt.
- **기준선 갱신 + 구현 교정**: `sheet.grabber`(48×4 → 58×4), `sheet.insets`(위 8·아래
  22 → 위 5·grabber 영역 총 16), `projectRow.insets`(전체 16 → 위 16·좌우 18·아래
  18), `action.small.height`(40pt는 Figma `MD`이며 `SM`은 36pt).
- **구조 불일치**: `ProjectRow`가 Figma `ProjectList`와 `학습세트 List-item` 두 컴포넌트의
  성격을 섞고 있다(R-07 참조).
- **보류**: `sheet.radius`(상단 모서리 값 미조회), `tab.*`의 바 형태(R-13), `homeCard.*`,
  `selectionCard.*`, `selectionList.spacing`(이번 조회 범위 밖).

**근거**: `Tag`(`1334:16349`), `Button`(`739:27351`),
`Button - Liquid Glass - Icon`(`783:34498`), `Sheet Modal`(`786:37977`),
`BottomNavigationBar`(`1303:15398`), `BottomNavigationBar-item`(`1305:14835`),
`학습세트 List-item`(`997:18550`), `ProjectList`(`1621:23606`)를 직접 조회했다.

**FR-029 준수**: 갱신 항목 4개 모두 Figma 노드 식별자와 조회값을 근거로 가진다.
`TagBadge`는 라이브 소스가 이미 `.small`(8pt)을 사용하므로 갱신 대상에서 제외하고 회귀
검증만 추가한다. 구현 편의를 이유로 기준선을 현재 값에 맞춘 항목은 없다.

## R-07. `ProjectRow`는 `ProjectList`에 대응하며 `학습세트 List-item`은 별도 컴포넌트다

**결정**: `sources/docs/ui-component-checklist.md`가 `학습세트 List-item` → `ProjectRow`로
적은 대응을 정정한다. `ProjectRow`의 실제 대응은 Figma `ProjectList`(`1621:23606`)이고,
`학습세트 List-item`(`997:18550`)은 아직 구현이 없는 별도 컴포넌트다. 체크리스트 문서
수정은 이 기능의 허용 수정 경로 밖이므로 계약에 정정 근거만 남기고 문서 갱신은
구현 단계 작업으로 배정한다.

**근거**: 두 Figma 컴포넌트의 계약이 다르다.

| 항목 | `ProjectList` | `학습세트 List-item` |
| --- | --- | --- |
| 크기 | 320×150(Default) / 320×94(Delete) | 320×130 |
| 내부 여백 | `[16, 18, 18, 18]` | `[20, 18, 20, 18]` |
| 항목 간격 | 12 | 25 |
| 배경 | `#242425`(Grey600) | `#141414`(Grey700) |
| 진행 표시 | 연속 바 6pt, 트랙 Grey500, 채움 Blue200 | 세그먼트 7칸, 높이 10pt, 반경 3pt, 간격 4pt |
| 부가 요소 | 태그 + 세트 제목 | 없음 |

저장소 `ProjectRow`는 연속 진행 바와 `TagBadge`를 가지므로 `ProjectList` 쪽 계약이다.
세그먼트 진행 표시는 이미 `ProgressSegments`가 소유하고 있고 반경 3pt가
`CornerRadiusToken.micro`와 일치한다.

**검토한 대안**: 두 Figma 컴포넌트를 하나의 저장소 컴포넌트로 합치는 방법은 UI 패키지
규칙의 재사용 판단 5개 질문 중 "같은 상태 값이 같은 표현 규칙을 의미하는가"를 만족하지
못하므로 기각했다.

## R-08. 이름이 같은 프레임의 다수는 상태 변형이며 "중복 배치" 2개는 헤더 변형이다

**결정**: 명세 부록이 중복 배치로 의심한 `저장 (Empty)`(`1597:21683`)와
`Task4_06`(`1597:21241`)은 중복이 아니라 **상단 툴바 유형 변형**이다. 화면 수에서
제외하지 않고 같은 화면의 상태 변형으로 집계한다.

**근거**: 두 쌍의 자식 구성이 동일하고 `Toolbar - Top`의 높이만 다르다.

| 화면 | Inline Title 변형 | Large Title 변형 |
| --- | --- | --- |
| `저장 (Empty)` | `1597:19247`(툴바 43pt, top dim 103pt) | `1597:21683`(툴바 99pt, top dim 152pt) |
| `Task4_06` | `1597:19231`(툴바 43pt) | `1597:21241`(툴바 99pt) |

같은 규칙이 참조 화면 계열에도 적용된다. `프로젝트`는 Inline Title(43pt),
`프로젝트 삭제`와 `프로젝트 삭제 모달`은 Large Title(99pt)을 사용한다. 스크롤 위치에
따른 헤더 축소·확장으로 해석한다.

**부수 확인**: `홈화면 (완)`(`1828:19279`)은 700×840이고 카드 6개와 `불러오기` 프레임을
가진 설명용 조합이다. 기기 크기 화면이 아니므로 화면 목록에서 제외한다.

## R-09. Use Case는 Domain의 Protocol로 정의하고 신규 target이 소유한다

**결정**: 참조 화면이 사용하는 Use Case 계약 두 개를 Domain 패키지의 신규 target
`DomainLearningProject`가 소유한다. 소스 폴더는 네이밍 가이드에 따라 패키지 접두어 없이
`LearningProject/`로 둔다.

```swift
public protocol FetchLearningProjects: Sendable {
    func callAsFunction(page: Int, size: Int) async throws -> LearningProjectPage
}

public protocol DeleteLearningProject: Sendable {
    func callAsFunction(_ id: LearningProjectID) async throws
}
```

**근거**:

- FR-015가 Protocol 정의를 요구하고 FR-016이 Feature의 생성자 주입을 요구한다. 기존
  `DomainAuthentication`의 Use Case는 구조체(`SignIn`, `RestoreSession`)이지만, 그것은
  Repository Protocol을 주입받는 구현체다. 이번 요구는 Feature가 Use Case 자체를 대역으로
  교체할 수 있어야 하므로 계약이 Protocol이어야 한다. `callAsFunction` 시그니처를 유지해
  호출부 표기는 기존과 같다.
- `DomainAuthentication`에 넣지 않는 이유는 학습 프로젝트가 인증과 다른 비즈니스 경계를
  가지기 때문이다. Domain 패키지 규칙의 "모든 내부 target은 도메인 모델·규칙·Use Case
  또는 외부 기능 계약을 소유해야 한다"를 새 target이 그대로 만족한다.
- 이름은 `sources/docs/git-it-domain-usecases/`의 문서 제목과 일치시켜 문서와 계약이
  같은 어휘를 쓰게 한다.

**검토한 대안**: `DomainLearning`처럼 더 넓은 이름은 학습 세트·문제 풀이 Use Case까지
한 target에 몰아넣게 되어 후속 기능의 경계를 미리 흐린다. 필요해지면 그때 target을
추가한다.

## R-10. Lottie 재생 수단은 도입하지 않는다

**결정**: 이 기능에서 Lottie 재생 의존성을 도입하지 않는다. 애니메이션이 정의된 화면은
정적 대체 표현으로 구현하고 계약에 미대응으로 기록한다. 참조 화면은 이 보류에 의존하지
않도록 선택했다(R-01).

**근거**: 명세의 범위 밖 절에 "Lottie 재생 수단의 도입 결정과 그에 따른 의존성 추가"가
명시되어 있다. 가정 절은 결정을 계획 단계로 넘긴다고 적었으므로, 계획의 결정은 "이번에는
도입하지 않는다"이며 도입 여부 자체는 후속 판단으로 남긴다. 참조 화면의 빈 상태
일러스트(128×128)는 `ResourceImage.Asset.emptyState`로 대체할 수 있다.

**자산 대응**: 조회한 화면과 자산 크기를 대조한 결과는 다음과 같다. 대응은 크기와 용도
추정에 근거하며 디자이너 확인 전까지 `보류`다.

| 자산 | 크기 | 대응 후보 화면 |
| --- | --- | --- |
| `Animation_Project_Empty.json` | 128×128 | `프로젝트 (Empty)`의 `Component 7`(128×128) |
| `Animation_Storage_Empty.json` | 128×128 | `저장 (Empty)`의 `Frame 2147238406` 안 일러스트 |
| `Animation_Set Creation_Loading.json` | 200×200 | `로딩(완)` |
| `Animation_General_Loading.json` | 100×100 | `Loading` 컴포넌트 세트(`1617:18762`) |
| `Animation_Complete.json` | 200×200 | `홈 - 생성 완료` |
| `Animation_Notification.json` | 120×120 | `Examples/Notifications` 계열 |

## R-11. Use Case Mock은 각 `FeatureTests`가 로컬로 소유한다

**결정**: `LearningProjectListFeature` 검증에 필요한 두 Use Case Mock을
`FeatureTests/LearningProjectList/Mocks/`에 둔다. 공유 Mock target이나 패키지는 신설하지
않고, 후속 Feature도 자기 테스트 target 안에 필요한 최소 Mock을 정의한다.

**근거**:

- `FeatureTests`는 이미 Feature와 Domain에 의존할 수 있으므로 production 의존 방향을
  추가하지 않고 Domain Protocol을 구현할 수 있다.
- Mock은 재사용 API가 아니라 특정 Reducer의 상태 전이와 호출 관찰에 맞춘 테스트 장치다.
  Feature별로 로컬화하면 다른 Feature의 테스트 구현 세부사항과 수명에 결합하지 않는다.
- 일부 호출 기록 코드가 중복될 수 있지만, 공유 target의 공개 표면·패키지 규칙·배포 링크를
  관리하는 비용보다 테스트 격리와 삭제 가능성을 우선한다.

**FR-025 검증 방법**: Mock 정의와 참조가 `FeatureTests/**` 안에만 있는지 정적 검사하고,
App·Composition·Feature production target의 소스와 의존성 및 앱 빌드 산출물에 Mock
심볼이나 별도 Mock 모듈이 없는지 확인한다.

**검토한 대안**: Domain의 `DomainTestDouble` 또는 최상위 `TestSupport` target은 여러
Feature의 테스트 구현을 한 공개 경계에 모으고 패키지 규칙·의존성 선언을 늘리므로 기각했다.
Composition 배치는 `FeatureTests → Composition` 역방향 의존을 만들므로 기각했다.

## R-12. 앱 실행 경로의 임시 구현은 Composition이 소유한다

**결정**: 표본 데이터를 반환하는 Use Case 임시 구현을 `Composition` target에 두고,
App은 조립 지점 한 곳에서 Feature에 주입한다. 임시 구현은 비즈니스 규칙을 갖지 않고
고정 표본만 반환한다.

**근거**: FR-024가 위치를 지정하고, Composition 패키지 규칙이 "실행 환경별
production/test/stub 구현 선택이 필요한 경우 Composition에서 결정해야 한다"를 이미
명시한다. 실제 구현으로 바꿀 때 수정 지점은 Composition의 조립 타입 한 곳이며 화면과
Feature 코드는 바뀌지 않는다(SC-018).

**교체 지점**: 구현 선택은
`sources/Projects/Composition/Composition/AppComposition.swift`의 `AppComposition.live()`
한 곳에 둔다. App은 이 반환값을 Feature initializer에 연결하기만 하므로 표본 구현을 실제
구현으로 바꿀 때 `GitItApp.swift`, `ContentView.swift` 또는 Feature 파일을 수정하지 않는다.

**주의**: Composition 규칙의 "비즈니스 규칙을 Adapter 내부에 구현해서는 안 된다"를
지키기 위해 임시 구현은 정렬·필터·검증을 수행하지 않는다. 삭제 요청은 표본 목록에서
해당 식별자를 제거한 결과만 반환한다.

## R-13. 탭 바는 목표 형태를 확정하지 않고 보류한다

**결정**: `TabShell`의 Figma 대응 여부를 이 계획에서 확정하지 않는다. 계약에 Figma
조회값과 현재 구현 방식을 함께 기록하고 근거 수준을 `보류`로 둔 뒤, 구현 단계에서 실제
렌더 결과를 측정해 (1) 시스템 `TabView` 유지 (2) 고정 크기 커스텀 바 구현 중 하나를
선택한다. 참조 화면의 확정 계약 항목에서는 탭 바를 제외한다.

**근거**: Figma `BottomNavigationBar`(`1303:15398`)는 360×92 컨테이너
(`padding [4, 20, 24, 20]`, `itemSpacing 10`) 안에 298×64 떠 있는 막대
(반경 999, 채우기 Blue300 10%)를 두고, 항목은 70×50(반경 99, 선택 시 Grey400 30%),
아이콘 24pt와 라벨 10pt 사이 간격 4pt다. 저장소 `TabShell`은 시스템 `TabView`를 사용해
막대의 크기·형태를 소유하지 않는다. `005`는 전체 `TabView` 높이와 안전 영역을 플랫폼
소유 값으로 제외했으므로, 형태까지 고정값으로 승격하려면 실제 렌더 측정이 먼저 필요하다.
측정 없이 커스텀 바 구현을 확정하면 플랫폼 소유 영역을 픽셀로 고정하지 말라는 명세의
경계 사례와 충돌할 수 있다.

## R-14. 검증 수단은 세 층으로 나눈다

**결정**:

| 검증 대상 | 위치 | 소유 패키지 단계 |
| --- | --- | --- |
| 토큰 값·정합·무결성 | `DesignSystemTests` | UI |
| 컴포넌트 고정 크기·터치 영역 | `UIComponentTests`, `UIComponentLayoutHarness` + `UIComponentUITests` | UI |
| Feature 상태 전이와 Mock 호출 | `FeatureTests`(신설) | Feature |
| 참조 화면의 여백·색·상호작용 렌더 | `ScreenLayoutHarness` + `ScreenLayoutUITests`(신설) | App |

**근거**:

- 화면 렌더 검증은 Feature와 Composition을 함께 조립해야 하므로 UI 프로젝트에 둘 수
  없다(UI → Feature 의존 금지). App 프로젝트는 규칙상 "실행 진입점과 Feature↔Composition
  조립"을 담당하므로 검증용 진입점이 그 책임 안에 있다.
- 검증 앱이 Composition의 임시 구현을 주입하고 Mock 정의는 `FeatureTests` 안에만 두므로
  앱 형태의 산출물에 Mock이 들어가지 않아 FR-025를 함께 만족한다.
- Feature 상태 전이 검증은 실행 환경에 의존하면 안 되므로(FR-022) 별도 단위 테스트
  target의 로컬 Mock을 주입한다.

**SC-005 검출력 확인 방법**: production 값을 수정하지 않는다. 레이아웃·색 판정 helper의
단위 테스트에서 계약값과 다른 측정값을 입력하고, 화면 이름·계약 ID·기대값·실제값이 담긴
실패 진단을 반환하는지 확인한다. 실제 화면 UI 테스트는 같은 helper에 캡처 측정값을 넣는다.

## R-15. Feature 소스 디렉터리와 Tuist 선언을 View 컨벤션에 맞춘다

**결정**: `Feature` target의 소스 디렉터리를 현재 `Feature/`에서 `Presentation/`으로
바꾸고 화면을 `Presentation/Screens/<화면>/`에 둔다. 프리뷰는
`Presentation/Screens/Previews/`, 여러 화면이 공유하는 보조 타입은
`Presentation/Shared/`에 둔다.

**근거**: View 컨벤션 §1이 적용 범위를 `sources/Projects/Feature/Presentation/**`로
명시하고, §3.4·§6.3·§8이 `Screens/`, `Presentation/Shared/Models/`,
`Screens/Previews/` 경로를 전제한다. 현재 경로는 규칙보다 먼저 만들어진 자리표시자
(`Projects/Feature/Feature/Feature.swift`)뿐이므로 지금 바꾸는 비용이 가장 작다.

**추가 선언**: `Feature` target에 `DomainLearningProject`, `UIComponent`, `DesignSystem`,
`ComposableArchitecture` 의존성을 더한다. TCA는 `sources/Tuist/Package.swift`에
`1.26.0` 이상으로 이미 선언되어 있고 `ComposableArchitecture`가 프레임워크 제품으로
설정되어 있어 추가 도입 결정이 필요 없다.

## R-16. 흐름 그룹은 다섯 개로 확정한다

**결정**: 명세 부록의 분류를 그대로 후속 기능 단위로 확정하되, 프레임 배정을 조회
결과로 정정했다. 전체 배정표는 `contracts/screen-inventory.md`가 소유한다.

| 그룹 | 프레임 | 시작 화면 | 비고 |
| --- | --- | --- | --- |
| G1 온보딩·인증 | 13 | `온보딩_애플로그인`(`779:33450`) | |
| G2 스플래시·학습 세트 생성 | 13 | `스플래시`(`986:13739`) | |
| G3 메인 탭 | 19 | `홈화면 (완)`(`1542:19610`) | 참조 화면 6프레임 포함, 006이 선구현 |
| G4 프로젝트 상세·등록 | 6 | `프로젝트 상세(완)`(`1342:19562`) | |
| G5 문제 풀이 | 12 | `Task3_03`(`813:15700`) | |
| 제외 | 2 | — | `Examples/Notifications` 2프레임 |

합계 63 + 제외 2 = 65로 명세 부록의 총계와 일치한다. 부록이 "메인 탭 17 + 중복 배치 2"로
나눈 것을 R-08에 따라 "메인 탭 19"로 통합했다.

**전환 근거**: 프로토타입으로 확인된 화면 간 전환 5개만 확정으로 기록하고 나머지는
추정으로 표기한다(FR-028). 그룹 사이 연결은 그룹 시작 화면 기준으로만 기록하고 화면별
진입 경로는 각 후속 기능이 확정한다.

## R-17. 계획 계약과 현재 완료 상태의 소유권을 분리한다

**결정**: `contracts/**`는 구현 위치, 계획 시 구현 대상과 검증 대상 상태를 보존한다.
동적인 현재 완료 상태는 계약에 복제하지 않고 `tasks.md`의 완료 표시와 실제 빌드·테스트
결과가 소유한다. 후속 기능의 고정 패키지 순서도 분할 계약에 복제하지 않고 실행 시점의
Constitution 원칙 7을 참조한다.

**근거**: 계약의 `현재 구현 상태`를 패키지 승인마다 수동 갱신하면 계획 산출물이 실행
상태와 쉽게 어긋나고, 읽기 전용 최종 검증 작업이 문서를 갱신할 수도 없다. 계획 기준과
검증 결과의 수명을 분리하면 문서는 안정적인 계약을 유지하고 완료 주장은 실제 검증 근거에
한정된다.

**검토한 대안**: Feature·App 승인마다 `/speckit-plan`을 다시 실행해 계약의 현재 상태를
갱신하는 방식을 검토했으나, 반복 동기화 비용과 누락 위험 때문에 채택하지 않았다.

## R-18. 참조 화면 typography는 정적 대응과 Dynamic Type으로 검증한다

**결정**: 참조 화면이 실제 사용하는 `subtitle1`, `subtitle2`, `subtitle3`, `body1`,
`body2`, `caption1`만 Figma 로컬 텍스트 스타일과 대응한다. 기존 `TextStyleTokenTests`로
크기·굵기·행간을 확인하고 컴포넌트 사용처를 정적으로 대조한다. App UI 검증은 최대
Dynamic Type의 잘림·겹침을 확인하되 glyph 픽셀 비교는 수행하지 않는다.

**근거**: 여섯 토큰은 `design-token-alignment.md`에서 Figma 스타일과 일치하며 참조 화면의
현재 컴포넌트 사용처에서 확인된다. glyph 픽셀은 렌더러·안티앨리어싱·폰트 환경에 민감해
토큰 계약보다 불안정하고, 텍스트 접근성 목표는 Dynamic Type 검증이 직접 판정한다.

**검토한 대안**: 화면 캡처의 glyph 픽셀을 Figma와 비교하는 방법은 환경 의존성과 오탐
비용이 커서 제외했다. 참조 화면이 사용하지 않는 `Caption 2`, `ENG/Subtitle 3` 불일치를
이번 기능에서 교정하는 방법도 범위 확장으로 제외했다.
