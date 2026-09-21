import SwiftUI
import Testing

@testable import UIComponent

@Suite("LabeledTextField 계약")
@MainActor
struct LabeledTextFieldTests {

    // MARK: Internal

    @Test
    func `상태 모델을 넘기지 않으면 오류 없이 기본 키보드와 입력 보정으로 그린다`() throws {
        let stateModel = try #require(storedStateModel(of: LabeledTextField(displayModel: displayModel, text: .constant(""))))

        #expect(stateModel.isError == false)
        #expect(stateModel.keyboardType == .default)
        #expect(stateModel.autocorrectionDisabled == false)
    }

    @Test
    func `넘긴 상태 모델로 오류와 입력 설정을 정한다`() throws {
        let field = LabeledTextField(
            displayModel: displayModel,
            text: .constant(""),
            stateModel: .init(
                isError: true,
                keyboardType: .URL,
                textInputAutocapitalization: .never,
                autocorrectionDisabled: true,
            ),
        )
        let stateModel = try #require(storedStateModel(of: field))

        #expect(stateModel.isError)
        #expect(stateModel.keyboardType == .URL)
        #expect(stateModel.autocorrectionDisabled)
    }

    // MARK: Private

    private let displayModel = LabeledTextField.DisplayModel(label: "링크", placeholder: "https://github.com")

    private func storedStateModel(of field: LabeledTextField) -> LabeledTextField.StateModel? {
        Mirror(reflecting: field).descendant("stateModel") as? LabeledTextField.StateModel
    }

}
