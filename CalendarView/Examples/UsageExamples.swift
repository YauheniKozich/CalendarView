 import Foundation

/// Примеры использования переиспользуемой архитектуры календаря
@MainActor
enum CalendarUsageExamples {

    /// Пример использования календаря с дефолтными настройками
    static func createDefaultCalendar() -> CalendarViewController {
        let explosionAnimator = DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        return CalendarAssembly.makeDefaultCalendarViewController(explosionAnimator: explosionAnimator)
    }

    /// Пример использования календаря с русской локалью
    static func createRussianCalendar() -> CalendarViewController {
        CalendarAssembly.makeLocalizedCalendarViewController(for: Locale(identifier: "ru_RU"))
    }

    /// Пример использования календаря с пользовательским хранилищем в памяти
    static func createInMemoryCalendar() -> CalendarViewController {
        let configuration = DependencyFactories.ConfigurationFactory.makeForTesting()
        return CalendarAssembly.makeCalendarViewController(configuration: configuration)
    }

    /// Пример создания ViewModel отдельно для использования в бизнес-логике
    static func createCalendarViewModel() -> CalendarViewModel {
        let configuration = CalendarConfiguration(
            calendar: DependencyFactories.CalendarProviderFactory.makeDefault(),
            storage: DependencyFactories.DateStorageFactory.make(with: "customCalendar"),
            dateFormatter: DependencyFactories.DateFormatterFactory.make(with: "MMM yyyy")
        )

        return CalendarAssembly.makeCalendarViewModel(configuration: configuration)
    }

    /// Пример использования календаря с пользовательским григорианским календарем
    static func createGregorianCalendar() -> CalendarViewController {
        let gregorianCalendar = Calendar(identifier: .gregorian)

        let configuration = DependencyFactories.ConfigurationFactory.make(
            calendar: DependencyFactories.CalendarProviderFactory.make(with: gregorianCalendar),
            storage: DependencyFactories.DateStorageFactory.make(with: "gregorianCalendar"),
            dateFormatter: DependencyFactories.DateFormatterFactory.make(for: Locale(identifier: "en_US"))
        )

        return CalendarAssembly.makeCalendarViewController(configuration: configuration)
    }

    /// Пример тестирования с mock зависимостями
    static func createTestCalendar() -> CalendarViewController {
        let testDates = [
            Date().addingTimeInterval(-86400), // Вчера
            Date(), // Сегодня
            Date().addingTimeInterval(86400)  // Завтра
        ]
        return CalendarAssembly.makeTestingCalendarViewController(with: testDates)
    }
}
