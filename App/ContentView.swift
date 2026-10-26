import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var model = CountdownModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isEditing = false
    @State private var showsHelp = false
    @State private var confirmsDeletion = false
    @State private var clockRevision = 0
    @ScaledMetric(relativeTo: .largeTitle) private var numeralSize = 128

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if let event = model.event {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            countdown(event, now: context.date)
                        }
                        .id(clockRevision)
                        Button { isEditing = true } label: {
                            Label("Upravit událost", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .accessibilityIdentifier("editEvent")

                        widgetNote

                        Button("Smazat událost", role: .destructive) { confirmsDeletion = true }
                            .font(.subheadline)
                            .accessibilityIdentifier("deleteEvent")
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Odpočet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showsHelp = true } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("Jak přidat widget")
                }
            }
            .sheet(isPresented: $isEditing) {
                EventEditor(event: model.event, onSave: model.save)
            }
            .sheet(isPresented: $showsHelp) { WidgetHelpView() }
            .confirmationDialog("Smazat událost?", isPresented: $confirmsDeletion, titleVisibility: .visible) {
                Button("Smazat událost", role: .destructive, action: model.delete)
                Button("Zrušit", role: .cancel) {}
            } message: {
                Text("Odpočet se odstraní i ze všech widgetů.")
            }
            .alert("Něco se nepovedlo", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK") { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.reload()
                    clockRevision += 1
                } else if phase == .background { model.refreshWidgets() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                clockRevision += 1
                model.refreshWidgets()
            }
        }
    }

    private func countdown(_ event: CountdownEvent, now: Date) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.orange)
                .padding(.bottom, 10)
                .accessibilityHidden(true)
            Text(event.name)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("eventName")
            Text("\(event.remainingDays(at: now))")
                .font(.system(size: min(numeralSize, 180), weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.35)
                .lineLimit(1)
                .contentTransition(.numericText())
                .accessibilityIdentifier("remainingDays")
            Text(event.status(at: now))
                .font(.title3)
                .foregroundStyle(.secondary)
            Label(event.formattedDate(), systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.5), in: Capsule())
                .padding(.top, 8)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(.orange)
                .padding(.top, 40)
            VStack(spacing: 12) {
                Text("Na co se těšíš?")
                    .font(.largeTitle.weight(.semibold))
                Text("Jeden důležitý den.\nVždycky na očích.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            Button { isEditing = true } label: {
                Label("Nastavit událost", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 12)
            .accessibilityIdentifier("createEvent")
            widgetNote.padding(.top, 20)
        }
    }

    private var widgetNote: some View {
        Button { showsHelp = true } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "rectangle.3.group")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Odpočet na očích").font(.headline)
                    Text("Přidej si widget na plochu nebo zamykací obrazovku.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
            }
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
