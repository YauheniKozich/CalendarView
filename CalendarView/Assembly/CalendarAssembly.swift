//
//  CalendarAssembly.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import UIKit

// MARK: - Configuration

/// Конфигурация зависимостей календаря
/// Примечание: Не является Sendable, так как содержит протоколы, которые могут иметь mutable состояние
public struct CalendarConfiguration {
    public let calendar: CalendarProvider
    public let storage: DateStorage
    public let dateFormatter: DateFormatterProvider

    public init(
        calendar: CalendarProvider,
        storage: DateStorage,
        dateFormatter: DateFormatterProvider
    ) {
        self.calendar = calendar
        self.storage = storage
        self.dateFormatter = dateFormatter
    }

    
    public static var `default`: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeDefault()
    }

   
    public static var testing: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeForTesting()
    }
}

public enum CalendarAssembly {
    /// Создание ViewModel с конфигурацией
    
    public static func makeCalendarViewModel(configuration: CalendarConfiguration? = nil) -> CalendarViewModel {
        let config = configuration ?? .default
        return CalendarViewModel(
            calendar: config.calendar,
            storage: config.storage,
            dateFormatter: config.dateFormatter
        )
    }

    /// Создание ViewController с конфигурацией
   public static func makeCalendarViewController(
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
    public static func makeDefaultCalendarViewController(
        explosionAnimator: CalendarExplosionAnimator? = nil,
        hapticFeedbackProvider: HapticFeedbackProvider? = nil
    ) -> CalendarViewController {
        return makeCalendarViewController(
            configuration: .default,
            explosionAnimator: explosionAnimator,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
    }

    // MARK: - Convenience Methods

    /// Создание календаря для тестирования
    public static func makeTestingCalendarViewController(
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
    public static func makeLocalizedCalendarViewController(
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
