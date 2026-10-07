# 내부 Swift 타입 인벤토리 (네이밍 점검용)

**작성일**: 2026-09-19

**목적**: 네이밍 컨벤션 점검을 위해 프로젝트가 소유한 모든 Swift 타입을 패키지·관심사별로 나열하고, 각 타입의 책임을 한 줄로 설명하며, 이름을 이루는 단어를 분해해 정의한다. 판정이나 rename 제안은 담지 않는다.

## 범위와 수집 방법

- 대상: `sources/Projects/<패키지>/` 아래 production 소스의 `struct`·`enum`·`class`·`actor`·`protocol`·`typealias` 선언(중첩 타입 포함)과 `sources/Tuist/ProjectDescriptionHelpers`의 선언.
- 제외: 테스트 target(`Tests/`), Tuist 생성물(`Derived/`), 빌드 산출물(`DerivedData/`, `build/`), 외부 의존성(`Tuist/.build`), `#Preview`만 있는 파일, `Project.swift` manifest.
- 수집: code-review-graph 지식 그래프를 전체 재빌드한 뒤 `Class` 노드(swift_kind ≠ extension)를 추출했다. 그래프가 수집하지 못한 선언(속성 줄이 앞에 붙은 타입 47개)과 `typealias` 14개는 grep으로 보강했고, 해당 항목은 목록에 "그래프 미수집" 또는 typealias로 표시했다.
- 작성: 27개 청크로 나누어 에이전트가 소스를 직접 읽고 설명과 단어 분해를 작성했다.
- 검증: 스크립트가 모든 항목을 소스 선언과 대조해 누락·중복, 선언 종류, 이름, 접근 수준, 중첩 경로, 단어 분해 결과를 이어 붙였을 때 원래 이름이 되는지를 확인했다. 설명 문장은 표본 대조로만 확인했으며, 전 항목에 대한 독립 재검토는 수행하지 않았다.
- 접근 수준은 선언에 적힌 수식어가 아니라 둘러싼 타입까지 고려한 실효 수준이다. 예를 들어 `fileprivate` 타입 안의 수식어 없는 중첩 타입은 `fileprivate`로 적었다.
- 단어 사전은 모든 항목의 단어 정의를 단어별로 모아 통합했다.

## 규모

| 패키지 | 타입 수 | 문서 |
|---|---|---|
| App | 32 | [App.md](App.md) |
| Composition | 33 | [Composition.md](Composition.md) |
| Feature | 380 | [Feature.md](Feature.md) |
| Domain | 110 | [Domain.md](Domain.md) |
| Data | 136 | [Data.md](Data.md) |
| Infrastructure | 52 | [Infrastructure.md](Infrastructure.md) |
| UI | 139 | [UI.md](UI.md) |
| Tuist | 3 | [Tuist.md](Tuist.md) |
| 합계 | 885 | |

| 종류 | 개수 |
|---|---|
| struct | 412 |
| enum | 400 |
| protocol | 37 |
| typealias | 14 |
| class | 12 |
| actor | 10 |

합성어(단어 2개 이상) 583개, 단일 단어 302개. 고유 단어 328개는 [단어 사전](glossary.md)에 정리했다.

## 합성어 분해 규칙

- 타입 이름(중첩 경로가 아니라 마지막 식별자)을 PascalCase 경계에서 나눈다.
- 약어(`ID`, `URL`, `HTTP`, `DTO`, `API`, `UI`, `JSON`)는 한 단어로 유지하고 정의에 원형을 적는다.
- 브랜드·플랫폼·표준 고정 명칭(`GitHub`, `Firebase`, `Apple`, `Keychain`, `UserDefaults`, `TextField`, `CodingKeys`)은 한 단어로 유지하고 외부 고정 명칭임을 표시한다.
- 관용 표현(`SignIn`, `SignOut`, `Noop`)은 한 단어로 유지하되 구성 단어를 정의에 적는다.
- 정의는 "일반 의미 + 이 타입 문맥에서 가리키는 것" 순서로 쓴다.

## 부록: extension 선언

타입을 새로 정의하지 않는 `extension` 선언 124개는 목록에서 제외했다. 패키지별 개수만 남긴다.

| 패키지 | extension 수 |
|---|---|
| App | 1 |
| Feature | 69 |
| Data | 1 |
| Infrastructure | 6 |
| UI | 47 |

확장 대상이 프로젝트 소유 타입이 아닌 경우(예: `View`, `String`, `Color`, `NSItemProvider`):

`Character`(1), `Color`(1), `Duration`(1), `Font`(1), `Image`(1), `LinearGradient`(1), `NSItemProvider`(1), `RoundedRectangle`(1), `Text`(1), `UnevenRoundedRectangle`(1)
