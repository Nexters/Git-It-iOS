import DesignSystem
import SwiftUI
import Testing

@testable import UIComponent

@Suite("BookmarkButton 계약")
struct BookmarkButtonTests {
    @Test
    func `접근성 라벨을 생략할 수 없다`() {
        _ = BookmarkButton(
            isSaved: .constant(false),
            accessibilityLabel: "저장하기",
        )
    }

    @Test
    func `히트 영역은 최소 터치 크기 이상이다`() {
        #expect(ControlSizeToken.minimumTouch.value >= 44)
    }

    @Test
    func `저장 여부는 값으로 받아 아이콘을 결정한다`() {
        #expect(BookmarkButton.symbol(isSaved: true) == "bookmark.fill")
        #expect(BookmarkButton.symbol(isSaved: false) == "bookmark")
    }

    @Test
    func `저장 여부를 State로 보관하지 않고 Binding으로 참조한다`() {
        let button = BookmarkButton(
            isSaved: .constant(true),
            accessibilityLabel: "저장 해제하기",
        )
        let children = Mirror(reflecting: button).children
        let stateProperties = children.filter {
            String(describing: type(of: $0.value)).hasPrefix("State<")
        }

        #expect(stateProperties.isEmpty)
        #expect(children.first { $0.label == "_isSaved" }?.value is Binding<Bool>)
    }

    @Test
    func `탭하면 저장 여부 Binding을 반전한다`() {
        var isSaved = true
        let button = BookmarkButton(
            isSaved: Binding(
                get: { isSaved },
                set: { isSaved = $0 },
            ),
            accessibilityLabel: "저장 해제하기",
        )

        button.toggle()

        #expect(!isSaved)
    }
}
