import Testing

@testable import DesignSystem

@Suite("LayoutMetrics 파생값 범위")
struct LayoutMetricsTests {

    // MARK: Internal

    @Test
    func `지원 기기 9종의 입력이 규격 범위 안에 있다`() {
        for device in Self.supportedDevices {
            let metrics = device.metrics

            #expect((375.0...440.0).contains(metrics.screenWidth), "\(device.name) screenWidth")
            #expect((667.0...956.0).contains(metrics.screenHeight), "\(device.name) screenHeight")
            #expect((20.0...68.0).contains(metrics.safeAreaTop), "\(device.name) safeAreaTop")
            #expect((0.0...34.0).contains(metrics.safeAreaBottom), "\(device.name) safeAreaBottom")
        }
    }

    @Test
    func `지원 기기 9종의 콘텐츠 폭과 그리드 열이 규격 범위 안에 있다`() {
        for device in Self.supportedDevices {
            let metrics = device.metrics

            #expect((335.0...400.0).contains(metrics.contentWidth), "\(device.name) contentWidth")
            #expect((161.5...194.0).contains(metrics.gridColumn2), "\(device.name) gridColumn2")
            #expect(
                (103.66...125.34).contains(metrics.gridColumn3),
                "\(device.name) gridColumn3",
            )
        }
    }

    @Test
    func `지원 기기 9종의 스크림 높이가 규격 범위 안에 있다`() {
        for device in Self.supportedDevices {
            let metrics = device.metrics

            for headerStyle in LayoutMetrics.HeaderStyle.allCases {
                #expect((50.0...120.0).contains(headerStyle.height), "headerHeight")
                #expect(
                    (70.0...188.0).contains(metrics.topScrimHeight(headerStyle: headerStyle)),
                    "\(device.name) topScrimHeight",
                )
            }
            #expect(
                (0.0...127.0).contains(metrics.bottomScrimHeight(hasTabBar: false)),
                "\(device.name) bottomScrimHeight 탭바 없음",
            )
            #expect(
                (0.0...127.0).contains(metrics.bottomScrimHeight(hasTabBar: true)),
                "\(device.name) bottomScrimHeight 탭바 있음",
            )
        }
    }

    @Test
    func `지원 기기 9종의 세로 예산과 시트 높이가 규격 범위 안에 있다`() {
        for device in Self.supportedDevices {
            let metrics = device.metrics

            for headerStyle in LayoutMetrics.HeaderStyle.allCases {
                #expect(
                    (435.0...718.0).contains(metrics.contentBudget(headerStyle: headerStyle)),
                    "\(device.name) contentBudget",
                )
            }
            #expect(
                (24.0...34.0).contains(metrics.tabBarBottomInset),
                "\(device.name) tabBarBottomInset",
            )
            #expect(
                (631.0...878.0).contains(metrics.sheetMaximumHeight),
                "\(device.name) sheetMaximumHeight",
            )
        }
    }

    @Test
    func `가장 작은 기기에서 파생값이 규격 하한과 정확히 일치한다`() {
        let metrics = LayoutMetrics(
            screenWidth: 375,
            screenHeight: 667,
            safeAreaTop: 20,
            safeAreaBottom: 0,
        )

        #expect(metrics.contentWidth == 335)
        #expect(metrics.topScrimHeight(headerStyle: .plain) == 70)
        #expect(metrics.tabBarBottomInset == 24)
        #expect(metrics.contentBudget(headerStyle: .plain) == 505)
        #expect(metrics.contentBudget(headerStyle: .largeTitle) == 435)
        #expect(metrics.sheetMaximumHeight == 631)
    }

    @Test
    func `가장 큰 기기에서 파생값이 규격 상한과 정확히 일치한다`() {
        let metrics = LayoutMetrics(
            screenWidth: 440,
            screenHeight: 956,
            safeAreaTop: 62,
            safeAreaBottom: 34,
        )

        #expect(metrics.contentWidth == 400)
        #expect(metrics.gridColumn2 == 194)
        #expect(metrics.contentBudget(headerStyle: .plain) == 718)
        #expect(metrics.sheetMaximumHeight == 878)
    }

    @Test
    func `safe area 상단이 가장 큰 기기의 큰 제목 헤더에서 상단 스크림이 상한과 일치한다`() {
        let metrics = LayoutMetrics(
            screenWidth: 420,
            screenHeight: 912,
            safeAreaTop: 68,
            safeAreaBottom: 34,
        )

        #expect(metrics.topScrimHeight(headerStyle: .largeTitle) == 188)
    }

    @Test
    func `헤더 종류별 높이가 규격 값과 일치한다`() {
        #expect(LayoutMetrics.HeaderStyle.plain.height == 50)
        #expect(LayoutMetrics.HeaderStyle.inlineTitle.height == 64)
        #expect(LayoutMetrics.HeaderStyle.inlineUser.height == 98)
        #expect(LayoutMetrics.HeaderStyle.largeTitle.height == 120)
    }

    // MARK: Private

    private struct SupportedDevice {
        let name: String
        let metrics: LayoutMetrics
    }

    private static let supportedDevices: [SupportedDevice] = [
        SupportedDevice(
            name: "iPhone SE 3",
            metrics: LayoutMetrics(screenWidth: 375, screenHeight: 667, safeAreaTop: 20, safeAreaBottom: 0),
        ),
        SupportedDevice(
            name: "iPhone 13 mini",
            metrics: LayoutMetrics(screenWidth: 375, screenHeight: 812, safeAreaTop: 50, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 16e · 14 · 13",
            metrics: LayoutMetrics(screenWidth: 390, screenHeight: 844, safeAreaTop: 47, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 16 · 15 · 15 Pro",
            metrics: LayoutMetrics(screenWidth: 393, screenHeight: 852, safeAreaTop: 59, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 17 · 17 Pro · 16 Pro",
            metrics: LayoutMetrics(screenWidth: 402, screenHeight: 874, safeAreaTop: 62, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone Air",
            metrics: LayoutMetrics(screenWidth: 420, screenHeight: 912, safeAreaTop: 68, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 14 Plus · 13 Pro Max",
            metrics: LayoutMetrics(screenWidth: 428, screenHeight: 926, safeAreaTop: 47, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 16 Plus · 15 Pro Max",
            metrics: LayoutMetrics(screenWidth: 430, screenHeight: 932, safeAreaTop: 59, safeAreaBottom: 34),
        ),
        SupportedDevice(
            name: "iPhone 17 Pro Max · 16 Pro Max",
            metrics: LayoutMetrics(screenWidth: 440, screenHeight: 956, safeAreaTop: 62, safeAreaBottom: 34),
        ),
    ]

}
