import Testing

@testable import DomainLearningProject

// MARK: - ProjectRegistrationReceiptTests

@Suite("ProjectRegistrationReceipt")
struct ProjectRegistrationReceiptTests {
    @Test
    func `서버 raw status 대소문자를 그대로 보존한다`() {
        let receipt = ProjectRegistrationReceipt(
            projectID: "project-1",
            requestStatus: "Ready",
            quizLevel: .l2,
        )

        #expect(receipt.requestStatus == "Ready")
    }

    @Test
    func `서버가 정의하지 않은 새 상태 값도 그대로 보존한다`() {
        let receipt = ProjectRegistrationReceipt(
            projectID: "project-1",
            requestStatus: "SOME_NEW_STATUS",
            quizLevel: .l1,
        )

        #expect(receipt.requestStatus == "SOME_NEW_STATUS")
    }
}
