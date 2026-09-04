import DomainMember

enum SettingsTestFixture {
    static let curatedProfile = profile(position: .backend, careerLevel: .entry)
    static let uncuratedProfile = profile(position: nil, careerLevel: nil)

    static let servicePolicyURLString =
        "https://git-it-service-policy.notion.site/Git-it-3bb7221e5fe78005bcd9fab953906df1"

    static func profile(
        position: MemberPosition?,
        careerLevel: CareerLevel?,
    ) -> MemberProfile {
        MemberProfile(
            name: "프로덕션에 푸시하는 고양이",
            email: "kimlee@github.io",
            position: position,
            careerLevel: careerLevel,
            statistics: LearningStatistics(
                thisWeekSolvedCount: 11,
                thisMonthSolvedCount: 27,
                streakDays: 4,
                weeklyCounts: [WeeklyLearningCount(dayLabel: "월", count: 3)],
            ),
        )
    }
}
