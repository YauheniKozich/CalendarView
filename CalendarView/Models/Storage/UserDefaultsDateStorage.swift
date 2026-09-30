 import Foundation

/// Реализация DateStorage для UserDefaults
internal final class UserDefaultsDateStorage: DateStorage {
    private let key: String
    private let defaults: UserDefaults
    
    init(key: String = "selectedDates", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func save(_ dates: [Date]) throws {
        guard !dates.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        let data = try JSONEncoder().encode(dates)
        defaults.set(data, forKey: key)
    }

    func load() throws -> [Date] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        return try JSONDecoder().decode([Date].self, from: data)
    }

}
