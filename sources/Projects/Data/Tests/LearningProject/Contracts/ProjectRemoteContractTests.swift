import Testing

@testable import DataLearningProject

// MARK: - LearningProjectRemoteContractTests

@Suite("ProjectRemote 계약")
struct LearningProjectRemoteContractTests {

    @Test
    func `프로젝트를 등록한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.registerProject(
            RegisterProjectRequestDTO(githubRepoURL: "https://github.com/example/repo", quizLevel: .l1)
        )

        #expect(response.projectID == "project-1")
        #expect(await remote.recordedCalls() == [.registerProject])
    }

    @Test
    func `프로젝트 목록을 페이지 단위로 조회한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.fetchProjects(page: 0, size: 20)

        #expect(response.items.count == 1)
        #expect(!response.hasNext)
        #expect(await remote.recordedCalls() == [.fetchProjects])
    }

    @Test
    func `프로젝트 상세를 조회한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        let response = try await remote.fetchProjectDetail(projectID: "project-1")

        #expect(response.projectID == "project-1")
        #expect(await remote.recordedCalls() == [.fetchProjectDetail])
    }

    @Test
    func `프로젝트를 삭제한다`() async throws {
        let remote = LearningProjectRemoteProbe()

        try await remote.deleteProject(projectID: "project-1")

        #expect(await remote.recordedCalls() == [.deleteProject])
    }

}
