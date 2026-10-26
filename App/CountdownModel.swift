import SwiftUI
import WidgetKit

@MainActor
final class CountdownModel: ObservableObject {
    @Published private(set) var event: CountdownEvent?
    @Published var errorMessage: String?
    private let store: EventStore

    init(store: EventStore = EventStore()) {
        self.store = store
        reload()
    }

    func reload() {
        do { event = try store.load() }
        catch { errorMessage = error.localizedDescription }
    }

    func save(_ event: CountdownEvent) throws {
        try store.save(event)
        self.event = event
        refreshWidgets()
    }

    func delete() {
        do {
            try store.delete()
            event = nil
            refreshWidgets()
        } catch { errorMessage = error.localizedDescription }
    }

    func refreshWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: EventStore.widgetKind)
    }
}
