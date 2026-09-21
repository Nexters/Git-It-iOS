import SwiftUI
import Testing
import UIKit

@testable import UIComponent

@Suite("LabeledTextField 상태 선언")
@MainActor
struct LabeledTextFieldTests {

    // MARK: Internal

    @Test
    func `오류를 선언하지 않으면 오류가 없는 상태로 그린다`() {
        #expect(isError(of: LabeledTextField(displayModel: displayModel, text: .constant(""))) == false)
    }

    @Test
    func `error로 오류를 선언하면 표시 값을 유지한 채 오류 상태로 그린다`() {
        let field = LabeledTextField(displayModel: displayModel, text: .constant("")).error(true)

        #expect(isError(of: field) == true)
        #expect(Mirror(reflecting: field).descendant("displayModel") as? LabeledTextField.DisplayModel == displayModel)
    }

    @Test
    func `호출부가 붙인 SwiftUI 입력 수정자는 안쪽 입력 필드에 적용된다`() throws {
        let field = LabeledTextField(displayModel: displayModel, text: .constant(""))
            .error(true)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        let textField = try #require(renderedTextField(of: field))

        #expect(textField.keyboardType == .URL)
        #expect(textField.autocapitalizationType == .none)
        #expect(textField.autocorrectionType == .no)
    }

    // MARK: Private

    private let displayModel = LabeledTextField.DisplayModel(label: "링크", placeholder: "https://github.com")

    private func isError(of field: LabeledTextField) -> Bool? {
        Mirror(reflecting: field).descendant("isError") as? Bool
    }

    private func renderedTextField(of view: some View) -> UITextField? {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
        let host = UIHostingController(rootView: view)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        return firstTextField(in: host.view)
    }

    private func firstTextField(in view: UIView) -> UITextField? {
        if let textField = view as? UITextField {
            return textField
        }
        return view.subviews.lazy.compactMap { firstTextField(in: $0) }.first
    }

}
