import DomainAuthentication
import Foundation

// MARK: - PolicyManifestLoader

enum PolicyManifestLoader {

    // MARK: Internal

    enum LoadError: Error, Equatable {
        case resourceMissing
        case invalidApprovedURL(identifier: String)
    }

    static func loadPolicyDocuments(
        resourceName: String = AppBundleResource.policyManifest.rawValue,
        bundle: Bundle = .module,
    ) throws -> [PolicyDocument] {
        guard let resourceURL = bundle.url(forResource: resourceName, withExtension: "json")
        else {
            throw LoadError.resourceMissing
        }
        let data = try Data(contentsOf: resourceURL)
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        return try manifest.documents.map { entry in
            guard
                let approvedURL = URL(string: entry.approvedURL),
                approvedURL.scheme == "https"
            else {
                throw LoadError.invalidApprovedURL(identifier: entry.identifier)
            }
            return PolicyDocument(
                identifier: entry.identifier,
                displayName: entry.displayName,
                version: entry.version,
                approvedURL: approvedURL,
                isRequired: entry.isRequired,
            )
        }
    }

    // MARK: Private

    private struct Manifest: Decodable {
        let documents: [Entry]
    }

    private struct Entry: Decodable {
        let identifier: String
        let displayName: String
        let version: String
        let approvedURL: String
        let isRequired: Bool
    }

}
