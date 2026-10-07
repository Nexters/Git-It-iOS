# 디자인 토큰 정합 계약

**대상 기능**: `006-final-uxui-screens` · **조사일**: 2026-08-19

**원천**: Figma 로컬 변수 컬렉션 `Variable collection`(색 변수 25개, FLOAT 변수 0개),
로컬 텍스트 스타일 20종, 저장소 `sources/Projects/UI/DesignSystem/Token/**`

이 문서는 FR-004, FR-005, FR-006, SC-005, SC-014의 산출물이다.

## 1. 색 변수 대조 (Figma 25개 전량)

`evidence`는 모두 `A`이며 값은 `figma.variables.getLocalVariableCollectionsAsync()`
결과를 hex와 alpha로 변환한 것이다.

| Figma 변수 | hex | alpha | 저장소 토큰 | 판정 |
| --- | --- | --- | --- | --- |
| `Blue/Blue500` | `#2F3853` | 1 | `ColorToken.blue500` | 일치 |
| `Blue/Blue400` | `#506381` | 1 | `ColorToken.blue400` | 일치 |
| `Blue/Blue300` | `#7E94BB` | 1 | `ColorToken.blue300` | 일치 |
| `Blue/Blue200` | `#8BB5EF` | 1 | `ColorToken.blue200` | 일치 |
| `Blue/Blue100` | `#B9D6FE` | 1 | `ColorToken.blue100` | 일치 |
| `Purple/Purple500` | `#3B3749` | 1 | `ColorToken.purple500` | 일치 |
| `Purple/Purple400` | `#585B6F` | 1 | `ColorToken.purple400` | 일치 |
| `Purple/Purple300` | `#898DA6` | 1 | `ColorToken.purple300` | 일치 |
| `Purple/Purple200` | `#A4A9C7` | 1 | `ColorToken.purple200` | 일치 |
| `Purple/Purple100` | `#BDC2DC` | 1 | `ColorToken.purple100` | 일치 |
| `Grey/Grey700` | `#141414` | 1 | `ColorToken.grey700` | 일치 |
| `Grey/Grey600` | `#242425` | 1 | `ColorToken.grey600` | 일치 |
| `Grey/Grey500` | `#3B3B3B` | 1 | `ColorToken.grey500` | 일치 |
| `Grey/Grey400` | `#919191` | 1 | `ColorToken.grey400` | 일치 |
| `Grey/Grey300` | `#BCBCBC` | 1 | `ColorToken.grey300` | 일치 |
| `Grey/Grey200` | `#ECECEC` | 1 | `ColorToken.grey200` | 일치 |
| `Grey/Grey100` | `#FFFFFF` | 1 | `ColorToken.grey100` | 일치 |
| `Opacity/white 5` | `#FFFFFF` | 0.05 | `ColorToken.white5` | 일치 |
| `Opacity/white 15` | `#FFFFFF` | 0.15 | `ColorToken.white15` | 일치 |
| `Opacity/white 30` | `#FFFFFF` | 0.3 | `ColorToken.white30` | 일치 |
| `Opacity/white 70` | `#FFFFFF` | 0.7 | `ColorToken.white70` | 일치 |
| `Opacity/Black 70` | `#000000` | 0.7 | `ColorToken.black70` | 일치 |
| `State/Error` | `#FF3721` | 1 | `ColorToken.error` | 일치 |
| `State/Caution` | `#ECBD23` | 1 | `ColorToken.caution` | 일치 |
| `State/Success` | `#249900` | 1 | `ColorToken.success` | 일치 |

**결과**: 이름이 어긋난 항목 0건, 값이 어긋난 항목 0건, Figma에만 있는 항목 0건.

## 2. 저장소 전용 색 토큰

Figma 변수 컬렉션에 없는 저장소 토큰이다. 삭제하지 않고 근거 수준과 사유를 유지한다.

| 저장소 토큰 | hex | alpha | 근거 | 사유 |
| --- | --- | --- | --- | --- |
| `ColorToken.clear` | `#000000` | 0 | `C` | 투명 표면을 표현하기 위한 구현 전용 값. 디자인 변수 대응이 없다 |
| `ColorToken.white` | `#FFFFFF` | 1 | `C` | `Grey100`과 값이 같은 별칭. 통합 여부는 별도 판단이 필요하다 |
| `ColorToken.correct` | `#3E85FF` | 1 | `보류` | 객관식 답안 컴포넌트의 직접 채우기에서 온 값. Figma 노드 조회로 확정해야 한다 |
| `ColorToken.incorrect` | `#FF5656` | 1 | `보류` | 같은 사유 |

**SC-014 판정 기준**: Figma 변수 25개 기준으로 이름·값이 어긋나거나 한쪽에만 존재하는
항목이 0건이면 통과한다. 저장소 전용 토큰은 위 표처럼 근거 수준과 사유가 기록된 상태를
유지해야 하며, 근거 없이 남은 항목이 있으면 실패로 판정한다.

**후속 작업**: `correct`·`incorrect`는 G5(문제 풀이) 기능이 `객관식문항-답안`
(`1369:17327`)을 조회해 근거 수준을 `A`로 승격한다.

## 3. 텍스트 스타일 대조

| Figma 스타일 | 크기 | 굵기 | 행간 | 저장소 | 판정 |
| --- | --- | --- | --- | --- | --- |
| `Headline 1` | 30 | Bold | 124% | `headline1` | 일치 |
| `Headline 2` | 28 | Bold | 130% | `headline2` | 일치 |
| `Subtitle 1` | 22 | Bold | 148% | `subtitle1` | 일치 |
| `Subtitle 2` | 18 | Bold | 148% | `subtitle2` | 일치 |
| `Subtitle 3` | 16 | Bold | 148% | `subtitle3` | 일치 |
| `Body 1` | 16 | Medium | 150% | `body1` | 일치 |
| `Body 2` | 14 | Medium | 150% | `body2` | 일치 |
| `Body 3` | 12 | Medium | 150% | `body3` | 일치 |
| `Caption 1` | 12 | Regular | 150% | `caption1` | 일치 |
| `Caption 2` | **12** | Medium | 150% | `caption2`(**10**) | **불일치** |
| `ENG/Headline 1` | 30 | Bold | 124% | `headline1` + `plusJakartaSans` | 일치 |
| `ENG/Headline 2` | 28 | Bold | 130% | 〃 | 일치 |
| `ENG/Subtitle 1` | 22 | Bold | 148% | 〃 | 일치 |
| `ENG/Subtitle 2` | 18 | Bold | 148% | 〃 | 일치 |
| `ENG/Subtitle 3` | 16 | Bold | **120%** | `subtitle3`(148%) | **불일치** |
| `ENG/Body 1` | 16 | Medium | 150% | 〃 | 일치 |
| `ENG/Body 2` | 14 | Medium | 150% | 〃 | 일치 |
| `ENG/Body 3` | 12 | Medium | 150% | 〃 | 일치 |
| `ENG/Caption 1` | 12 | Regular | 150% | 〃 | 일치 |
| `ENG/Caption 2` | **10** | Medium | 150% | `caption2`(10) | 값은 일치하나 한국어 변형과 크기가 갈린다 |

**폰트 계열**: Figma는 `Noto Sans`와 `Plus Jakarta Sans`를 쓰고 저장소
`FontFamilyToken`이 같은 이름과 PostScript 이름 대응을 소유한다. 일치한다.

**저장소 전용 스타일**

| 저장소 | 값 | 근거 | 사유 |
| --- | --- | --- | --- |
| `TextStyleToken.tabItem` | 10pt Regular 150% | `C` | Figma `BottomNavigationBar-item` 라벨은 10pt이지만 텍스트 스타일이 아닌 직접 지정이다 |

**불일치 처리**: `Caption 2`(한국어 12pt)와 `ENG/Subtitle 3`(120%)은 한국어·영문에서
크기와 행간이 갈리므로 현재의 `TextStyleToken` + `FontFamilyToken.selectionRole` 구조로는
표현되지 않는다. 참조 화면은 두 항목을 사용하지 않으므로 이번 기능은 값을 변경하지 않고
근거만 보존한다. 디자이너 확인, 영향 화면 목록과 회귀 기준을 갖춘 후속 명세에서 구조와
`tabItem`의 승격 여부를 결정한다.

### 참조 화면 사용 스타일

`screen.project.list`는 일치 판정된 `subtitle1`, `subtitle2`, `subtitle3`, `body1`, `body2`,
`caption1`만 사용한다. 참조 화면 계약은 화면 역할과 사용 위치를 열거하고, 기존
`TextStyleTokenTests`가 각 토큰의 크기·굵기·행간을 검증한다. 컴포넌트 사용처는 정적으로
대조하되 glyph 픽셀 비교는 수행하지 않으며, 최대 Dynamic Type의 잘림·겹침은 App UI
검증이 담당한다(SC-023).

## 4. 신규 토큰

| 토큰 | 값 | 근거 | 승격 사유 |
| --- | --- | --- | --- |
| `LayoutToken` 8pt 항목 | 8 | `A` | `프로젝트` 목록 항목 간격, `Text Set` 텍스트 간격, `Toolbar - Bottom` 버튼 간격 세 곳에서 같은 역할 |
| `SemanticColorToken` 진행 바 트랙 | `grey500` | `A` | `ProjectList`(연속형)와 `학습세트 List-item`(세그먼트형)이 같은 역할로 사용 |
| `SemanticColorToken` 진행 바 채움 | `blue200` | `A` | `ProjectList`(연속형, `ContinuousProgressBar` → `SemanticColorToken.progressFill`)만 해당. **정정(2026-09-03, Task 3 문제 풀이 조사)**: `학습세트 List-item`의 세그먼트 채움은 `blue200`이 아니라 `blue100`이다 — `프로젝트 상세(완)`(`1342:19562`) 학습세트 List-item 인스턴스 5개의 `Progress Bar` 세그먼트 fill을 재조회해 확인(`A`, 완료 세그먼트 `#B9D6FE`=blue100, 미완료 `#3B3B3B`=grey500). 이 행이 두 컴포넌트를 "같은 근거"로 묶은 것은 세그먼트 채움에는 적용되지 않는다. 코드는 이미 `ProgressSegments.swift`가 `.blue100`을 직접 사용해 정확히 구현했으므로 production 수정은 불필요하다. `LearningSetRow.swift`가 `ProgressSegments`가 아닌 `ContinuousProgressBar`를 쓰는 구조 격차는 별개 사안이며 이 문서의 범위 밖이다 |
| `GradientToken` 상단 dim | 아래→위, `#141414` 정지점 2개 | `A` | 참조 화면 6개가 `top dim`의 `문제풀이용` 변형을 사용 |
| `GradientToken` 하단 dim | 위→아래, `#141414` 정지점 2개 | `A` | 참조 화면 6개가 `bottom dim`을 사용 |

**dim 정지점 실측값**

| 대상 | 내부 노드 | 방향 | 정지점 | 색 | 불투명도 |
| --- | --- | --- | --- | --- | --- |
| `top dim` `문제풀이용`(`1216:16439`) | `1216:16441` | 아래→위 | 0 | `#141414` | 0 |
| 〃 | 〃 | 〃 | 0.25 | `#141414` | 0.5 |
| `bottom dim`(`1216:16402`) | `1216:16399` | 위→아래 | 0.7 | `#141414` | 0.6 |
| 〃 | 〃 | 〃 | 1 | `#141414` | 0 |

**방향 실측값**: 상단 내부 노드의 `gradientTransform`은
`[[0, -1, 1], [12.2160425, 0, -5.6080213]]`, 하단 내부 노드는
`[[0, 1, 0], [-9.6313915, 0, 5.3156958]]`다. Figma의 기본 좌→우 행렬과
위→아래 행렬 정의에 따라 각각 아래→위와 위→아래로 판정한다. 참조 화면 노드 6개를
재조회해 모두 같은 상단 변형과 하단 컴포넌트를 사용하는 것도 확인했다.

**부수 변경**: `GradientToken.Stop`은 `position`과 `hex`만 소유해 불투명도를 표현할 수
없다. 기본값 1을 갖는 불투명도 프로퍼티를 추가한다. 기존 `gradient1`~`gradient3`은
기본값으로 동작이 유지된다.

## 5. 승격하지 않는 값

| 값 | 결정 | 사유 |
| --- | --- | --- |
| 14, 16, 18, 24, 25pt 간격 | 컴포넌트 로컬 `Constant` | 각각 한 컴포넌트 안에서만 의미를 가진다(View 컨벤션 §5.1) |
| 완전 라운드 99·100·999 | `Capsule()`로 표현 | 세 값 모두 "완전히 둥근 형태"를 뜻하며 숫자 토큰은 의미 없는 상수를 남긴다 |
| 컨트롤 높이 40·36pt | 컴포넌트 로컬 `Constant` + 44pt 터치 영역 | `DesignTokenSet.validate()`가 44pt 미만 `ControlSizeToken`을 오류로 판정한다 |

## 6. 검증 기준선 영향

| 기존 검증 | 영향 | 조치 |
| --- | --- | --- |
| `LayoutTokenTests`의 `레이아웃 토큰 총 개수는 2개다` | 8pt 토큰 추가로 실패 | 개수를 갱신하고 새 토큰 값 검증을 추가한다 |
| `DesignTokenSetIntegrityTests` | 신규 토큰의 중복 이름·참조 무결성 검사 대상 확대 | 통과 유지를 확인한다 |
| `GradientTokenTests` | `Stop` 프로퍼티 추가 | 기존 기대값이 유지되는지 확인한다 |

SC-006은 위 갱신 항목을 제외한 나머지 검증이 적용 전후 동일하게 통과하는지로 판정한다.

## 완료 조건

- 1절 25행 전부가 `일치`다.
- 2절과 3절의 저장소 전용·불일치 항목이 근거 수준과 사유를 가진다.
- 참조 화면의 텍스트 역할 100%가 3절의 일치 스타일과 `TextStyleToken`에 대응하고 기존
  토큰 단위 테스트 및 사용처 정적 검토로 확인된다(SC-023).
- 4절 신규 토큰이 `DesignSystem`에 정의되고 값 검증이 존재한다.
- production 값을 수정하지 않고 색 assertion helper에 계약과 다른 측정값을 주입하면 계약
  ID·기대값·실제값을 포함해 실패하고, 올바른 측정값은 통과한다(SC-005).
