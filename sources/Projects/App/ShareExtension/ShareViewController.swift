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
        let providers = ((extensionContext?.inputItems as? [NSExtensionItem]) ?? [])
            .flatMap { $0.attachments ?? [] }

        for provider in providers {
            if let urlString = await urlString(from: provider) {
                return urlString
            }
        }
        return nil
    }

    private func urlString(from provider: NSItemProvider) async -> String? {
        let urlIdentifier = UTType.url.identifier
        if
            provider.hasItemConformingToTypeIdentifier(urlIdentifier),
            let url = try? await provider.loadItem(forTypeIdentifier: urlIdentifier) as? URL
        {
            return url.absoluteString
        }

        let textIdentifier = UTType.plainText.identifier
        if
            provider.hasItemConformingToTypeIdentifier(textIdentifier),
            let text = try? await provider.loadItem(forTypeIdentifier: textIdentifier) as? String
        {
            return SharedURLExtractor.firstURLString(inText: text)
        }

        return nil
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

}
