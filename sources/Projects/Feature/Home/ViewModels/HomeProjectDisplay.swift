import DomainIdentifier
import DomainProject
import UIComponent

struct HomeProjectDisplay: Equatable, Sendable {

    // MARK: Lifecycle

    init(
        _ project: ProjectSummary,
        index: Int,
    ) {
        projectID = project.id
        title = project.repositoryName
        technologies = project.techStack.joined(separator: " · ")
        progress = Double(project.progressPercent) / 100
        currentSetLabel = project.currentSet.label
        setTitle = project.currentSet.title
        style = Self.styles[index % Self.styles.count]
        isLearningEnabled = project.next?.quizID != nil
    }

    // MARK: Internal

    let projectID: ProjectID
    let title: String
    let technologies: String
    let progress: Double
    let currentSetLabel: String
    let setTitle: String
    let style: HomeProjectCard.Style
    let isLearningEnabled: Bool

    // MARK: Private

    private static let styles: [HomeProjectCard.Style] = [.purple, .lightBlue, .darkBlue]

}
