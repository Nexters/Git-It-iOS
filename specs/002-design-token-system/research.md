# 조사 노트: 디자인 토큰 시스템

**입력**: [spec.md](./spec.md), [architecture.md](../../docs/architecture.md), [package-rules/ui.md](../../docs/package-rules/ui.md)

이 문서는 Technical Context를 채우기 위해 확인한 사실과, 명세가 "적용 수단에 위임"하기로
결정한 항목의 구체적 구현 방식을 다룹니다. 명세 자체의 모호성은 `/speckit-clarify`에서
모두 해소되었으므로, 여기서는 프로젝트 기존 관례 확인과 위임된 항목의 구체화만 다룹니다.

## 1. 프로젝트 기존 관례 확인

- **Decision**: Swift tools-version 6.0(`sources/Tuist/Package.swift`), 타겟 `SWIFT_VERSION`
  "5.0"(언어 모드), 배포 타겟 iOS 26.0(`Target+Module.swift`)을 그대로 따른다.
- **Rationale**: 리포지토리 전체가 이미 이 값으로 통일되어 있고, 이 기능만 다른 버전을 쓸
  이유가 없다.
- **Alternatives considered**: 없음(기존 설정을 바꿀 근거가 없음).

- **Decision**: 테스트 프레임워크는 Swift Testing(`import Testing`, `@Suite`, `@Test`,
  `#expect`)을 사용한다. `sources/Projects/App/Tests/GitItCompilationTests.swift`가 이미
  이 관례를 따른다.
- **Rationale**: 프로젝트 유일한 기존 테스트 예시가 Swift Testing이며, XCTest와 혼용할
  이유가 없다.
- **Alternatives considered**: XCTest(기존 관례와 불일치로 기각).

- **Decision**: UI 패키지(`sources/Projects/UI`)에는 아직 단위테스트 타겟이 없다. 이번
  기능은 `DesignSystem` 타겟 옆에 `DesignSystemTests`(product: `.unitTests`) 타겟을
  신설한다. UI 프로젝트는 `ProjectName.swift`의 기본 자동 공유 스킴을 유지하므로,
  생성된 `DesignSystem` 스킴이 `DesignSystemTests`의 `TestableReference`를 포함하고
  `tools/githooks/project-build`가 이를 기준으로 build/test를 판별한다.
- **Rationale**: 사용자 스토리 3("화면 없이 검증")은 시뮬레이터·렌더링 없는 단위 테스트를
  요구하며, pre-commit 훅이 스킴 존재만으로 test 여부를 판별하므로 신규 스킴 등록이
  필요하다.
- **Alternatives considered**: 최상위 `GitItTests`에 검증 코드를 추가(패키지 경계를 넘는
  배치로 원칙 1·7 위반 소지가 있어 기각). UI 패키지 전체를 대상으로 하나의 통합 테스트
  타겟만 두는 방안은 향후 `UIComponent`가 뷰 테스트를 추가할 때 충돌하므로, 이번 기능은
  `DesignSystem` 전용 테스트 타겟만 신설한다.

- **Decision**: `UIModuleName.swift`에서 `Noto Sans KR`와 `Plus Jakarta Sans`의
  `Regular`·`Medium`·`Bold` 정적 폰트 6개를 `ResourceFileElements`로 코드 생성해
  `DesignSystem` 리소스에 등록한다.
- **Rationale**: 런타임 글꼴 등록과 실제 토큰 굵기가 이 여섯 파일만 사용한다. 폰트
  디렉터리 전체 glob은 미사용 가변 글꼴·이탤릭·추가 굵기까지 번들에 포함하므로 피한다.
- **Alternatives considered**: `Font/**/*.ttf` glob(미사용 파일까지 포함하므로 기각).

## 2. 값 모델의 프레임워크 비의존성 (FR-001, FR-017)

- **Decision**: `ColorToken`의 색상 값은 `SwiftUI.Color`가 아닌 프로젝트 소유의
  `RGBAComponents`(0~1 범위의 `red`, `green`, `blue`, `alpha` `Double`) 구조체로 표현한다.
  `DesignSystem` 타겟 내부를 `Token/`(값 모델, `Foundation`만 import)과 `Application/`
  (SwiftUI 적용 수단, `SwiftUI` import 허용)로 폴더 분리해 의존 방향을 코드 조직으로
  드러낸다.
- **Rationale**: `SwiftUI.Color`를 값 모델에 쓰면 FR-001("UI 프레임워크에 의존하지 않는
  순수 데이터")을 직접 위반한다. RGBA 컴포넌트는 동등성 비교가 결정적이라 사용자 스토리
  3의 화면 없는 검증(값 대조)에도 적합하다.
- **Alternatives considered**: 16진수 문자열 저장(비교는 가능하나 불투명도 합성 시 매번
  파싱 필요해 기각). `CGColor` 사용(플랫폼 그래픽 프레임워크 의존이라 FR-001 위반).

## 3. 토큰 이름 ↔ Swift 식별자 매핑 (FR-002)

- **Decision**: 디자인 문서 표기의 공백을 제거하고 lowerCamelCase로 변환해 Swift `case`
  이름을 만든다(예: `Blue500` → `blue500`, `Subtitle 2` → `subtitle2`, `Gradient 1` →
  `gradient1`, `white 15` → `white15`, `Black 70` → `black70`, `Headline 1` →
  `headline1`). 각 토큰 열거형은 표시용 원본 이름을 `displayName: String` 상수로 함께
  보관해, 검증 코드가 Swift 식별자가 아닌 디자인 문서 표기 그대로 대조할 수 있게 한다.
- **Rationale**: Swift 식별자는 공백을 허용하지 않으므로 결정적이고 되돌릴 수 있는 규칙이
  필요하다. `displayName`을 별도로 보관하면 FR-002의 "문서 표기와 1:1 대응"을 이름 변환
  손실 없이 검증할 수 있다.
- **Alternatives considered**: 백틱 이스케이프로 공백 포함 식별자 사용(예: `` `Subtitle 2` ``,
  Swift 문법상 가능하나 호출부 가독성이 떨어지고 프로젝트 관례에 없어 기각).

## 4. 행간 백분율 → 실제 행 높이 변환 (FR-011)

명세는 "변환 규칙은 적용 수단 한 곳에만 존재해야 한다"까지만 결정했고, 구체적 공식은
계획 단계로 위임했습니다. 여기서 그 공식을 확정합니다.

- **Decision**: 목표 행 높이(pt) = 폰트 크기(pt) × 행간 백분율(예: 16pt, 150% → 24pt)로
  계산한다. SwiftUI `Text`에는 `.lineSpacing(목표 행 높이 - 폰트 크기)`를 적용하고, 첫 줄
  상단 여백을 보정하기 위해 `.padding(.vertical, (목표 행 높이 - 폰트 크기) / 2)`를 함께
  적용한다. 반올림은 수행하지 않고 `Double` 값을 그대로 사용한다(SC-005가 ±1 오차를
  허용하며, 서브포인트 값을 미리 반올림하면 오히려 오차가 커진다). 이 계산은
  `Application/` 폴더의 단일 파일(`TextStyleApplying.swift`)에서만 수행한다.
- **Rationale**: SwiftUI는 배수 기반 줄간격 API를 제공하지 않고 `lineSpacing(_:)`(기준선
  사이 추가 간격)만 제공하므로, "목표 행 높이 - 폰트 크기"가 추가해야 할 간격의 가장
  직접적인 근사치다. 상하 패딩 보정은 텍스트 블록 전체 높이가 목표 행 높이의 배수에
  가깝게 유지되도록 한다.
- **Alternatives considered**: `UIFont`의 실제 ascender/descender/leading을 조회해 정밀
  보정(플랫폼 API가 필요해 값 모델과 적용 수단의 경계를 흐릴 위험, 그리고 SC-005가 이미
  ±1 오차를 허용해 과설계로 판단해 기각).

## 5. 그라데이션 좌표 → SwiftUI 매핑 (FR-008a)

- **Decision**: `GradientToken`의 시작점·끝점(0~1 좌표비율)은 SwiftUI `UnitPoint(x:y:)`와
  값 범위·의미가 동일하므로 변환 없이 `UnitPoint(x: point.x, y: point.y)`로 그대로
  대응한다.
- **Rationale**: 별도 변환 로직이 필요 없어 FR-017("값 모델이 적용 수단에 의존해서는 안
  된다")을 지키면서도 적용 코드가 가장 단순해진다.
- **Alternatives considered**: 없음(직접 대응 가능한 기존 API 존재).

## 6. 글꼴 미탑재 시 대체 (FR-012)

- **Decision**: `Application/` 계층에서 `UIFont(name: familyName, size:)`(또는
  `CTFontCreateWithName` 존재 확인)로 지정 글꼴 사용 가능 여부를 먼저 확인하고, 사용
  불가 시 `Font.system(size:weight:)`로 대체한다. 크기·굵기·행간 값은 토큰 값을 그대로
  유지한 채 글꼴 이름만 교체한다.
- **Rationale**: `Font.custom(_:size:)`는 지정한 이름의 글꼴이 없어도 조용히 시스템 기본
  글꼴로 대체되지 않는 경우가 있어(텍스트가 사라지는 사례) 사전 확인이 필요하다.
- **Alternatives considered**: 항상 `Font.custom` 사용 후 결과를 신뢰(FR-012의 "텍스트가
  사라지지 않도록" 요구를 보장하지 못해 기각).

## 7. 문자 단위 스크립트 판별 (FR-010)

- **Decision**: 문자 단위로 한글 완성형(`U+AC00`–`U+D7A3`)과 한글 자모(`U+1100`–
  `U+11FF`, `U+3130`–`U+318F`)는 `Noto Sans`, ASCII 영문 알파벳(`U+0041`–`U+005A`,
  `U+0061`–`U+007A`)은 `Plus Jakarta Sans`로 분류한다. 어느 분류에도 속하지 않는
  기본 문자(공백·구두점·숫자·그 외 스크립트)는 `Noto Sans`로 적용한다. 판별 로직은 값
  모델이 아닌 `Application/` 계층에 둔다.
- **Rationale**: 기본 문자는 `Noto Sans`로 처리한다는 사용자 결정에 따라, 명시적으로
  영문 알파벳으로 분류된 문자에만 `Plus Jakarta Sans`를 선택해야 한다. 유니코드 범위를
  명시하면 문자별 선택 결과가 결정적이다.
- **Alternatives considered**: 한글 외 모든 문자를 `Plus Jakarta Sans`로 적용(기본 문자를
  `Noto Sans`로 처리하는 결정과 불일치해 기각). `CharacterSet.koreanCharacters`같은 시스템
  제공 집합은 존재하지 않으며, 언어 감지 API(`NLLanguageRecognizer`)는 문장 단위
  추정이라 문자 단위 요구와 맞지 않아 기각.

## 8. 토큰 집합의 교체 가능성과 단일 활성 인스턴스 (FR-020, FR-022)

- **Decision**: 모든 원시 토큰 값을 값 타입 `DesignTokenSet` 구조체 하나에 담고, 이
  구조체를 담는 전역 접근점은 `DesignTokenSet.current` 정적 상수 하나만 노출한다(런타임
  다중 선택 금지). 값을 교체하려면 `DesignTokenSet`을 구성하는 리터럴 값 파일을 고쳐
  다시 빌드해 배포한다.
- **Rationale**: FR-020은 "교체 가능한 하나의 집합"을, FR-022는 "활성 집합은 항상
  하나"를 요구한다. 값 타입 구조체 하나 + 단일 정적 상수 조합이 두 요구를 동시에
  만족하면서 가장 단순하다.
- **Alternatives considered**: 프로토콜 기반 다중 구현체 + 런타임 주입(다크 모드 등 향후
  다중 테마 확장에는 유리하지만, 현재 범위 밖(FR-022)이며 원칙 없는 확장 지점을
  추가하는 과설계로 기각).

## 미해결 항목

없음. Technical Context의 모든 항목이 위 결정 또는 §1의 기존 관례로 확정되었습니다.
