 import UIKit

/// Конфигурация зависимостей календаря
/// Примечание: Не является Sendable, так как содержит протоколы, которые могут иметь mutable состояние
struct CalendarConfiguration {
    let calendar: CalendarProvider
    let storage: DateStorage
    let dateFormatter: DateFormatterProvider

    init(
        calendar: CalendarProvider,
        storage: DateStorage,
        dateFormatter: DateFormatterProvider
    ) {
        self.calendar = calendar
        self.storage = storage
        self.dateFormatter = dateFormatter
    }

    
    static var `default`: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeDefault()
    }

   
    static var testing: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeForTesting()
    }
}

enum CalendarAssembly {
    /// Создание ViewModel с конфигурацией
    
    static func makeCalendarViewModel(configuration: CalendarConfiguration? = nil) -> CalendarViewModel {
        let config = configuration ?? .default
        return CalendarViewModel(
            calendar: config.calendar,
            storage: config.storage,
            dateFormatter: config.dateFormatter
        )
    }

    /// Создание ViewController с конфигурацией
   static func makeCalendarViewController(
        configuration: CalendarConfiguration? = nil,
        explosionAnimator: CalendarExplosionAnimator? = nil,
        hapticFeedbackProvider: HapticFeedbackProvider? = nil
    ) -> CalendarViewController {
        let config = configuration ?? .default
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        let hapticProvider = hapticFeedbackProvider ?? DependencyFactories.HapticFeedbackFactory.makeDefault()
        let viewModel = makeCalendarViewModel(configuration: config)
        return CalendarViewController(
            viewModel: viewModel,
            explosionAnimator: animator,
            hapticFeedbackProvider: hapticProvider
        )
    }

    /// Создание полного календаря с дефолтной конфигурацией
    static func makeDefaultCalendarViewController(
        explosionAnimator: CalendarExplosionAnimator? = nil,
        hapticFeedbackProvider: HapticFeedbackProvider? = nil
    ) -> CalendarViewController {
        return makeCalendarViewController(
            configuration: .default,
            explosionAnimator: explosionAnimator,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
    }

    /// Создание календаря для тестирования
    static func makeTestingCalendarViewController(
        with initialDates: [Date] = [],
        explosionAnimator: CalendarExplosionAnimator? = nil,
        hapticFeedbackProvider: HapticFeedbackProvider? = nil
    ) -> CalendarViewController {
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeForTesting()
        let hapticProvider = hapticFeedbackProvider ?? DependencyFactories.HapticFeedbackFactory.makeForTesting()
        let configuration = DependencyFactories.ConfigurationFactory.makeForTesting(with: initialDates)
        return makeCalendarViewController(
            configuration: configuration,
            explosionAnimator: animator,
            hapticFeedbackProvider: hapticProvider
        )
    }

    /// Создание календаря для конкретной локали
    static func makeLocalizedCalendarViewController(
        for locale: Locale,
        explosionAnimator: CalendarExplosionAnimator? = nil,
        hapticFeedbackProvider: HapticFeedbackProvider? = nil
    ) -> CalendarViewController {
        let configuration = DependencyFactories.ConfigurationFactory.make(for: locale)
        return makeCalendarViewController(
            configuration: configuration,
            explosionAnimator: explosionAnimator,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
    }
}
