// MARK: - DesignTokenSet

public struct DesignTokenSet: Sendable {

    // MARK: Lifecycle

    public init(
        colors: [ColorToken],
        gradients: [GradientToken],
        fontFamilies: [FontFamilyToken],
        textStyles: [TextStyleToken],
        layouts: [LayoutToken],
        opacities: [OpacityToken],
        cornerRadii: [CornerRadiusToken],
        borders: [BorderToken],
        effects: [EffectToken],
        controlSizes: [ControlSizeToken],
    ) {
        self.colors = colors
        self.gradients = gradients
        self.fontFamilies = fontFamilies
        self.textStyles = textStyles
        self.layouts = layouts
        self.opacities = opacities
        self.cornerRadii = cornerRadii
        self.borders = borders
        self.effects = effects
        self.controlSizes = controlSizes
    }

    // MARK: Public

    public let colors: [ColorToken]
    public let gradients: [GradientToken]
    public let fontFamilies: [FontFamilyToken]
    public let textStyles: [TextStyleToken]
    public let layouts: [LayoutToken]
    public let opacities: [OpacityToken]
    public let cornerRadii: [CornerRadiusToken]
    public let borders: [BorderToken]
    public let effects: [EffectToken]
    public let controlSizes: [ControlSizeToken]

}

extension DesignTokenSet {
    public static let current = DesignTokenSet(
        colors: ColorToken.all,
        gradients: GradientToken.all,
        fontFamilies: FontFamilyToken.all,
        textStyles: TextStyleToken.all,
        layouts: LayoutToken.all,
        opacities: OpacityToken.all,
        cornerRadii: CornerRadiusToken.all,
        borders: BorderToken.all,
        effects: EffectToken.all,
        controlSizes: ControlSizeToken.all,
    )
}

extension DesignTokenSet {

    // MARK: Public

    public enum ValidationError: Error, Equatable {
        case duplicateName(category: String, name: String)
        case outOfRange(category: String, name: String, detail: String)
        case danglingReference(category: String, name: String, reference: String)
    }

    public func validate() -> [ValidationError] {
        var errors = [ValidationError]()

        errors += Self.duplicateNameErrors(
            category: "ColorToken",
            names: colors.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "GradientToken",
            names: gradients.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "FontFamilyToken",
            names: fontFamilies.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "TextStyleToken",
            names: textStyles.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "LayoutToken",
            names: layouts.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "OpacityToken",
            names: opacities.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "CornerRadiusToken",
            names: cornerRadii.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "BorderToken",
            names: borders.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "EffectToken",
            names: effects.map(\.name)
        )
        errors += Self.duplicateNameErrors(
            category: "ControlSizeToken",
            names: controlSizes.map(\.name)
        )

        for gradient in gradients {
            for stop in gradient.stops where !(0...1).contains(stop.position) {
                errors.append(
                    .outOfRange(
                        category: "GradientToken",
                        name: gradient.name,
                        detail: "stop position \(stop.position) not in 0...1",
                    )
                )
            }
        }
        for opacity in opacities where !(0...100).contains(opacity.percent) {
            errors.append(.outOfRange(
                category: "OpacityToken",
                name: opacity.name,
                detail: "percent \(opacity.percent) not in 0...100",
            )
            )
        }
        for controlSize in controlSizes where controlSize.value < 44 {
            errors.append(.outOfRange(
                category: "ControlSizeToken",
                name: controlSize.name,
                detail: "value \(controlSize.value) < 44",
            )
            )
        }

        let colorNames = Set(colors.map(\.name))
        for border in borders where !colorNames.contains(border.colorToken.name) {
            errors.append(.danglingReference(
                category: "BorderToken",
                name: border.name,
                reference: border.colorToken.name
            )
            )
        }
        for effect in effects where !colorNames.contains(effect.colorToken.name) {
            errors.append(.danglingReference(
                category: "EffectToken",
                name: effect.name,
                reference: effect.colorToken.name
            )
            )
        }

        return errors
    }

    // MARK: Private

    private static func duplicateNameErrors(
        category: String,
        names: [String],
    ) -> [ValidationError] {
        var seen = Set<String>()
        var errors = [ValidationError]()
        for name in names {
            if !seen.insert(name).inserted {
                errors.append(.duplicateName(
                    category: category,
                    name: name
                ))
            }
        }
        return errors
    }

}
