import Testing

@testable import GitIt

@Suite("LocalizedText 문구 조회")
struct LocalizedTextTests {
    @Test
    func `생성 알림 문구는 카탈로그의 한국어 문구를 반환한다`() {
        #expect(LocalizedText.GenerationReminder.Completed.title == "세트 생성 완료")
        #expect(LocalizedText.GenerationReminder.Completed.body == "학습 세트 생성이 완료됐어요. 지금 확인해보세요.")
        #expect(LocalizedText.GenerationReminder.Failed.title == "세트 생성 실패")
        #expect(LocalizedText.GenerationReminder.Failed.body == "학습 세트를 만들지 못했어요. 앱에서 다시 시도해 주세요.")
    }
}
