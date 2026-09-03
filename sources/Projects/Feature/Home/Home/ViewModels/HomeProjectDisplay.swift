import DomainLearningProject
import UIComponent

struct HomeProjectDisplay: Equatable, Sendable {

    // MARK: Lifecycle

    init(_ project: LearningProjectSummary, index: Int) {
        projectID = project.projectID
        title = project.repositoryName
        technologies = project.techStack.joined(separator: " · ")
        progress = Double(project.overallProgressPercent) / 100
        currentSetLabel = project.currentSetLabel
        setTitle = project.currentSetTitle
        variant = Self.variants[index % Self.variants.count]
        isLearningEnabled = project.nextSetID != nil && project.nextQuestionID != nil
    }

    // MARK: Internal

    let projectID: String
    let title: String
    let technologies: String
    let progress: Double
    let currentSetLabel: String
    let setTitle: String
    let variant: HomeProjectCard.Variant
    let isLearningEnabled: Bool

    // MARK: Private

    private static let variants: [HomeProjectCard.Variant] = [.purple, .lightBlue, .darkBlue]

}
