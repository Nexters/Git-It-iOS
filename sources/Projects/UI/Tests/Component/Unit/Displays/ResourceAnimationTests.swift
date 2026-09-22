import SwiftUI
import Testing

@testable import UIComponent

@Suite("ResourceAnimation 상태 선언")
struct ResourceAnimationTests {

    // MARK: Internal

    @Test
    func `재생 설정을 선언하지 않으면 반복 재생·기본 속도·맞춤 비율로 그린다`() {
        let animation = ResourceAnimation(asset: .generalLoading)

        #expect(stored(
            "isLooping",
            of: animation,
        ) as? Bool == true)
        #expect(stored(
            "speed",
            of: animation,
        ) as? Double == 1)
        #expect(stored(
            "contentMode",
            of: animation,
        ) as? ContentMode == .fit)
    }

    @Test
    func `선언 메서드는 각 재생 설정만 바꾸고 나머지를 유지한다`() {
        let animation = ResourceAnimation(asset: .complete).looping(false).speed(1.5).contentMode(.fill)

        #expect(stored(
            "isLooping",
            of: animation,
        ) as? Bool == false)
        #expect(stored(
            "speed",
            of: animation,
        ) as? Double == 1.5)
        #expect(stored(
            "contentMode",
            of: animation,
        ) as? ContentMode == .fill)
        #expect(stored(
            "asset",
            of: animation,
        ) as? ResourceAnimation.Asset == .complete)
    }

    // MARK: Private

    private func stored(
        _ label: String,
        of animation: ResourceAnimation,
    ) -> Any? {
        Mirror(reflecting: animation).descendant(label)
    }

}
