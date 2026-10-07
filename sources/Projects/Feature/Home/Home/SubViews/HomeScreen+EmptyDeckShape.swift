import SwiftUI

extension HomeScreen {
    struct EmptyDeckShape: Shape {

        // MARK: Internal

        static let designSize = CGSize(width: 501.331, height: 236.627)

        func path(in rect: CGRect) -> Path {
            let scale = min(
                rect.width / Self.designSize.width,
                rect.height / Self.designSize.height,
            )
            let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY)
                .scaledBy(x: scale, y: scale)

            return Self.designPath.applying(transform)
        }

        // MARK: Private

        private static let designPath: Path = {
            var path = Path()

            path.move(to: CGPoint(x: 445.782, y: 0.359))
            path.addCurve(
                to: CGPoint(x: 460.328, y: 9.100),
                control1: CGPoint(x: 452.213, y: -1.244),
                control2: CGPoint(x: 458.725, y: 2.669),
            )
            path.addLine(to: CGPoint(x: 500.972, y: 172.109))
            path.addCurve(
                to: CGPoint(x: 492.231, y: 186.655),
                control1: CGPoint(x: 502.575, y: 178.540),
                control2: CGPoint(x: 498.662, y: 185.052),
            )
            path.addLine(to: CGPoint(x: 366.093, y: 218.105))
            path.addCurve(
                to: CGPoint(x: 351.546, y: 209.365),
                control1: CGPoint(x: 359.662, y: 219.709),
                control2: CGPoint(x: 353.149, y: 215.796),
            )
            path.addLine(to: CGPoint(x: 322.765, y: 93.931))
            path.addLine(to: CGPoint(x: 284.342, y: 227.932))
            path.addCurve(
                to: CGPoint(x: 269.499, y: 236.159),
                control1: CGPoint(x: 282.515, y: 234.302),
                control2: CGPoint(x: 275.869, y: 237.986),
            )
            path.addLine(to: CGPoint(x: 154, y: 203.040))
            path.addLine(to: CGPoint(x: 154, y: 207.456))
            path.addCurve(
                to: CGPoint(x: 142, y: 219.456),
                control1: CGPoint(x: 154, y: 214.083),
                control2: CGPoint(x: 148.627, y: 219.456),
            )
            path.addLine(to: CGPoint(x: 12, y: 219.456))
            path.addCurve(
                to: CGPoint(x: 0, y: 207.456),
                control1: CGPoint(x: 5.373, y: 219.456),
                control2: CGPoint(x: 0, y: 214.083),
            )
            path.addLine(to: CGPoint(x: 0, y: 39.456))
            path.addCurve(
                to: CGPoint(x: 12, y: 27.456),
                control1: CGPoint(x: 0, y: 32.829),
                control2: CGPoint(x: 5.373, y: 27.456),
            )
            path.addLine(to: CGPoint(x: 142, y: 27.456))
            path.addCurve(
                to: CGPoint(x: 154, y: 39.456),
                control1: CGPoint(x: 148.627, y: 27.456),
                control2: CGPoint(x: 154, y: 32.829),
            )
            path.addLine(to: CGPoint(x: 154, y: 123.781))
            path.addLine(to: CGPoint(x: 182.614, y: 23.991))
            path.addCurve(
                to: CGPoint(x: 197.457, y: 15.764),
                control1: CGPoint(x: 184.441, y: 17.620),
                control2: CGPoint(x: 191.086, y: 13.937),
            )
            path.addLine(to: CGPoint(x: 311.424, y: 48.442))
            path.addLine(to: CGPoint(x: 310.903, y: 46.355))
            path.addCurve(
                to: CGPoint(x: 319.644, y: 31.809),
                control1: CGPoint(x: 309.300, y: 39.925),
                control2: CGPoint(x: 313.213, y: 33.412),
            )
            path.closeSubpath()

            return path
        }()

    }
}
