import ComposableArchitecture
import CompositionShareExtension
import Feature
import SwiftUI
import UIKit

// MARK: - ShareViewController

final class ShareViewController: UIViewController {

    // MARK: Lifecycle

    override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?,
    ) {
        super.init(
            nibName: nibNameOrNil,
            bundle: nibBundleOrNil,
        )
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
                externalRepository: composition.externalRepository,
                projectGeneration: composition.projectGeneration,
                signInAvailability: composition.signInAvailability,
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
