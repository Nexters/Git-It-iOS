import DataExternalRepository
import UIKit
import UniformTypeIdentifiers

// MARK: - ShareViewController

/// 공유 시트에서 전달받은 첫 번째 URL 중 저장소로 해석되는 것을 App Group 컨테이너에
/// 기록하고 컨테이너 앱을 연다. 판정 규칙은 앱의 링크 검증과 같은
/// `GitHubRepositoryURLParser`가 소유하므로 특정 앱의 공유 형태에 의존하지 않는다.
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

    private let urlParser = GitHubRepositoryURLParser()

    private func forwardSharedRepositoryURL() async {
        guard let url = await firstRepositoryURL() else { return }
        SharedRepositoryLinkContainer.store(url)
        guard
            let containerAppURL = URL(string: SharedRepositoryLinkContainer.containerAppURL),
            let extensionContext
        else { return }
        // 컨테이너 앱이 열린 뒤에 확장을 종료해야 실행 신호가 유실되지 않는다.
        _ = await extensionContext.open(containerAppURL)
    }

    /// 공유 항목의 URL을 순서대로 훑어 저장소로 해석되는 첫 번째 것을 고른다. 해석되지
    /// 않으면 아무것도 기록하지 않고 앱도 열지 않는다.
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
                let candidate = url.absoluteString
                if urlParser.location(from: candidate) != nil {
                    return candidate
                }
            }
        }
        return nil
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

}
