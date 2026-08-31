import SwiftUI

#Preview("Project Present - 1465:19015") {
    HomeScreen(store: HomePreviewSupport.projectPresent)
        .frame(width: 360, height: 800)
}

#Preview("Project Absent - 1542:19610") {
    HomeScreen(store: HomePreviewSupport.projectAbsent)
        .frame(width: 360, height: 800)
}

#Preview("Loading") {
    HomeScreen(store: HomePreviewSupport.loading)
        .frame(width: 360, height: 800)
}

#Preview("Project Failure as Empty - 1542:19610") {
    HomeScreen(store: HomePreviewSupport.projectFailure)
        .frame(width: 360, height: 800)
}

#Preview("Profile Failure") {
    HomeScreen(store: HomePreviewSupport.profileFailure)
        .frame(width: 360, height: 800)
}
