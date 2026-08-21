import DesignSystem
import SwiftUI

struct ComponentPreviewCatalog: View {

    // MARK: Internal

    var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement()
                .accessibilityIdentifier("component.preview.catalog")

            ScrollView {
                VStack(alignment: .leading, spacing: LayoutToken.margin.cgFloatValue) {
                    environmentMarkers
                    routeMarkers
                    ComponentPreviewFixtures(environment: environment)
                }
                .designSystemScreenMargin()
                .padding(.vertical, LayoutToken.margin.cgFloatValue)
            }
        }
        .designSystemBackground(.grey700)
        .dynamicTypeSize(environment.usesMaximumDynamicType ? .accessibility5 : .large)
        .preferredColorScheme(environment.isDark ? .dark : .light)
    }

    // MARK: Private

    private let environment = ComponentPreviewEnvironment.process

    private var environmentMarkers: some View {
        VStack(alignment: .leading) {
            marker("component.preview.environment.appearance.\(environment.isDark ? "dark" : "light")")
            marker("component.preview.environment.dynamicType.\(environment.usesMaximumDynamicType ? "maximum" : "standard")")
            marker("component.preview.environment.reduceMotion.\(environment.reducesMotion ? "enabled" : "disabled")")
            marker("component.preview.environment.fallback.\(environment.usesResourceFallback ? "enabled" : "disabled")")
        }
    }

    private var routeMarkers: some View {
        ForEach(ComponentPreviewFixtures.entries) { entry in
            marker("component.preview.route.\(entry.componentID)")
        }
    }

    private func marker(_ identifier: String) -> some View {
        Text(identifier)
            .font(.caption2)
            .accessibilityIdentifier(identifier)
    }

}
