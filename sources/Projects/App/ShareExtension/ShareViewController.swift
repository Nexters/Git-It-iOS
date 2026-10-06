import UIKit
import UniformTypeIdentifiers

// MARK: - ShareViewController

/// 공유 시트에서 전달받은 첫 번째 URL을 App Group 컨테이너에 기록하고 컨테이너 앱을 연다.
/// 저장소 링크인지는 판정하지 않는다. 유효성 판정과 실패 안내는 사용자가 직접 붙여넣었을
/// 때와 동일하게 앱의 링크 입력 경로가 단독으로 담당한다.
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
        // 컨테이너 앱이 열린 뒤에 확장을 종료해야 실행 신호가 유실되지 않는다.
        _ = await extensionContext.open(containerAppURL)
    }

    /// 공유 항목의 URL을 순서대로 훑어 형식과 무관하게 첫 번째 것을 고른다. URL 항목이
    /// 하나도 없을 때만 아무것도 기록하지 않고 앱도 열지 않는다.
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
