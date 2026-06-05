import SwiftUI
import WidgetKit

private let appGroupId = "group.com.example.kaimonoPlus.widgets"
private let widgetKind = "KaimonoWidget"

private enum WidgetDataKey {
    static let title = "kaimono_widget_title"
    static let items = "kaimono_widget_items"
    static let updatedAt = "kaimono_widget_updated_at"
    static let emptyMessage = "kaimono_widget_empty_message"
}

struct KaimonoWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let items: [String]
    let updatedAt: String
    let emptyMessage: String
}

struct KaimonoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> KaimonoWidgetEntry {
        KaimonoWidgetEntry(
            date: Date(),
            title: "買うものリスト",
            items: ["牛乳", "卵", "大根"],
            updatedAt: "今日 更新",
            emptyMessage: ""
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (KaimonoWidgetEntry) -> Void
    ) {
        completion(currentEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<KaimonoWidgetEntry>) -> Void
    ) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: Date()
        ) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> KaimonoWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let title = defaults?.string(forKey: WidgetDataKey.title) ?? "買うものリスト"
        let updatedAt = defaults?.string(forKey: WidgetDataKey.updatedAt) ?? ""
        let emptyMessage = defaults?.string(forKey: WidgetDataKey.emptyMessage) ?? "保存したリストがありません"
        let itemsJson = defaults?.string(forKey: WidgetDataKey.items) ?? "[]"
        let items = decodeItems(from: itemsJson)

        return KaimonoWidgetEntry(
            date: Date(),
            title: title,
            items: items,
            updatedAt: updatedAt,
            emptyMessage: emptyMessage
        )
    }

    private func decodeItems(from json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let items = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return items
    }
}

struct KaimonoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: KaimonoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "basket")
                    .font(.system(size: 16, weight: .semibold))
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .foregroundStyle(.black.opacity(0.86))

            if entry.items.isEmpty {
                Text(entry.emptyMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.48))
                    .lineLimit(2)
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                itemList
                .frame(maxHeight: .infinity, alignment: .top)
            }

            if !entry.updatedAt.isEmpty {
                Text(entry.updatedAt)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.48))
            }
        }
        .padding(14)
        .kaimonoWidgetBackground()
    }

    @ViewBuilder
    private var itemList: some View {
        if family == .systemMedium {
            let columns = splitItems(Array(entry.items.prefix(8)))
            HStack(alignment: .top, spacing: 14) {
                itemColumn(columns.left)
                itemColumn(columns.right)
            }
        } else {
            itemColumn(Array(entry.items.prefix(5)))
        }
    }

    private func itemColumn(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 9, weight: .semibold))
                    Text(item)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .foregroundStyle(.black.opacity(0.64))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func splitItems(_ items: [String]) -> (left: [String], right: [String]) {
        let midpoint = (items.count + 1) / 2
        return (
            Array(items.prefix(midpoint)),
            Array(items.dropFirst(midpoint))
        )
    }
}

@main
struct KaimonoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: widgetKind,
            provider: KaimonoWidgetProvider()
        ) { entry in
            KaimonoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("買うものリスト")
        .description("最後に保存・更新した買い物リストを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension View {
    @ViewBuilder
    func kaimonoWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(Color(red: 1.0, green: 0.92, blue: 0.33), for: .widget)
        } else {
            background(Color(red: 1.0, green: 0.92, blue: 0.33))
        }
    }
}
