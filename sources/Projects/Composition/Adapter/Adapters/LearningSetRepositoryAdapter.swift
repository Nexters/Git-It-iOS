import DataLearningProject
import DomainLearningProject

// MARK: - LearningSetRepositoryAdapter

struct LearningSetRepositoryAdapter: LearningSetRepository {

    // MARK: Lifecycle

    init(remote: LearningSetRemote) {
        self.remote = remote
    }

    // MARK: Internal

    func fetchSet(
        projectID: String,
        setID: String,
    ) async throws -> LearningSet {
        do {
            let response = try await remote.fetchLearningSet(projectID: projectID, setID: setID)
            return LearningSet(
                setID: response.setID,
                title: response.title,
                description: response.description,
                questions: response.questions.map(question(from:)),
            )
        } catch let error as DataLearningProjectError {
            throw domainError(for: error)
        }
    }

    // MARK: Private

    private let remote: LearningSetRemote

    private func question(from dto: QuestionResponseDTO) -> Question {
        Question(
            questionID: dto.questionID,
            prompt: dto.text,
            format: format(from: dto.format),
            choices: dto.choices.isEmpty ? nil : dto.choices,
            sources: dto.sources.map(source(from:)),
            myAnswer: dto.myAnswer.map(submittedAnswer(from:)),
        )
    }

    private func source(from dto: SourceResponseDTO) -> QuestionSource {
        QuestionSource(
            filePath: dto.file,
            startLine: dto.startLine,
            endLine: dto.endLine,
            symbol: dto.symbol,
            summary: dto.summary,
            referenceURL: dto.url,
        )
    }

    private func submittedAnswer(from dto: MyAnswerResponseDTO) -> SubmittedAnswer {
        SubmittedAnswer(
            selectedIndex: dto.selectedIndex,
            text: dto.text,
            correct: dto.correct,
        )
    }

    private func format(from raw: String) -> QuestionFormat {
        switch raw.lowercased() {
        case "essay": .essay
        default: .multipleChoice
        }
    }

    private func domainError(for error: DataLearningProjectError) -> LearningProjectError {
        switch error {
        case .invalidRequest:
            .invalidRequest

        case .unauthorized:
            .unauthorized

        case .projectUnavailable:
            .notFound

        case .questionUnavailable:
            .questionUnavailable

        case .learningSetUnavailable:
            .learningSetUnavailable

        case .temporarilyUnavailable,
             .transport:
            .temporarilyUnavailable

        case .decoding,
             .unexpectedStatus,
             .generationRetryUnavailable:
            .unexpected

        @unknown default:
            .unexpected
        }
    }

}
