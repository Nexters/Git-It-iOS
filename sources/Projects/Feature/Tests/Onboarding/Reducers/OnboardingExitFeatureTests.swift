import Testing

@testable import Feature

@Suite("OnboardingExitFeature")
struct OnboardingExitFeatureTests {

    @Test
    func `curationSucceeded input을 받으면 shouldExit delegate를 발생시킨다`() async {
        let store = makeOnboardingExitStore()

        await store.send(.input(.curationSucceeded))
        await store.receive(.delegate(.shouldExit))
    }

}
