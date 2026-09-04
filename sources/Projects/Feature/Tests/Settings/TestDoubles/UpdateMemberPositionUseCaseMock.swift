import DomainMember

actor UpdateMemberPositionUseCaseMock: UpdateMemberPositionUseCase {

    // MARK: Lifecycle

    init(errors: [MemberError?] = [nil]) {
        self.errors = errors
    }

    // MARK: Internal

    func callAsFunction(_ position: MemberPosition) async throws {
        requestedPositions.append(position)
        if let error = nextError() {
            throw error
        }
    }

    func snapshot() -> [MemberPosition] {
        requestedPositions
    }

    // MARK: Private

    private var errors: [MemberError?]
    private var requestedPositions = [MemberPosition]()

    private func nextError() -> MemberError? {
        guard !errors.isEmpty else { return nil }
        return errors.count > 1 ? errors.removeFirst() : errors[0]
    }

}
