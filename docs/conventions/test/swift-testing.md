# Swift Testing을 기본으로 사용합니다

[Git It iOS 테스트 컨벤션](../test.md)의 규칙 문서입니다.

일반 테스트는 `Testing`을 import하고 `@Suite`, `@Test`, `#expect`, `#require`를
사용합니다.

```swift
import Testing

@Suite("학습 프로젝트 목록 로딩")
struct LearningProjectListLoadingTests {

    @Test
    func `빈 페이지는 로딩 완료와 빈 상태를 함께 표현한다`() {
        let state = LearningProjectListFeature.State(loadState: .loaded)

        #expect(state.isEmpty)
    }
}
```

- 값과 상태 비교에는 `#expect`를 사용합니다.
- 이후 검증에 필요한 전제 조건과 optional 해제에는 `try #require`를 사용합니다.
- 오류 계약은 동기 코드에 `#expect(throws:)`, 비동기 코드에
  `await #expect(throws:)`를 사용합니다.
- 같은 입력과 기대 결과를 반복할 때는 `@Test(arguments:)`를 사용합니다.
- 비동기 완료 횟수나 콜백을 검증할 때는 임의의 `sleep` 대신 Swift Testing의
  `confirmation` 또는 대상이 제공하는 구조화된 동시성 완료 지점을 사용합니다.
