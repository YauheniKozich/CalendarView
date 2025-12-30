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
