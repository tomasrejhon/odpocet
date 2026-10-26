import Foundation

/// A civil date stays on the same calendar day when the user travels.
struct EventDay: Codable, Equatable {
    let year: Int
    let month: Int
    let day: Int

    static func calendar(timeZone: TimeZone = .autoupdatingCurrent) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    init(_ date: Date, calendar: Calendar = Self.calendar()) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year!
        month = parts.month!
        day = parts.day!
    }

    func date(in calendar: Calendar = Self.calendar()) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    var isValid: Bool {
        let calendar = Self.calendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return false
        }
        return EventDay(date, calendar: calendar) == self
    }
}

struct CountdownEvent: Codable, Equatable {
    let name: String
    let targetDay: EventDay

    static let maximumDays = 36_500
    static let maximumNameLength = 60

    init(name: String, targetDay: EventDay) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count <= Self.maximumNameLength else {
            throw CountdownError.invalidName
        }
        guard targetDay.isValid else { throw CountdownError.invalidDate }
        self.name = trimmedName
        self.targetDay = targetDay
    }

    init(name: String, days: Int, now: Date = .now, calendar: Calendar = EventDay.calendar()) throws {
        guard (0...Self.maximumDays).contains(days),
              let date = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) else {
            throw CountdownError.invalidDays
        }
        try self.init(name: name, targetDay: EventDay(date, calendar: calendar))
    }

    // Validate decoded data too; damaged shared storage must not crash the widget.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(name: values.decode(String.self, forKey: .name),
                      targetDay: values.decode(EventDay.self, forKey: .targetDay))
    }

    func signedDays(from now: Date = .now, calendar: Calendar = EventDay.calendar()) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                to: targetDay.date(in: calendar)).day ?? 0
    }

    func remainingDays(at now: Date = .now, calendar: Calendar = EventDay.calendar()) -> Int {
        max(0, signedDays(from: now, calendar: calendar))
    }

    func status(at now: Date = .now, calendar: Calendar = EventDay.calendar()) -> String {
        let days = signedDays(from: now, calendar: calendar)
        if days < 0 { return "Událost proběhla" }
        if days == 0 { return "Je to dnes" }
        return Self.dayLabel(days)
    }

    static func dayLabel(_ days: Int) -> String {
        switch days {
        case 1: return "den zbývá"
        case 2...4: return "dny zbývají"
        default: return "dní zbývá"
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.calendar = EventDay.calendar()
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: targetDay.date())
    }

    static var sample: CountdownEvent { try! CountdownEvent(name: "Dovolená", days: 28) }
}

enum CountdownError: LocalizedError {
    case invalidName, invalidDate, invalidDays, sharedContainerUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidName: return "Název musí mít 1 až 60 znaků."
        case .invalidDate: return "Vyber platné datum."
        case .invalidDays: return "Zadej počet dní od 0 do 36 500."
        case .sharedContainerUnavailable:
            return "Sdílené úložiště není dostupné. V Xcode zkontroluj stejnou App Group u aplikace i widgetu."
        }
    }
}

enum CountdownSchedule {
    /// Calendar arithmetic handles 23- and 25-hour days correctly.
    static func dates(from now: Date, calendar: Calendar = EventDay.calendar(), days: Int = 35) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return [now] + (1...max(1, days)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
}
