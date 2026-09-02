// MARK: - LayoutMetrics

public struct LayoutMetrics: Sendable, Equatable {

    // MARK: Lifecycle

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

    public static let `default` = LayoutMetrics(
        screenWidth: 402,
        screenHeight: 874,
        safeAreaTop: 62,
        safeAreaBottom: 34,
    )

    public let screenWidth: Double
    public let screenHeight: Double
    public let safeAreaTop: Double
    public let safeAreaBottom: Double

    public var contentWidth: Double {
        screenWidth - LayoutToken.margin.value * 2
    }

    public var gridColumn2: Double {
        (contentWidth - LayoutToken.gutter.value) / 2
    }

    public var gridColumn3: Double {
        (contentWidth - LayoutToken.gutter.value * 2) / 3
    }

    public var tabBarBottomInset: Double {
        max(safeAreaBottom, Self.minimumTabBarBottomInset)
    }

    public var sheetMaximumHeight: Double {
        screenHeight - safeAreaTop - Self.sheetTopClearance
    }

    public func topScrimHeight(headerStyle: HeaderStyle) -> Double {
        safeAreaTop + headerStyle.height
    }

    public func bottomScrimHeight(hasTabBar: Bool) -> Double {
        safeAreaBottom + (hasTabBar ? Self.tabBarScrimHeight : 0)
    }

    public func contentBudget(headerStyle: HeaderStyle) -> Double {
        screenHeight - safeAreaTop - safeAreaBottom - headerStyle.height - Self.tabBarClearance
    }

    // MARK: Private

    private static let tabBarClearance: Double = 92
    private static let tabBarScrimHeight: Double = 92
    private static let minimumTabBarBottomInset: Double = 24
    private static let sheetTopClearance: Double = 16

}
