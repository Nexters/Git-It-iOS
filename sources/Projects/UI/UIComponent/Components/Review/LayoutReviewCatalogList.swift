import SwiftUI

public struct LayoutReviewCatalogList: View {

    // MARK: Lifecycle

    public init(
        viewModel: ViewModel,
        onSelectScreen: @escaping (String) -> Void,
    ) {
        self.viewModel = viewModel
        self.onSelectScreen = onSelectScreen
    }

    // MARK: Public

    public struct Screen: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
        ) {
            self.id = id
            self.title = title
        }

        public let id: String
        public let title: String
    }

    public struct Section: Identifiable, Sendable, Equatable {
        public init(
            id: String,
            title: String,
            screens: [Screen],
        ) {
            self.id = id
            self.title = title
            self.screens = screens
        }

        public let id: String
        public let title: String
        public let screens: [Screen]
    }

    public struct ViewModel: Sendable, Equatable {
        public init(
            version: String,
            buildNumber: String,
            purpose: String,
            changeSummary: String,
            limitations: [String],
            sections: [Section],
        ) {
            self.version = version
            self.buildNumber = buildNumber
            self.purpose = purpose
            self.changeSummary = changeSummary
            self.limitations = limitations
            self.sections = sections
        }

        public let version: String
        public let buildNumber: String
        public let purpose: String
        public let changeSummary: String
        public let limitations: [String]
        public let sections: [Section]
    }

    public var body: some View {
        List {
            SwiftUI.Section("검토 정보") {
                LabeledContent(
                    "검토 build",
                    value: "\(viewModel.version) (\(viewModel.buildNumber))",
                )

                information(title: "목적", body: viewModel.purpose)
                information(title: "변경 요약", body: viewModel.changeSummary)

                if viewModel.limitations.isEmpty == false {
                    VStack(alignment: .leading, spacing: Constant.informationSpacing) {
                        Text("알려진 제한")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(viewModel.limitations, id: \.self) { limitation in
                            Text("• \(limitation)")
                        }
                    }
                }
            }

            ForEach(viewModel.sections) { section in
                SwiftUI.Section(section.title) {
                    ForEach(section.screens) { screen in
                        screenRow(screen)
                    }
                }
            }
        }
        .navigationTitle("레이아웃 검토")
    }

    // MARK: Private

    private enum Constant {
        static let informationSpacing: CGFloat = 4
        static let screenInformationSpacing: CGFloat = 3
    }

    private let viewModel: ViewModel
    private let onSelectScreen: (String) -> Void

    private func information(
        title: String,
        body: String,
    ) -> some View {
        VStack(alignment: .leading, spacing: Constant.informationSpacing) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(body)
        }
    }

    private func screenRow(_ screen: Screen) -> some View {
        Button {
            onSelectScreen(screen.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Constant.screenInformationSpacing) {
                    Text(screen.title)
                        .foregroundStyle(.primary)
                    Text(screen.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(screen.title) 검토 화면 열기")
    }

}

#Preview("Layout Review Catalog List") {
    NavigationStack {
        LayoutReviewCatalogList(
            viewModel: .init(
                version: "1.0",
                buildNumber: "1",
                purpose: "최종 UI 레이아웃 검토",
                changeSummary: "전체 화면 카탈로그 연결",
                limitations: ["제품 기능은 동작하지 않음"],
                sections: [
                    .init(
                        id: "core",
                        title: "핵심 화면",
                        screens: [.init(id: "home", title: "홈")],
                    )
                ],
            ),
            onSelectScreen: { _ in },
        )
    }
}
