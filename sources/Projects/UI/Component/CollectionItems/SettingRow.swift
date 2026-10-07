import DesignSystem
import SwiftUI

// MARK: - SettingRow

public struct SettingRow<Content: View>: View {

    // MARK: Lifecycle

    public init(
        value: String? = nil,
        @ViewBuilder content: () -> Content,
        onTap: @escaping () -> Void = { },
    ) {
        self.value = value
        self.content = content()
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        Button(action: onTap) {
            HStack {
                content
                Spacer()
                HStack(spacing: 6) {
                    if let value {
                        StyledText.body2(value, color: .grey400)
                    }
                    ResourceImage(asset: .icon(.settingChevron))
                        .frame(width: Constant.chevronSize, height: Constant.chevronSize)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Constant.minimumHeight)
            .padding(.vertical, Constant.verticalPadding)
            .padding(.horizontal, Constant.horizontalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    private enum Constant {
        static var chevronSize: CGFloat {
            16
        }

        static var horizontalPadding: CGFloat {
            20
        }

        static var verticalPadding: CGFloat {
            8
        }

        static var minimumHeight: CGFloat {
            40
        }
    }

    private let content: Content
    private let value: String?
    private let onTap: () -> Void

}
