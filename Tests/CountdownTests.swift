import XCTest
#if canImport(CountdownCore)
@testable import CountdownCore
#else
@testable import Odpocet
#endif

final class CountdownTests: XCTestCase {
    private var prague: Calendar { EventDay.calendar(timeZone: TimeZone(identifier: "Europe/Prague")!) }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12,
                      calendar: Calendar? = nil) -> Date {
        (calendar ?? prague).date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testCalendarDaysInsteadOf24HourIntervals() throws {
        let now = date(2026, 10, 26, hour: 23)
        let event = try CountdownEvent(name: "Výlet", days: 1, now: now, calendar: prague)
        XCTAssertEqual(event.remainingDays(at: now, calendar: prague), 1)
        XCTAssertEqual(event.remainingDays(at: date(2026, 10, 27, hour: 0), calendar: prague), 0)
    }

    func testSpringAndAutumnDaylightSavingChanges() throws {
        for (month, day) in [(3, 28), (10, 24)] {
            let now = date(2026, month, day)
            let event = try CountdownEvent(name: "Změna času", days: 2, now: now, calendar: prague)
            XCTAssertEqual(event.remainingDays(at: now, calendar: prague), 2)
            XCTAssertEqual(event.remainingDays(at: date(2026, month, day + 1), calendar: prague), 1)
            XCTAssertEqual(event.remainingDays(at: date(2026, month, day + 2), calendar: prague), 0)
        }
    }

    func testTodayAndPastStopAtZero() throws {
        let now = date(2026, 10, 26)
        let event = try CountdownEvent(name: "Dnes", days: 0, now: now, calendar: prague)
        XCTAssertEqual(event.remainingDays(at: now, calendar: prague), 0)
        XCTAssertEqual(event.status(at: now, calendar: prague), "Je to dnes")
        XCTAssertEqual(event.remainingDays(at: date(2026, 11, 10), calendar: prague), 0)
        XCTAssertEqual(event.status(at: date(2026, 11, 10), calendar: prague), "Událost proběhla")
    }

    func testLeapDayAndYearBoundary() throws {
        let leap = try CountdownEvent(name: "Přestupný rok", days: 2, now: date(2028, 2, 28), calendar: prague)
        XCTAssertEqual(leap.targetDay, EventDay(date(2028, 3, 1), calendar: prague))
        let year = try CountdownEvent(name: "Nový rok", days: 1, now: date(2026, 12, 31), calendar: prague)
        XCTAssertEqual(year.targetDay, EventDay(date(2027, 1, 1), calendar: prague))
    }

    func testCivilDateSurvivesTravel() throws {
        let event = try CountdownEvent(name: "Odlet", days: 2, now: date(2026, 10, 26), calendar: prague)
        let tokyo = EventDay.calendar(timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        XCTAssertEqual(event.remainingDays(at: date(2026, 10, 27, calendar: tokyo), calendar: tokyo), 1)
        XCTAssertEqual(event.targetDay, EventDay(date(2026, 10, 28, calendar: tokyo), calendar: tokyo))
    }

    func testNameValidation() throws {
        XCTAssertThrowsError(try CountdownEvent(name: " \n ", days: 2))
        XCTAssertThrowsError(try CountdownEvent(name: String(repeating: "a", count: 61), days: 2))
        XCTAssertEqual(try CountdownEvent(name: "  Dovolená  ", days: 2).name, "Dovolená")
    }

    func testDayCountValidation() throws {
        XCTAssertThrowsError(try CountdownEvent(name: "Test", days: -1))
        XCTAssertThrowsError(try CountdownEvent(name: "Test", days: 36_501))
        XCTAssertNoThrow(try CountdownEvent(name: "Test", days: 36_500))
    }

    func testCzechDayLabels() {
        XCTAssertEqual(CountdownEvent.dayLabel(1), "den zbývá")
        XCTAssertEqual(CountdownEvent.dayLabel(2), "dny zbývají")
        XCTAssertEqual(CountdownEvent.dayLabel(4), "dny zbývají")
        XCTAssertEqual(CountdownEvent.dayLabel(5), "dní zbývá")
        XCTAssertEqual(CountdownEvent.dayLabel(21), "dní zbývá")
    }

    func testInvalidDecodedDateIsRejected() {
        let data = Data(#"{"name":"Test","targetDay":{"year":2026,"month":2,"day":30}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(CountdownEvent.self, from: data))
    }

    func testInvalidDecodedNameIsRejected() {
        let data = Data(#"{"name":" ","targetDay":{"year":2026,"month":2,"day":28}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(CountdownEvent.self, from: data))
    }

    func testRoundTrip() throws {
        let event = try CountdownEvent(name: "Dovolená 🌴", days: 28)
        XCTAssertEqual(try JSONDecoder().decode(CountdownEvent.self, from: JSONEncoder().encode(event)), event)
    }

    func testStoreHasExactlyOneEventAndSharesChanges() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let appStore = EventStore(directory: directory)
        let widgetStore = EventStore(directory: directory)
        XCTAssertNil(try appStore.load())
        let first = try CountdownEvent(name: "První", days: 28)
        let second = try CountdownEvent(name: "Druhá", days: 7)
        try appStore.save(first)
        XCTAssertEqual(try widgetStore.load(), first)
        try appStore.save(second)
        XCTAssertEqual(try widgetStore.load(), second)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["event.json"])
        try appStore.delete()
        XCTAssertNil(try widgetStore.load())
        XCTAssertNoThrow(try appStore.delete())
    }

    func testCorruptedStoreReportsError() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("invalid JSON".utf8).write(to: directory.appendingPathComponent("event.json"))
        XCTAssertThrowsError(try EventStore(directory: directory).load())
    }

    func testTimelineUsesLocalMidnightsAcrossDST() {
        let now = date(2026, 3, 28, hour: 23)
        let dates = CountdownSchedule.dates(from: now, calendar: prague, days: 4)
        XCTAssertEqual(dates.count, 5)
        XCTAssertEqual(dates[0], now)
        for entry in dates.dropFirst() { XCTAssertEqual(prague.component(.hour, from: entry), 0) }
        XCTAssertEqual(dates[2].timeIntervalSince(dates[1]), 23 * 60 * 60)
    }
}
