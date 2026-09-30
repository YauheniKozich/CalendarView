 import Foundation

/// Реализация DateStorage для памяти (для тестирования)
/// Thread-safe реализация с использованием NSLock для синхронизации
final class InMemoryDateStorage: DateStorage {
    private var storage: [Date] = []
    private let lock = NSLock()

    init(initialDates: [Date] = []) {
        self.storage = initialDates
    }

    func save(_ dates: [Date]) throws {
        lock.lock()
        defer { lock.unlock() }
        storage = dates
    }

    func load() throws -> [Date] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

}
