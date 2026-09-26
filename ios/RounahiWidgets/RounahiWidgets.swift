import SwiftUI
import WidgetKit
import Foundation

struct RounahiEntry: TimelineEntry {
    let date: Date
    let brand: String
    let arabic: String
    let translation: String
    let topic: String
    let ayahId: String
    let wordId: String
    let topicId: String
}

struct RounahiProvider: TimelineProvider {
    func placeholder(in context: Context) -> RounahiEntry {
        sample
    }

    func getSnapshot(in context: Context, completion: @escaping (RounahiEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RounahiEntry>) -> Void) {
        let timeline = Timeline(entries: [load()], policy: .after(Date().addingTimeInterval(60 * 30)))
        completion(timeline)
    }

    private var sample: RounahiEntry {
        RounahiEntry(
            date: Date(),
            brand: "رووناهى",
            arabic: "وَقُل رَّبِّ زِدْنِي عِلْمًا",
            translation: "و بڵێ: پەروەردگارم، زانستم زیاد بکە.",
            topic: "زانست",
            ayahId: "20-114",
            wordId: "word-ilm",
            topicId: "topic-ilm"
        )
    }

    private func load() -> RounahiEntry {
        let defaults = UserDefaults(suiteName: "group.com.rounahi.rounahi")
        return RounahiEntry(
            date: Date(),
            brand: defaults?.string(forKey: "brand") ?? sample.brand,
            arabic: defaults?.string(forKey: "ayah_arabic") ?? sample.arabic,
            translation: defaults?.string(forKey: "ayah_translation") ?? sample.translation,
            topic: defaults?.string(forKey: "topic_title") ?? sample.topic,
            ayahId: defaults?.string(forKey: "ayah_id") ?? sample.ayahId,
            wordId: defaults?.string(forKey: "word_id") ?? sample.wordId,
            topicId: defaults?.string(forKey: "topic_id") ?? sample.topicId
        )
    }
}

struct RounahiWidgetChrome<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.layoutDirection, .rightToLeft)
            .containerBackground(for: .widget) {
                Color(red: 0.043, green: 0.165, blue: 0.290)
            }
    }
}

struct TodayAyahWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayAyahWidget", provider: RounahiProvider()) { entry in
            RounahiWidgetChrome {
                VStack(spacing: 8) {
                    Text(entry.brand).font(.caption.bold()).foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.36))
                    Text(entry.arabic).multilineTextAlignment(.center).foregroundStyle(.white)
                    Text(entry.translation).font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.9))
                }
            }
            .widgetURL(URL(string: "rounahi://app/verses/\(entry.ayahId)"))
        }
        .configurationDisplayName("ئایەتی ئەمڕۆ")
        .description("رووناهى")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WordOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WordOfDayWidget", provider: RounahiProvider()) { entry in
            RounahiWidgetChrome {
                VStack(spacing: 8) {
                    Text(entry.brand).font(.caption.bold()).foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.36))
                    Text(entry.arabic).foregroundStyle(.white)
                    Text(entry.translation).font(.caption).foregroundStyle(.white.opacity(0.9))
                }
            }
            .widgetURL(URL(string: "rounahi://app/words/\(entry.wordId)"))
        }
        .configurationDisplayName("وشەی ڕۆژ")
        .description("رووناهى")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TopicOfDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TopicOfDayWidget", provider: RounahiProvider()) { entry in
            RounahiWidgetChrome {
                VStack(spacing: 8) {
                    Text(entry.brand).font(.caption.bold()).foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.36))
                    Text(entry.topic).foregroundStyle(.white)
                    Text(entry.translation).font(.caption).foregroundStyle(.white.opacity(0.9))
                }
            }
            .widgetURL(URL(string: "rounahi://app/topics/\(entry.topicId)"))
        }
        .configurationDisplayName("بابەتی ڕۆژ")
        .description("رووناهى")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LatestContentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LatestContentWidget", provider: RounahiProvider()) { entry in
            RounahiWidgetChrome {
                VStack(spacing: 8) {
                    Text(entry.brand).font(.caption.bold()).foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.36))
                    Text(entry.topic).foregroundStyle(.white)
                }
            }
            .widgetURL(URL(string: "rounahi://app/topics/\(entry.topicId)"))
        }
        .configurationDisplayName("نوێترین ناوەڕۆک")
        .description("رووناهى")
        .supportedFamilies([.systemMedium])
    }
}

struct CompactRounahiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CompactRounahiWidget", provider: RounahiProvider()) { entry in
            RounahiWidgetChrome {
                VStack {
                    Text(entry.brand).font(.headline).foregroundStyle(Color(red: 0.79, green: 0.66, blue: 0.36))
                    Text(entry.arabic).font(.caption).foregroundStyle(.white)
                }
            }
            .widgetURL(URL(string: "rounahi://app/home"))
        }
        .configurationDisplayName("رووناهى")
        .description("رووناهى")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct RounahiWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayAyahWidget()
        WordOfDayWidget()
        TopicOfDayWidget()
        LatestContentWidget()
        CompactRounahiWidget()
    }
}
