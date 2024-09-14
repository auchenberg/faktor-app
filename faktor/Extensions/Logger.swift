import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem: String = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let core: Logger = Logger(subsystem: subsystem, category: "core")
}
