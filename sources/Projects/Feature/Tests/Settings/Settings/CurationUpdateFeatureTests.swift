import ComposableArchitecture
import Testing

@testable import Feature

@MainActor
@Suite("CurationUpdateFeature 직군·연차 저장")
struct CurationUpdateFeatureTests {

    // MARK: Internal

    @Test
    func `직군 저장 성공은 대기 상태로 되돌리고 positionUpdated를 보낸다`() async {
        let updateMemberPosition = UserInfoUseCasePositionMock()
        let store = makeStore(updateMemberPosition: updateMemberPosition)

        await store.send(.input(.positionSelected(.ios))) {
            $0.positionMutation = .committing
        }
        await store.receive(.effect(.positionUpdateFinished(.ios, nil))) {
            $0.positionMutation = .idle
        }
        await store.receive(.delegate(.positionUpdated(.ios)))

        #expect(await updateMemberPosition.snapshot() == [.ios])
    }

    @Test
    func `연차 저장 성공은 대기 상태로 되돌리고 careerLevelUpdated를 보낸다`() async {
        let updateMemberCareerLevel = UserInfoUseCaseCareerLevelMock()
        let store = makeStore(updateMemberCareerLevel: updateMemberCareerLevel)

        await store.send(.input(.careerLevelSelected(.senior))) {
            $0.careerLevelMutation = .committing
        }
        await store.receive(.effect(.careerLevelUpdateFinished(.senior, nil))) {
            $0.careerLevelMutation = .idle
        }
        await store.receive(.delegate(.careerLevelUpdated(.senior)))

        #expect(await updateMemberCareerLevel.snapshot() == [.senior])
    }

    @Test
    func `저장 실패는 실패 상태를 남기고 delegate를 보내지 않는다`() async {
        let store = makeStore(
            updateMemberPosition: UserInfoUseCasePositionMock(errors: [.temporarilyUnavailable])
        )

        await store.send(.input(.positionSelected(.ios))) {
            $0.positionMutation = .committing
        }
        await store.receive(.effect(.positionUpdateFinished(.ios, .temporarilyUnavailable))) {
            $0.positionMutation = .failed(.temporarilyUnavailable)
        }
    }

    @Test
    func `직군 저장 중에는 직군 선택을 다시 보내지 않는다`() async {
        let updateMemberPosition = UserInfoUseCasePositionMock()
        let store = makeStore(
            state: CurationUpdateFeature.State(positionMutation: .committing),
            updateMemberPosition: updateMemberPosition,
        )

        await store.send(.input(.positionSelected(.ios)))

        #expect(await updateMemberPosition.snapshot().isEmpty)
    }

    @Test
    func `연차 저장 중에는 연차 선택을 다시 보내지 않는다`() async {
        let updateMemberCareerLevel = UserInfoUseCaseCareerLevelMock()
        let store = makeStore(
            state: CurationUpdateFeature.State(careerLevelMutation: .committing),
            updateMemberCareerLevel: updateMemberCareerLevel,
        )

        await store.send(.input(.careerLevelSelected(.senior)))

        #expect(await updateMemberCareerLevel.snapshot().isEmpty)
    }

    // MARK: Private

    private func makeStore(
        state: CurationUpdateFeature.State = CurationUpdateFeature.State(),
        updateMemberPosition: UserInfoUseCasePositionMock = UserInfoUseCasePositionMock(),
        updateMemberCareerLevel: UserInfoUseCaseCareerLevelMock = UserInfoUseCaseCareerLevelMock(),
    ) -> TestStoreOf<CurationUpdateFeature> {
        TestStore(initialState: state) {
            CurationUpdateFeature(
                updatePosition: updateMemberPosition.updatePosition,
                updateCareerLevel: updateMemberCareerLevel.updateCareerLevel,
            )
        }
    }

}
