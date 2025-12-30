//
import Foundation
import OSLog

/// Логер приложения на основе OSLog
/// Предоставляет структурированное логирование с категориями и уровнями
public enum Logger {
    /// Категории логирования
    public enum Category: String, Sendable {
        case calendar = "Calendar"
        case gesture = "Gesture"
        case storage = "Storage"
        case animation = "Animation"
        case general = "General"
    }

    /// Уровни логирования
    public enum Level: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    /// Логирование с указанной категорией и уровнем
    /// - Parameters:
    ///   - message: Сообщение для логирования
    ///   - category: Категория логирования
    ///   - level: Уровень логирования
    public static func log(
        _ message: String,
        category: Category = .general,
        level: Level = .info
    ) {
        let logger = os.Logger(subsystem: "com.calendarView", category: category.rawValue)

        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }

    /// Логирование отладочной информации
    public static func debug(_ message: String, category: Category = .general) {
        log(message, category: category, level: .debug)
    }

    /// Логирование информационных сообщений
    public static func info(_ message: String, category: Category = .general) {
        log(message, category: category, level: .info)
    }

    /// Логирование предупреждений
    public static func warning(_ message: String, category: Category = .general) {
        log(message, category: category, level: .warning)
    }

    /// Логирование ошибок
    public static func error(_ message: String, category: Category = .general) {
        log(message, category: category, level: .error)
    }
}
