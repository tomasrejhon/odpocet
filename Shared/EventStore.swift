import Foundation

/// The app is the sole writer. Atomic replacement lets the widget always read a complete event.
struct EventStore {
    static let widgetKind = "OdpocetWidget"
    private let directory: URL?

    init() {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "SharedAppGroup") as? String else {
            directory = nil
            return
        }
        directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    init(directory: URL) { self.directory = directory }

    private func fileURL() throws -> URL {
        guard let directory else { throw CountdownError.sharedContainerUnavailable }
        return directory.appendingPathComponent("event.json")
    }

    func load() throws -> CountdownEvent? {
        let url = try fileURL()
        do {
            return try JSONDecoder().decode(CountdownEvent.self, from: Data(contentsOf: url))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    func save(_ event: CountdownEvent) throws {
        let url = try fileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(event)
        #if os(iOS)
        // Available on the Lock Screen after the first device unlock following a restart.
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }

    func delete() throws {
        let url = try fileURL()
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        }
    }
}
