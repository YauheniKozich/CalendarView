 import OSLog

/// Логер приложения на основе OSLog
/// Предоставляет структурированное логирование с категориями и уровнями
enum Logger {
    /// Категории логирования
    enum Category: String, Sendable {
        case calendar = "Calendar"
        case gesture = "Gesture"
        case storage = "Storage"
        case animation = "Animation"
        case general = "General"
    }

    /// Уровни логирования
    enum Level: String, Sendable {
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
    static func log(
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
    static func debug(_ message: String, category: Category = .general) {
        log(message, category: category, level: .debug)
    }

    /// Логирование информационных сообщений
    static func info(_ message: String, category: Category = .general) {
        log(message, category: category, level: .info)
    }

    /// Логирование предупреждений
    static func warning(_ message: String, category: Category = .general) {
        log(message, category: category, level: .warning)
    }

    /// Логирование ошибок
    static func error(_ message: String, category: Category = .general) {
        log(message, category: category, level: .error)
    }
}
