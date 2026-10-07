import DomainLearningProject
import Foundation
import Testing

@testable import Feature

@Suite("QuestionSourceDisplay 출처 표시 값")
struct QuestionSourceDisplayTests {

    @Test
    func `출처 배열 전체를 응답 순서 그대로 변환한다`() {
        let displays = QuestionSourceDisplay.list(
            sources: [QuizTestFixture.fileSource, QuizTestFixture.referenceSource]
        )

        #expect(displays.count == 2)
        #expect(displays.map(\.id) == [0, 1])
        #expect(displays[0].title == "Sources/App/AppDelegate.swift")
        #expect(displays[0].detail == "10–24행")
        #expect(displays[0].lineAnchor == "L10-L24")
        #expect(displays[0].linkLabel == "Sources/App/AppDelegate.swift:L10-L24")
        #expect(displays[1].lineAnchor == nil)
        #expect(displays[1].linkLabel == "https://developer.apple.com/documentation/swiftui")
    }

    @Test
    func `URL이 있는 출처만 링크로 표시하고 접근성 문장에 링크를 알린다`() {
        let displays = QuestionSourceDisplay.list(
            sources: [QuizTestFixture.fileSource, QuizTestFixture.referenceSource]
        )

        #expect(!displays[0].isLink)
        #expect(displays[1].isLink)
        #expect(displays[1].referenceURL == URL(string: "https://developer.apple.com/documentation/swiftui"))
        #expect(displays[1].accessibilityLabel.hasSuffix("링크"))
    }

    @Test
    func `출처가 없으면 빈 배열을 만든다`() {
        #expect(QuestionSourceDisplay.list(sources: []).isEmpty)
    }

}
