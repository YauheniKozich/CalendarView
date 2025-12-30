//
import Foundation

/// Протокол для форматирования дат
/// Позволяет использовать разные форматы и локали
public protocol DateFormatterProvider {
    /// Форматирование даты в строку
    func string(from date: Date) -> String

    /// Форматирование даты с указанным форматом
    func string(from date: Date, format: String) -> String

    /// Локаль форматирования
    var locale: Locale? { get set }

    /// Формат даты
    var dateFormat: String? { get set }
}

/// Реализация на основе DateFormatter
public final class DateFormatterProviderImpl: DateFormatterProvider {
    private let formatter: DateFormatter

    public init(locale: Locale = .current, dateFormat: String? = nil) {
        self.formatter = DateFormatter()
        self.formatter.locale = locale
        self.formatter.dateFormat = dateFormat
    }

    public func string(from date: Date) -> String {
        return formatter.string(from: date)
    }

    public func string(from date: Date, format: String) -> String {
        let originalFormat = formatter.dateFormat
        defer { formatter.dateFormat = originalFormat }

        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    public var locale: Locale? {
        get { formatter.locale }
        set { formatter.locale = newValue }
    }

    public var dateFormat: String? {
        get { formatter.dateFormat }
        set { formatter.dateFormat = newValue }
    }
}
