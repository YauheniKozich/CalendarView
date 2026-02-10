 import Foundation

/// Перечисление ошибок календаря
enum CalendarError: LocalizedError, Sendable {

    /// Ошибка сохранения данных
    case saveFailed(reason: String)

    /// Ошибка загрузки данных
    case loadFailed(reason: String)

    /// Данные повреждены или имеют неверный формат
    case corruptedData

    /// Анимация уже выполняется
    case animationInProgress

    /// Таймаут анимации
    case animationTimeout

    /// Недопустимые параметры анимации
    case invalidAnimationParameters(reason: String)

    /// Недопустимая дата
    case invalidDate

    /// Дата находится в прошлом
    case dateInPast

    /// Ошибка валидации даты
    case dateValidationFailed(reason: String)

    /// Collection view не найден
    case collectionViewNotFound

    /// Недопустимые bounds для анимации
    case invalidBoundsForAnimation

    var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return "Не удалось сохранить данные: \(reason)"
        case .loadFailed(let reason):
            return "Не удалось загрузить данные: \(reason)"
        case .corruptedData:
            return "Данные повреждены или имеют неверный формат"
        case .animationInProgress:
            return "Анимация уже выполняется"
        case .animationTimeout:
            return "Превышено время ожидания анимации"
        case .invalidAnimationParameters(let reason):
            return "Недопустимые параметры анимации: \(reason)"
        case .invalidDate:
            return "Указана недопустимая дата"
        case .dateInPast:
            return "Нельзя выбрать дату из прошлого"
        case .dateValidationFailed(let reason):
            return "Ошибка валидации даты: \(reason)"
        case .collectionViewNotFound:
            return "Collection view не найден"
        case .invalidBoundsForAnimation:
            return "Недопустимые границы для анимации"
        }
    }

    var failureReason: String? {
        switch self {
        case .saveFailed, .loadFailed, .corruptedData:
            return "Проблема с хранением данных"
        case .animationInProgress, .animationTimeout, .invalidAnimationParameters:
            return "Проблема с анимацией"
        case .invalidDate, .dateInPast, .dateValidationFailed:
            return "Проблема с датой"
        case .collectionViewNotFound, .invalidBoundsForAnimation:
            return "Проблема с пользовательским интерфейсом"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed:
            return "Проверьте доступ к хранилищу и повторите операцию"
        case .corruptedData:
            return "Попробуйте сбросить настройки приложения"
        case .animationInProgress:
            return "Дождитесь завершения текущей анимации"
        case .animationTimeout:
            return "Попробуйте уменьшить количество анимируемых элементов"
        case .invalidAnimationParameters:
            return "Проверьте параметры анимации"
        case .invalidDate, .dateInPast:
            return "Выберите корректную дату в будущем"
        case .dateValidationFailed:
            return "Проверьте формат и диапазон даты"
        case .collectionViewNotFound:
            return "Убедитесь, что view правильно инициализирован"
        case .invalidBoundsForAnimation:
            return "Проверьте размеры и позицию элементов"
        }
    }
}

/// Расширение для работы с Result типами
extension Result where Failure == Error {
    /// Создает Result с CalendarError
    static func calendarError(_ error: CalendarError) -> Result<Success, Error> {
        .failure(error)
    }
}
