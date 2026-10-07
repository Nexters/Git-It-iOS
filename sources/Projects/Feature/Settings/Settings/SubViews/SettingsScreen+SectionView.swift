import SwiftUI
import UIComponent

extension SettingsScreen {
    /// 섹션 제목과 둥근 카드로 묶인 설정 행 그룹(Figma `1465:19702` / `1465:19708`).
    struct SectionView<Rows: View>: View {

        // MARK: Lifecycle

        init(
            title: String,
            @ViewBuilder rows: () -> Rows,
        ) {
            self.title = title
            self.rows = rows()
        }

        // MARK: Internal

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                StyledText.caption2(title, color: .grey400)
                    .padding(.top, Constant.titleTopPadding)
                    .padding(.bottom, Constant.titleBottomPadding)

                VStack(spacing: 0) {
                    rows
                }
                .background(Color(designSystem: .grey600), in: RoundedRectangle(designSystem: .large))
            }
        }

        // MARK: Private

        /// generic 타입 안에서는 static 저장 프로퍼티를 둘 수 없어 계산 프로퍼티로 선언한다.
        private enum Constant {
            static var titleTopPadding: CGFloat {
                20
            }

            static var titleBottomPadding: CGFloat {
                10
            }
        }

        private let title: String
        private let rows: Rows

    }
}
