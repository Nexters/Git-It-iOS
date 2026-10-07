# XCTest는 필요한 플랫폼 기능에만 사용합니다

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

`XCUIApplication`, `XCUIElement`처럼 Swift Testing이 직접 제공하지 않는 XCTest UI
자동화 API가 필요한 경우에만 `XCTestCase`를 사용합니다. 새 예외를 추가하면 테스트
파일 또는 PR 설명에 Swift Testing으로 작성할 수 없는 이유를 남깁니다.

- 하나의 테스트 파일에서 Swift Testing과 XCTest 선언을 섞지 않습니다.
- Xcode가 Swift Testing 테스트를 `xctest` runner로 실행하는 것은 XCTest 작성 예외가
  아닙니다.
- XCTest UI 자동화에서도 §3의 한국어 동작 이름과 §4 이후의 격리·검증 규칙을 따릅니다.
