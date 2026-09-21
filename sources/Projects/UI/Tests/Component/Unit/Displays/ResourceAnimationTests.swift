import SwiftUI
import Testing

@testable import UIComponent

@Suite("ResourceAnimation 계약")
struct ResourceAnimationTests {

    // MARK: Internal

    @Test
    func `상태 모델을 넘기지 않으면 반복 재생·기본 속도·맞춤 비율로 그린다`() {
        let stateModel = stateModel(of: ResourceAnimation(asset: .generalLoading))

        #expect(stateModel == ResourceAnimation.StateModel(isLooping: true, speed: 1, contentMode: .fit))
    }

    @Test
    func `넘긴 상태 모델을 그대로 보관한다`() {
        let expected = ResourceAnimation.StateModel(isLooping: false, speed: 1.5, contentMode: .fill)

        #expect(stateModel(of: ResourceAnimation(asset: .complete, stateModel: expected)) == expected)
    }

    // MARK: Private

    private func stateModel(of animation: ResourceAnimation) -> ResourceAnimation.StateModel? {
        Mirror(reflecting: animation).descendant("stateModel") as? ResourceAnimation.StateModel
    }

}
