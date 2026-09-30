import Foundation

enum CalendarStrings {
    enum Key: String {
        case clearDates = "calendar.clear_dates"
        case restore = "calendar.restore"
        case selected = "calendar.accessibility.selected"
        case inRange = "calendar.accessibility.in_range"
        case past = "calendar.accessibility.past"
        case pastHint = "calendar.accessibility.past_hint"
        case selectHint = "calendar.accessibility.select_hint"
        case selectedHint = "calendar.accessibility.selected_hint"
    }

    static func localized(_ key: Key, locale: Locale? = nil) -> String {
        let languageCode = (locale ?? .current).language.languageCode?.identifier ?? "en"
        let bundle: Bundle

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            bundle = localizedBundle
        } else {
            bundle = .main
        }

        return bundle.localizedString(forKey: key.rawValue, value: key.rawValue, table: nil)
    }
}
