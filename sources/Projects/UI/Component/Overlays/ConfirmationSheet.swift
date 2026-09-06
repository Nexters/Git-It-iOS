import DesignSystem
import Foundation
import SwiftUI

public struct ConfirmationSheet: View {

    // MARK: Lifecycle

    public init(
        imageURL: String?,
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String,
        onConfirmTap: @escaping () -> Void = { },
        onCancelTap: @escaping () -> Void = { },
    ) {
        self.imageURL = imageURL
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirmTap = onConfirmTap
        self.onCancelTap = onCancelTap
    }

    // MARK: Public

    public var body: some View {
        SheetSurface {
            VStack(spacing: 0) {
                thumbnail
                    .padding(.top, Constant.thumbnailTopPadding)

                VStack(spacing: Constant.textSpacing) {
                    StyledText.subtitle1(title, alignment: .center)
                    StyledText.body2(message, color: .grey400, alignment: .center)
                }
                .padding(.top, Constant.textSetTopPadding)

                VStack(spacing: LayoutToken.compactSpacing) {
                    ActionButton.destructive(confirmTitle, action: onConfirmTap)
                    ActionButton.text(cancelTitle, action: onCancelTap)
                }
                .padding(.top, Constant.buttonsTopPadding)
            }
        }
    }

    // MARK: Private

    private enum Constant {
        static let thumbnailSize: CGFloat = 128
        static let thumbnailTopPadding: CGFloat = 22
        static let textSpacing: CGFloat = 8
        static let textSetTopPadding: CGFloat = 22
        static let buttonsTopPadding: CGFloat = 26
    }

    private let imageURL: String?
    private let title: String
    private let message: String
    private let confirmTitle: String
    private let cancelTitle: String
    private let onConfirmTap: () -> Void
    private let onCancelTap: () -> Void

    @ViewBuilder
    private var thumbnail: some View {
        if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(designSystem: .grey500)
            }
            .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
            .designSystemCornerRadius(.small)
            .accessibilityHidden(true)
        } else {
            Color(designSystem: .grey500)
                .frame(width: Constant.thumbnailSize, height: Constant.thumbnailSize)
                .designSystemCornerRadius(.small)
                .accessibilityHidden(true)
        }
    }

}

#Preview("Confirmation Sheet") {
    ZStack {
        Color(designSystem: .grey700)

        ModalOverlay(isPresented: true) {
            ConfirmationSheet(
                imageURL: nil,
                title: "프로젝트를 삭제할까요?",
                message: "학습 문제와 진도가 모두 삭제되며,\n이 작업은 취소할 수 없습니다.",
                confirmTitle: "삭제",
                cancelTitle: "취소",
            )
        }
    }
    .frame(width: 390, height: 844)
}
