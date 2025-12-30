//
import Foundation

/// Протокол для абстракции хранения дат
/// Позволяет использовать разные хранилища (UserDefaults, Keychain, CoreData, сеть и т.д.)
public protocol DateStorage {
    /// Сохранить массив дат (синхронно)
    func save(_ dates: [Date]) throws

    /// Загрузить массив дат (синхронно)
    func load() throws -> [Date]

    /// Сохранить массив дат (асинхронно)
    func saveAsync(_ dates: [Date]) async throws

    /// Загрузить массив дат (асинхронно)
    func loadAsync() async throws -> [Date]
}

/// Реализация для UserDefaults
internal final class UserDefaultsDateStorage: DateStorage {
    private let key: String
    private let defaults: UserDefaults

    public init(key: String = "selectedDates", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    public func save(_ dates: [Date]) throws {
        guard !dates.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        let data = try JSONEncoder().encode(dates)
        defaults.set(data, forKey: key)
    }

    public func load() throws -> [Date] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }

        return try JSONDecoder().decode([Date].self, from: data)
    }

    public func saveAsync(_ dates: [Date]) async throws {
        try await Task { try save(dates) }.value
    }

    public func loadAsync() async throws -> [Date] {
        try await Task { try load() }.value
    }
}

/// Реализация для памяти (для тестирования)
internal final class InMemoryDateStorage: DateStorage {
    private var storage: [Date] = []

    public init(initialDates: [Date] = []) {
        self.storage = initialDates
    }

    public func save(_ dates: [Date]) throws {
        storage = dates
    }

    public func load() throws -> [Date] {
        return storage
    }

    public func saveAsync(_ dates: [Date]) async throws {
        storage = dates
    }

    public func loadAsync() async throws -> [Date] {
        return storage
    }
}
