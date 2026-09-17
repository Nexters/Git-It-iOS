import DomainIdentifier
import DomainProject
import Foundation

// MARK: - ProjectListDisplay

public struct ProjectListDisplay: Equatable, Sendable, Identifiable {

    // MARK: Lifecycle

    public init(
        id: ProjectID,
        name: String,
        supportingText: String,
        imageURL: String?,
        progress: Double,
        currentSet: Int,
        setTitle: String,
    ) {
        self.id = id
        self.name = name
        self.supportingText = supportingText
        self.imageURL = imageURL
        self.progress = progress
        self.currentSet = currentSet
        self.setTitle = setTitle
    }

    // MARK: Public

    public let id: ProjectID
    public let name: String
    public let supportingText: String
    public let imageURL: String?
    public let progress: Double
    public let currentSet: Int
    public let setTitle: String

    public static func list(projects: [ProjectSummary]) -> [Self] {
        projects.map {
            Self(
                id: $0.id,
                name: $0.repositoryName,
                supportingText: $0.techStack.joined(separator: " · "),
                imageURL: $0.repositoryImageURL,
                progress: Double($0.progressPercent) / 100,
                currentSet: setNumber(label: $0.currentSet.label),
                setTitle: $0.currentSet.title,
            )
        }
    }

    // MARK: Private

    private static let fallbackSetNumber = 1

    private static func setNumber(label: String) -> Int {
        let digits = label.compactMap(\.wholeNumberValue)
        guard !digits.isEmpty else { return fallbackSetNumber }
        return digits.reduce(0) { $0 * 10 + $1 }
    }

}
