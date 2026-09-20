# 조사: UIComponent 정적 팩토리 제거

**기능**: [spec.md](./spec.md) | **브랜치**: `feature/ui-component-factory-removal`

**기준선**: `2b994f2` | **작성일**: 2026-09-20

## 1. 기준선 실측

명세의 가정 중 두 항목이 실제와 달라 여기에 정정 측정값을 남긴다. 수치는 기준선에서
팩토리 호출 표현을 직접 집계한 결과다.

### 1.1 팩토리 개수와 호출부 분포

| 컴포넌트 | 팩토리 | UI 호출 | Feature 호출 | App 호출 | 영향 파일(UI/Feature)<br>컴포넌트별 |
| --- | ---: | ---: | ---: | ---: | --- |
| `ActionButton` | 9 | 15 | 0 | 0 | 7 / 0 |
| `IconGlassButton` | 3 | 9 | 11 | 0 | 4 / 8 |
| `TagBadge` | 4 | 9 | 2 | 0 | 4 / 1 |
| `LabeledCard` | 2 | 7 | 3 | 0 | 3 / 2 |
| `ScreenEdgeScrim` | 2 | 4 | 0 | 0 | 2 / 0 |
| `StyledText` | 10 | 65 | 101 | 0 | 30 / 48 |
| **합계** | **30** | **109** | **117** | **0** | 41 / 51 (고유) |

**결정**: 전환 대상 호출부를 약 226곳으로 본다.

**근거**: 명세의 가정은 `StyledText` 약 110곳, 합계 약 170곳으로 적었으나, 그 측정이
`subtitle1`~`subtitle3`(합계 56곳)을 누락하고 존재하지 않는 `title*`·`label*` 패턴을 포함했다.
팩토리별 재집계 결과는 `subtitle1` 33, `body2` 45, `caption1` 25, `body1` 20, `subtitle3` 16,
`caption2` 10, `subtitle2` 7, `body3` 5, `headline1` 3, `headline2` 2로 `StyledText` 합계가
166곳이다.

**검토한 대안**: 명세의 수치를 그대로 쓰는 안은 작업량 추정을 33% 과소평가하므로 기각했다.
명세의 해당 가정은 `/speckit-clarify`로 정정할 대상이다.

### 1.2 App 패키지는 호출부가 없다

**결정**: 변경 패키지를 UI와 Feature 둘로 한정한다.

**근거**: 여섯 컴포넌트의 팩토리 호출이 App에 0건이다. 근거 문서가 "UI 공개 API 제거와
Feature·App 호출부 수정"을 한 단위로 묶으라고 했으나, App은 실제 대상이 없다.

**검토한 대안**: App을 단위에 포함하는 안은 변경 없는 패키지를 단위에 넣어 검증 범위만
넓히므로 기각했다.

## 2. 컴포넌트별 출발 상태가 세 갈래다

명세의 가정은 "네 컴포넌트는 이미 대응하는 변형 enum과 이를 받는 초기화 메서드를 갖고
있다"고 적었으나, `LabeledCard`는 해당하지 않는다.

| 그룹 | 컴포넌트 | 현재 상태 | 필요한 작업 |
| --- | --- | --- | --- |
| A | `ActionButton`, `IconGlassButton`, `TagBadge`, `StyledText` | `public init` + `public enum Style`(및 `Size`) 보유 | 팩토리 제거와 호출부 전환만 |
| B | `LabeledCard` | `public init` 없음, `Style`이 `private`, 생성 경로가 팩토리 2개뿐 | `Style`을 `public`으로 올리고 `public init` 추가 후 팩토리 제거 |
| C | `ScreenEdgeScrim` | `public init` 없음, 변형 타입 자체가 없음 | 변형 enum 신규 정의, `public init` 추가, 팩토리 제거 |

**결정**: 그룹 B를 그룹 C와 같은 "공개 계약 신설" 성격으로 다루고, 그룹 A와 분리된 작업
단위로 계획한다.

**근거**: 그룹 A는 기존 공개 계약을 유지한 채 중복만 제거하지만, B와 C는 새 공개 API를
추가한다. 검토 범위와 되돌리기 비용이 다르다.

**검토한 대안**: 명세의 가정대로 `LabeledCard`를 그룹 A로 취급하는 안은 실제 코드와 달라
계획대로 진행하면 작업 도중 설계를 다시 해야 하므로 기각했다.

## 3. ScreenEdgeScrim의 변형 축

**결정**: `ScreenEdgeScrim.Edge`를 `public enum`으로 컴포넌트에 중첩해 정의하고,
`public init(edge: Edge, height: CGFloat)`를 공개한다.

**근거**:
- [View 내부 선언 컨벤션 — View 내부 선언](../../docs/conventions/view-declarations/internal-declarations.md)이
  View가 소유하는 보조 선언을 소유 View 이름 아래 같은 파일에 두고, 타입 이름에 View 이름을
  반복하지 않도록 정한다(`ScreenEdgeScrimEdge`가 아니라 `ScreenEdgeScrim.Edge`).
- 두 변형의 차이는 `GradientToken`(`.topEdgeScrim` / `.bottomEdgeScrim`) 하나이며 호출부는
  높이만 따로 전달한다. 축 하나로 충분하다.
- 이름은 화면 가장자리라는 책임을 그대로 드러낸다.
  [네이밍 컨벤션](../../docs/conventions/naming.md)의 책임 우선 원칙에 맞는다.

**검토한 대안**:
- `Style`: 다른 다섯 컴포넌트와 이름을 맞추는 이점이 있으나, 이 변형은 시각 스타일이 아니라
  배치 위치다. 책임을 흐린다.
- `Position`·`Anchor`: `Edge`보다 넓은 의미라 상·하 두 case로 좁혀진 이 축을 과대 표현한다.

**남는 위험**: `SwiftUI.Edge`와 이름이 겹친다. 중첩 타입이므로 `ScreenEdgeScrim` 스코프
안에서만 가려지고, 현재 이 파일은 `SwiftUI.Edge`를 쓰지 않는다. 필요하면 `SwiftUI.Edge`로
정규화한다.

## 4. 초기화 메서드의 파라미터 레이블

**결정**: 기존 `public init`의 레이블을 그대로 유지한다. `StyledText(text:style:color:alignment:)`,
`ActionButton(title:style:size:isEnabled:action:)` 형태를 바꾸지 않는다.

**근거**:
- 명세의 FR-011이 변경 범위를 팩토리 제거와 컨벤션 문서로 한정한다. 레이블 변경은 그룹 A
  컴포넌트의 기존 공개 계약을 추가로 바꾸는 일이라 범위를 넘는다.
- [View 내부 선언 컨벤션 — `Style`](../../docs/conventions/view-declarations/style.md)의 예시가
  이미 `ActionButton(title:style:isEnabled:action:)` 형태를 정본으로 보여준다. 개정 대상이 아닌
  이 예시와 코드가 어긋나지 않는다.
- 전환을 기계적 치환으로 유지해 226곳의 검토 부담을 낮춘다.

**검토한 대안**: 첫 인자를 레이블 없이 받는 `StyledText(_ text: String, style:)`은 팩토리의
호출 감각(`StyledText.body2("x")`)에 가깝지만, 기존 `public init`을 쓰던 호출부까지 함께
바꿔야 하고 두 형태가 공존하는 중간 상태를 만든다. 별도 판단 대상으로 남긴다.

## 5. `ActionButton`의 초기화 메서드 두 개

**결정**: `init(title:...)`과 `init(styledText:...)` 두 오버로드를 모두 유지한다.

**근거**: 이 둘은 시각 변형이 아니라 **레이블 입력 형태**가 다르다. 명세의 SC-002가 요구하는
"공개 생성 경로가 초기화 메서드 하나뿐"은 정적 팩토리가 남지 않는 상태를 뜻하며, 입력 형태
오버로드는 변형 축 중복이 아니다. 팩토리 9개가 이 두 형태 × 변형 5종으로 늘어난 것이 제거
대상이다.

**검토한 대안**: 한쪽으로 통합하는 안은 호출부의 레이블 표현 능력을 줄이고 FR-005(표현 불변)를
위협하므로 기각했다.

## 6. 컨벤션 개정 단위와 FR-004c

**결정**: 컨벤션 문서 개정과 `screen-init.md` 문구 정리, `factory-criteria.md` 삭제를
**마지막 단독 작업 단위**로 둔다. FR-004c의 범위가 브랜치 수준이라는 점은 명세 정정으로
확정됐다(2026-09-20 명확화 세션).

**근거**:
- FR-010이 컴포넌트 단위로 나눠 각 단위마다 검증이 통과하는 상태를 남기도록 요구한다.
  컨벤션 개정을 각 컴포넌트 단위에 쪼개 넣으면 같은 문서를 여섯 번 고치게 된다.
- 문서는 컴파일 대상이 아니므로 순서가 SC-005(각 커밋 단독 compile)에 영향을 주지 않는다.
- 브랜치 tip에서 문서와 코드가 일치하므로, 병합되는 어떤 상태에도 불일치가 남지 않는다.

**검토한 대안**:
- 컨벤션 개정을 첫 단위로 두는 안: 이후 다섯 단위 동안 코드가 개정된 규칙을 위반한 상태가
  된다. 리팩터링 진행 중이라는 점은 같지만, 리뷰 시 위반과 미전환을 구분하기 어렵다.
- 마지막 코드 단위(`StyledText`)에 문서를 합치는 안: 166곳 전환과 문서 6건이 한 커밋에 들어가
  검토가 어려워진다.

**해소된 쟁점**: 초안의 FR-004c는 "같은 변경 단위"를 커밋으로 읽을 여지가 있었고, 그
경우 여섯 컴포넌트를 한 커밋으로 묶어야 해 FR-010과 정면으로 충돌했다. `/speckit-analyze`
교차 검증 후 FR-004c와 시나리오 4 수용 시나리오 3을 브랜치 수준으로 정정해 해소했다.

## 7. 해소하지 않은 기존 문서 불일치

**결정**: 이번 기능에서 고치지 않고 기록만 남긴다.

**내용**: [View 내부 선언 컨벤션 — 선언 소유 판단](../../docs/conventions/view-declarations/ownership.md)은
"View가 소유하는 선언은 예외 없이 `private`입니다"라고 규정하지만,
[View 내부 선언](../../docs/conventions/view-declarations/internal-declarations.md)의 표는
`enum Style`의 접근 수준을 "필요한 최소 수준"으로 적는다. 기준선의 `ActionButton`,
`IconGlassButton`, `TagBadge`는 이미 `public enum Style`을 갖고 있어 후자를 따른다.

**근거**: 이 불일치는 기준선에 이미 존재하며 이번 변경이 만들지 않는다. 다만 팩토리를 없애면
`public` 변형 enum이 모든 컴포넌트의 유일한 변형 선택 수단이 되어 의존도가 높아진다. 명세의
FR-011이 개정 대상을 FR-004a·FR-004d가 지정한 문서로 한정하므로 여기서 넓히지 않는다.

**검토한 대안**: `ownership.md`를 함께 고치는 안은 FR-011 범위를 넘고, 그룹 B(`LabeledCard`)의
`Style`을 `public`으로 올리는 작업의 정당성 판단까지 끌어들인다. 별도 판단 대상으로 남긴다.
