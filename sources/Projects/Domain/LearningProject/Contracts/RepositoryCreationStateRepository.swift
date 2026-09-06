public protocol RepositoryCreationStateRepository: Sendable {
    func isCreating(githubRepoURL: String) async -> Bool
    func beginCreation(githubRepoURL: String) async -> Bool
    func attachProjectID(
        _ projectID: String,
        toGithubRepoURL githubRepoURL: String,
    ) async
    func endCreation(githubRepoURL: String) async
    func endCreation(projectID: String) async
    func activeProjectIDs() async -> Set<String>
}
