 import Foundation

/// Реализация DateFormatterProvider на основе DateFormatter
/// Thread-safe реализация с использованием NSLock, так как DateFormatter не thread-safe
final class DateFormatterProviderImpl: DateFormatterProvider {
    private let formatter: DateFormatter
    private let lock = NSLock()

    init(locale: Locale = .current, dateFormat: String? = nil) {
        self.formatter = DateFormatter()
        self.formatter.locale = locale
        self.formatter.dateFormat = dateFormat
    }

    func string(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return formatter.string(from: date)
    }

    func string(from date: Date, format: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let originalFormat = formatter.dateFormat
        defer { formatter.dateFormat = originalFormat }

        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    var locale: Locale? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return formatter.locale
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            formatter.locale = newValue
        }
    }

    var dateFormat: String? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return formatter.dateFormat
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            formatter.dateFormat = newValue
        }
    }
}

