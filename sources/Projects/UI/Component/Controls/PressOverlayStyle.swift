import DesignSystem
import SwiftUI

// MARK: - PressOverlayStyle

/// 버튼 계열 공용 누름 표현.
///
/// 눌림 시 `white30` 오버레이 하나만 겹치고 배경색을 새로 만들지 않는다.
/// `Component/`의 프로덕션 SwiftUI `Button` 사용처 전부가 이 스타일을 쓴다.
public struct PressOverlayStyle: ButtonStyle {

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                if configuration.isPressed {
                    Color(designSystem: .white30)
                        .allowsHitTesting(false)
                }
            }
    }

}

extension ButtonStyle where Self == PressOverlayStyle {
    public static var pressOverlay: Self {
        PressOverlayStyle()
    }
}
