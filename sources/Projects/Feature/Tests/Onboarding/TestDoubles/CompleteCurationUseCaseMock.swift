import DomainAuthentication
import DomainMember
import Foundation

actor CompleteCurationUseCaseMock: CompleteCurationUseCase {

    // MARK: Lifecycle

    init(results: [Result<Void, MemberError>] = [.success(())]) {
        self.results = results
    }

    // MARK: Internal

    struct Call: Equatable {
        let position: MemberPosition
        let careerLevel: CareerLevel
    }

    func callAsFunction(
        position: MemberPosition,
        careerLevel: CareerLevel,
    ) async throws {
        calls.append(Call(position: position, careerLevel: careerLevel))
        try nextResult().get()
    }

    func snapshot() -> [Call] {
        calls
    }

    // MARK: Private

    private var results: [Result<Void, MemberError>]
    private var calls = [Call]()

    private func nextResult() -> Result<Void, MemberError> {
        guard !results.isEmpty else { return .success(()) }
        return results.count > 1 ? results.removeFirst() : results[0]
    }

}
