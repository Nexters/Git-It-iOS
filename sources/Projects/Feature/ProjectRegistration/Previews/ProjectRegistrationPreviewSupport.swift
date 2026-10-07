import DomainLearningProject
import Foundation

enum ProjectRegistrationPreviewSupport {
    static let repository = ExternalRepository(
        canonicalURL: "https://github.com/seaweedfs/seaweedfs",
        ownerName: "SeaweedFS",
        repositoryName: "SeaweedFS",
        imageURL: "https://avatars.githubusercontent.com/u/33559114",
        starCount: 24000,
        techStack: ["Go"],
    )

    static let repositoryWithoutAvatar = ExternalRepository(
        canonicalURL: repository.canonicalURL,
        ownerName: repository.ownerName,
        repositoryName: repository.repositoryName,
        imageURL: nil,
        starCount: repository.starCount,
        techStack: repository.techStack,
    )

    static let receipt = ProjectRegistrationReceipt(
        projectID: "preview-project",
        requestStatus: "accepted",
        quizLevel: .l1,
    )
}
