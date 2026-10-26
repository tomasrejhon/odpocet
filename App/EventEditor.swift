import SwiftUI

struct EventEditor: View {
    private enum InputMode: String, CaseIterable { case days = "Počet dní", date = "Datum" }
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var days: String
    @State private var date: Date
    @State private var mode: InputMode
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    private enum Field { case name, days }
    private let isNew: Bool
    let onSave: (CountdownEvent) throws -> Void

    init(event: CountdownEvent?, onSave: @escaping (CountdownEvent) throws -> Void) {
        isNew = event == nil
        self.onSave = onSave
        _name = State(initialValue: event?.name ?? "")
        _days = State(initialValue: event.map { String($0.remainingDays()) } ?? "30")
        _date = State(initialValue: event?.targetDay.date() ?? EventDay.calendar().date(byAdding: .day, value: 30, to: .now)!)
        _mode = State(initialValue: event == nil ? .days : .date)
    }

    private var candidate: CountdownEvent? {
        if mode == .days {
            guard let count = Int(days) else { return nil }
            return try? CountdownEvent(name: name, days: count)
        }
        return try? CountdownEvent(name: name, targetDay: EventDay(date))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Na co se těšíš?") {
                    TextField("Třeba dovolená", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .name)
                        .accessibilityIdentifier("nameField")
                        .onChange(of: name) { _, value in
                            if value.count > CountdownEvent.maximumNameLength {
                                name = String(value.prefix(CountdownEvent.maximumNameLength))
                            }
                        }
                }
                Section {
                    Picker("Odpočet podle", selection: $mode) {
                        ForEach(InputMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { previous, next in
                        focusedField = nil
                        if previous == .days, next == .date, let count = Int(days),
                           (0...CountdownEvent.maximumDays).contains(count),
                           let newDate = EventDay.calendar().date(byAdding: .day, value: count, to: .now) {
                            date = newDate
                        } else if previous == .date, next == .days {
                            let count = EventDay.calendar().dateComponents([.day],
                                from: EventDay.calendar().startOfDay(for: .now),
                                to: EventDay.calendar().startOfDay(for: date)).day ?? 0
                            days = String(max(0, count))
                        }
                    }
                    if mode == .days {
                        HStack {
                            Text("Zbývá dní")
                            Spacer()
                            TextField("30", text: $days)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .days)
                                .accessibilityIdentifier("daysField")
                                .onChange(of: days) { _, value in
                                    days = String(value.filter { $0.isASCII && $0.isNumber }.prefix(5))
                                }
                        }
                    } else {
                        DatePicker("Den události", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .environment(\.calendar, EventDay.calendar())
                    }
                } header: {
                    Text("Kdy to bude?")
                } footer: {
                    if mode == .days, Int(days).map({ (0...CountdownEvent.maximumDays).contains($0) }) != true {
                        Text("Zadej 0 až 36 500 dní. Nula znamená dnešek.")
                    } else if let candidate {
                        Text("\(candidate.formattedDate()). Odpočet se mění každý den o půlnoci.")
                    } else {
                        Text("Nula dní znamená dnešek.")
                    }
                }
                Section {
                    Label("Jedna událost, všechny tvoje widgety.", systemImage: "rectangle.3.group")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isNew ? "Nová událost" : "Upravit událost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit", action: save)
                        .fontWeight(.semibold)
                        .disabled(candidate == nil)
                        .accessibilityIdentifier("saveEvent")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") { focusedField = nil }
                }
            }
            .alert("Událost se neuložila", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func save() {
        guard let candidate else { return }
        do {
            try onSave(candidate)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
