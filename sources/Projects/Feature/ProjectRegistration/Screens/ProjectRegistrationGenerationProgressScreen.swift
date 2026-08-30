import DesignSystem
import SwiftUI
import UIComponent

struct ProjectRegistrationGenerationProgressScreen: View {

    let onWaitAtHome: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: Constant.textSetSpacing) {
                Spacer(minLength: Constant.topSpacerMinLength)

                VStack(spacing: Constant.textSetSpacing) {
                    StyledText.subtitle1("학습세트를 만들고 있어요", alignment: .center)
                    StyledText.body2("약 5분의 시간이 소요돼요", color: .grey400, alignment: .center)
                }

                checklist
                    .padding(.top, Constant.checklistTopPadding)

                Spacer(minLength: 0)
            }
            .designSystemScreenMargin()

            ActionButton.text("홈에서 기다리기", action: onWaitAtHome)
                .designSystemScreenMargin()
                .padding(.bottom, Constant.bottomButtonPadding)
        }
        .designSystemBackground(.gradient2)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: Constant.checklistRowSpacing) {
            checklistRow(title: "프로젝트 정보 확인", status: .done)
            checklistRow(title: "코드 구조 분석", status: .active)
            checklistRow(title: "학습 개념 구성", status: .pending)
            checklistRow(title: "문제 생성", status: .pending)
            checklistRow(title: "세트 검증", status: .pending)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("학습 세트 생성 진행 체크리스트")
    }

    private func checklistRow(title: String, status: ChecklistStatus) -> some View {
        HStack(spacing: LayoutToken.gutter.cgFloatValue) {
            ResourceImage(asset: .icon(status.icon))
                .frame(width: Constant.checklistIconSize, height: Constant.checklistIconSize)
            StyledText.body2(title, color: status == .pending ? .grey400 : .grey100)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(status.accessibilityDescription)")
    }

    private enum ChecklistStatus: Equatable {
        case done
        case active
        case pending

        var icon: ResourceImage.Asset.Icon {
            switch self {
            case .done: .statusCheck
            case .active: .statusLoading
            case .pending: .statusLoadingDisabled
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .done: "완료"
            case .active: "진행 중"
            case .pending: "대기 중"
            }
        }
    }

}

extension ProjectRegistrationGenerationProgressScreen {
    private enum Constant {
        static let topSpacerMinLength: CGFloat = 96
        static let textSetSpacing: CGFloat = 16
        static let checklistTopPadding: CGFloat = 24
        static let checklistRowSpacing: CGFloat = 19
        static let checklistIconSize: CGFloat = 24
        static let bottomButtonPadding: CGFloat = 58
    }
}
