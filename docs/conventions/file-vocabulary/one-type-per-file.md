# 파일 하나에 타입 하나

[Git It iOS 파일·형태 어휘 컨벤션](../file-vocabulary.md)의 규칙 문서입니다.

**파일 하나는 파일 밖에서 참조되는 최상위 타입을 하나만 정의하고, 파일 이름은 그 타입
이름과 정확히 일치합니다.** `struct`, `enum`, `class`, `actor`, `protocol` 모두 같은
규칙을 따릅니다.

다음은 개수에 포함하지 않습니다.

- `private`·`fileprivate` 보조 선언
- 같은 파일의 타입에 대한 `extension`
- `#Preview` 매크로

UIComponent는 예외로, 중첩할 수 없는 보조 타입과 프리뷰 전용 타입을 컴포넌트 파일에 함께
둡니다([UIComponent 컨벤션 — 폴더와 파일](../ui-component/folder-file.md)).

테스트 파일은 `@Suite` 또는 `XCTestCase` 타입 하나와, 그 파일에서만 사용하는 `private`
Test Double을 함께 둘 수 있습니다([테스트 컨벤션 — 파일과 Target 구성](../test.md#7-파일과-target-구성)).
둘 이상의 파일에서 쓰는 Double은 `TestDoubles/`로 옮깁니다.

파일 이름은 타입 이름을 축약하거나 복수화하지 않습니다. 여러 타입을 한 파일에 묶은
`AnswerDTOs.swift` 같은 이름은 사용하지 않고 타입별 파일로 나눈 뒤
[디렉터리·파일 컨벤션 — 2뎁스 — 타입 패밀리 폴더](../directory-file.md#5-2뎁스--타입-패밀리-폴더)의 폴더로
묶습니다.
