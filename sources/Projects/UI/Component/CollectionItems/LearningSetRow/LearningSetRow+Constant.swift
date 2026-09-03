import DesignSystem
import SwiftUI

extension LearningSetRow {
    enum Constant {
        static let height: CGFloat = 130
        static let contentPadding: CGFloat = 18
        static let startSymbolSize: CGFloat = 12
        /// 보이는 원의 지름. 터치 영역(`startTouchSize`)이 이를 감쌉니다.
        static let startSurfaceSize: CGFloat = 32
        static let startTouchSize: CGFloat = 44
    }
}
