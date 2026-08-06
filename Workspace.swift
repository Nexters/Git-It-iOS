import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: "GitIt",
    projects: ProjectName.allCases.map(\.projectPath),
)
