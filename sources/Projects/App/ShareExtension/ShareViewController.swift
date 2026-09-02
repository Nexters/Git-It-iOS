import UIKit
import UniformTypeIdentifiers

// MARK: - ShareViewController

final class ShareViewController: UIViewController {

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { [weak self] in
            await self?.forwardSharedRepositoryURL()
            self?.finish()
        }
    }

    // MARK: Private

    private func forwardSharedRepositoryURL() async {
        guard let url = await firstRepositoryURL() else { return }
        SharedRepositoryLinkContainer.store(url)
        guard
            let containerAppURL = URL(string: SharedRepositoryLinkContainer.containerAppURL),
            let extensionContext
        else { return }

        _ = await extensionContext.open(containerAppURL)
    }

    private func firstRepositoryURL() async -> String? {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let identifier = UTType.url.identifier
        for item in items {
            for provider in item.attachments ?? []
                where provider.hasItemConformingToTypeIdentifier(identifier)
            {
                guard let url = try? await provider.loadItem(forTypeIdentifier: identifier) as? URL else {
                    continue
                }
                return url.absoluteString
            }
        }
        return nil
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

}
