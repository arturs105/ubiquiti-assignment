import SwiftUI

@main struct UbiquitiAssignmentApp: App {
    /// Built once for the life of the process; the App is never re-instantiated, so no `@State` is needed.
    private let dependencies = Dependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
