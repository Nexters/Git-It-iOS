import DesignSystem
import SwiftUI

extension EmptyState {
    enum Constant {
        static var illustrationSize: CGFloat {
            128
        }

        /// 삽화와 문구 사이 세로 간격. 화면 좌우 여백 토큰과 의미가 다르다.
        static var illustrationSpacing: CGFloat {
            20
        }

        static var textSpacing: CGFloat {
            8
        }

        static var textMaxWidth: CGFloat {
            320
        }
    }
}
