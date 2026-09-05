import ComposableArchitecture
import CompositionAdapter
import CompositionShareExtension
import Feature
import SwiftUI
import UIKit

// MARK: - ShareViewController

/// 공유 시트 진입점이다. 조립 루트와 진단 기록을 주입해 화면을 띄우고, 종료 시 호스트
/// 앱으로 그대로 돌아간다. 본 앱을 실행하지 않는다.
final class ShareViewController: UIViewController {

    // MARK: Lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()

        let composition = composition
        let diagnosticLog = diagnosticLog
        let store = Store(initialState: ShareRegistrationFeature.State()) {
            ShareRegistrationFeature(
                parseRepositoryLink: composition.parseRepositoryLink,
                fetchExternalRepository: composition.fetchExternalRepository,
                createLearningProject: composition.createLearningProject,
                resolveSession: { await Self.sessionState(composition.resolveSessionAvailability) },
                isNotificationAuthorized: composition.isNotificationAuthorized,
                enqueueGenerationReminder: composition.enqueueGenerationReminder,
                recordDiagnostic: { diagnosticLog.record($0) },
                dismiss: { [weak self] in self?.completeRequest() },
            )
        }
        self.store = store

        let hostingController = UIHostingController(
            rootView: ShareRegistrationScreen(store: store)
        )
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)

        loadSharedURL(store: store)
    }

    // MARK: Private

    private let composition = ShareExtensionComposition.live(
        ShareExtensionComposition.Environment(
            apiBaseURL: ShareExtensionEndpointHost.api.url,
            externalRepositoryBaseURL: ShareExtensionEndpointHost.externalRepository.url,
        )
    )
    private let diagnosticLog = ShareRegistrationDiagnosticLog()
    private let urlResolver = SharedItemURLResolver()

    private var store: StoreOf<ShareRegistrationFeature>?

    private static func sessionState(
        _ resolve: @Sendable () async -> SessionAvailability
    ) async -> ShareRegistrationSessionState {
        switch await resolve() {
        case .available:
            .available

        case .signInRequired:
            .signInRequired

        case .appLaunchRequired:
            .appLaunchRequired
        }
    }

    private func loadSharedURL(store: StoreOf<ShareRegistrationFeature>) {
        let attachments = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        Task { @MainActor in
            let url = await urlResolver.resolve(from: attachments)
            store.send(.view(.sharedURLResolved(url?.absoluteString)))
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }

}
