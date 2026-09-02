// MARK: - LayoutMetrics

/// 화면 크기와 safe area만 입력으로 받아 규격 레이아웃 파생값을 유도하는 런타임 변수.
///
/// 가로는 늘리고 세로는 고정한다. Figma 정본 캔버스 360 × 800은 크기 기준이 아니며
/// 구성 순서·간격·컴포넌트 높이만 정본에서 가져온다.
public struct LayoutMetrics: Sendable, Equatable {
    public init(
        screenWidth: Double,
        screenHeight: Double,
        safeAreaTop: Double,
        safeAreaBottom: Double,
    ) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.safeAreaTop = safeAreaTop
        self.safeAreaBottom = safeAreaBottom
    }

    // MARK: Public

    public let screenWidth: Double
    public let screenHeight: Double
    public let safeAreaTop: Double
    public let safeAreaBottom: Double

    /// 좌우 화면 여백을 뺀 콘텐츠 폭.
    public var contentWidth: Double {
        screenWidth - LayoutToken.margin.value * 2
    }

    /// 2열 그리드의 한 열 폭.
    public var gridColumn2: Double {
        (contentWidth - LayoutToken.gutter.value) / 2
    }

    /// 3열 그리드의 한 열 폭.
    public var gridColumn3: Double {
        (contentWidth - LayoutToken.gutter.value * 2) / 3
    }

    /// 탭바 알약이 화면 하단에서 띄워지는 거리.
    public var tabBarBottomInset: Double {
        max(safeAreaBottom, Self.minimumTabBarBottomInset)
    }

    /// 시트가 차지할 수 있는 최대 높이. 넘으면 시트 안에서 스크롤한다.
    public var sheetMaximumHeight: Double {
        screenHeight - safeAreaTop - Self.sheetTopClearance
    }

    /// 상단 스크림 높이. safe area와 헤더를 함께 덮는다.
    public func topScrimHeight(headerStyle: HeaderStyle) -> Double {
        safeAreaTop + headerStyle.height
    }

    /// 하단 스크림 높이. 탭바가 있으면 탭바 영역까지 덮는다.
    public func bottomScrimHeight(hasTabBar: Bool) -> Double {
        safeAreaBottom + (hasTabBar ? Self.tabBarScrimHeight : 0)
    }

    /// 헤더와 탭바를 제외하고 콘텐츠가 쓸 수 있는 세로 예산.
    public func contentBudget(headerStyle: HeaderStyle) -> Double {
        screenHeight - safeAreaTop - safeAreaBottom - headerStyle.height - Self.tabBarClearance
    }

    // MARK: Private

    /// UIUX Guide §7.3이 정한 탭바 여유 높이.
    private static let tabBarClearance: Double = 92
    private static let tabBarScrimHeight: Double = 93
    private static let minimumTabBarBottomInset: Double = 24
    private static let sheetTopClearance: Double = 16

}
