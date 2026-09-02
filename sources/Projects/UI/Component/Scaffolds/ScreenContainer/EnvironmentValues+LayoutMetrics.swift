import DesignSystem
import SwiftUI

extension EnvironmentValues {

    /// 화면 골격이 공유하는 런타임 레이아웃 변수.
    ///
    /// `ScreenContainer`가 유일한 주입 지점이며, 기본값은 주력 기기 규격이다.
    @Entry public var layoutMetrics = LayoutMetrics(
        screenWidth: 402,
        screenHeight: 874,
        safeAreaTop: 62,
        safeAreaBottom: 34,
    )
}
