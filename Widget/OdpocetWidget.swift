import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    let event: CountdownEvent?
    var unavailable = false
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, event: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let entry = currentEntry()
        let dates = CountdownSchedule.dates(from: entry.date)
        let entries = dates.map { CountdownEntry(date: $0, event: entry.event, unavailable: entry.unavailable) }
        // Keep several weeks ready even if iOS delays the next daily reload.
        completion(Timeline(entries: entries, policy: .after(dates[1])))
    }

    private func currentEntry() -> CountdownEntry {
        do { return CountdownEntry(date: .now, event: try EventStore().load()) }
        catch { return CountdownEntry(date: .now, event: nil, unavailable: true) }
    }
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: CountdownEntry

    // Clear/Tinted and Lock Screen rendering supply their own material and contrast.
    private var detailColor: Color { renderingMode == .fullColor ? .secondary : .primary }

    var body: some View {
        Group {
            if let event = entry.event {
                eventView(event)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(event.name), \(event.remainingDays(at: entry.date)), \(event.status(at: entry.date)), \(event.formattedDate())")
            } else {
                emptyView
            }
        }
        .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private func eventView(_ event: CountdownEvent) -> some View {
        switch family {
        case .accessoryInline:
            if event.remainingDays(at: entry.date) == 0 {
                Text("\(event.name) · \(event.signedDays(from: entry.date) == 0 ? "dnes" : "hotovo")")
            } else {
                Text("\(event.name) · \(event.remainingDays(at: entry.date)) \(shortDayLabel(event))")
            }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(event.remainingDays(at: entry.date))")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                    Text(event.remainingDays(at: entry.date) == 0 ? (event.signedDays(from: entry.date) == 0 ? "dnes" : "hotovo") : shortDayLabel(event))
                        .font(.system(size: 10, weight: .medium))
                }
                .lineLimit(1)
                .padding(5)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text(event.name).font(.headline).lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(event.remainingDays(at: entry.date))")
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    Text(event.status(at: entry.date)).font(.caption)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemMedium:
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    number(event, size: 64)
                    Text(event.status(at: entry.date)).font(.caption).foregroundStyle(detailColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "hourglass").foregroundStyle(.orange).widgetAccentable()
                    Text(event.name).font(.headline).lineLimit(2)
                    Text(event.formattedDate()).font(.caption).foregroundStyle(detailColor).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        default:
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top) {
                    Text(event.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                    Spacer(minLength: 4)
                    Image(systemName: "hourglass").font(.caption).foregroundStyle(.orange).widgetAccentable()
                }
                Spacer(minLength: 0)
                number(event, size: 62)
                Text(event.status(at: entry.date))
                    .font(.caption).foregroundStyle(detailColor).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func number(_ event: CountdownEvent, size: CGFloat) -> some View {
        Text("\(event.remainingDays(at: entry.date))")
            .font(.system(size: size, weight: renderingMode == .accented ? .regular : .light, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    private func shortDayLabel(_ event: CountdownEvent) -> String {
        switch event.remainingDays(at: entry.date) {
        case 1: return "den"
        case 2...4: return "dny"
        default: return "dní"
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        let message = entry.unavailable ? "Otevři aplikaci Odpočet" : "Nastav si událost"
        switch family {
        case .accessoryInline:
            Text("Odpočet · \(message)")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "hourglass.badge.plus").font(.title2)
            }
            .accessibilityLabel(message)
        default:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "hourglass").foregroundStyle(detailColor)
                Text(message).font(.headline)
                if family == .systemSmall || family == .systemMedium {
                    Text("Jeden důležitý den. Vždycky na očích.")
                        .font(.caption).foregroundStyle(detailColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@main
struct OdpocetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: EventStore.widgetKind, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Odpočet")
        .description("Jedna událost. Každý den o kousek blíž.")
        .containerBackgroundRemovable(true)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        .disfavoredLocations([.iPhoneWidgetsOnMac], for: [.systemSmall, .systemMedium])
    }
}

struct CountdownWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CountdownWidgetView(entry: CountdownEntry(date: .now, event: .sample))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Plocha – malý")
            CountdownWidgetView(entry: CountdownEntry(date: .now, event: .sample))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Plocha – střední")
            CountdownWidgetView(entry: CountdownEntry(date: .now, event: .sample))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Zamykací obrazovka")
            CountdownWidgetView(entry: CountdownEntry(date: .now, event: .sample))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Kruh")
            CountdownWidgetView(entry: CountdownEntry(date: .now, event: .sample))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Řádek nad hodinami")
        }
    }
}
