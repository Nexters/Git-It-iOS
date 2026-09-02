import DesignSystem
import Testing

@testable import UIComponent

@Suite("BookmarkButton 계약")
struct BookmarkButtonTests {
    @Test
    func `접근성 라벨을 생략할 수 없다`() {
        _ = BookmarkButton(isSaved: false, accessibilityLabel: "저장하기") { }
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
    func `저장 여부를 스스로 보관하지 않는다`() {
        let mirror = Mirror(reflecting: BookmarkButton(isSaved: true, accessibilityLabel: "저장 해제하기") { })
        let stateProperties = mirror.children.filter {
            ($0.label ?? "").hasPrefix("_")
        }

        #expect(stateProperties.isEmpty)
    }
}
