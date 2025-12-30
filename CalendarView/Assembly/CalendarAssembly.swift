//
//  CalendarAssembly.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import UIKit

// MARK: - Configuration

@MainActor
/// Конфигурация зависимостей календаря
public struct CalendarConfiguration: Sendable {
    public let calendar: CalendarProvider
    public let storage: DateStorage
    public let dateFormatter: DateFormatterProvider

    public static var `default`: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeDefault()
    }

    public static var testing: CalendarConfiguration {
        DependencyFactories.ConfigurationFactory.makeForTesting()
    }
}

public enum CalendarAssembly {
    /// Создание ViewModel с конфигурацией
    @MainActor
    public static func makeCalendarViewModel(configuration: CalendarConfiguration? = nil) -> CalendarViewModel {
        let config = configuration ?? .default
        return CalendarViewModel(
            calendar: config.calendar,
            storage: config.storage,
            dateFormatter: config.dateFormatter
        )
    }

    /// Создание ViewController с конфигурацией
    @MainActor public static func makeCalendarViewController(
        configuration: CalendarConfiguration? = nil,
        explosionAnimator: CalendarExplosionAnimator? = nil
    ) -> CalendarViewController {
        let config = configuration ?? .default
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        let viewModel = makeCalendarViewModel(configuration: config)
        return CalendarViewController(
            viewModel: viewModel,
            explosionAnimator: animator
        )
    }

    /// Создание полного календаря с дефолтной конфигурацией
    @MainActor public static func makeDefaultCalendarViewController(
        explosionAnimator: CalendarExplosionAnimator? = nil
    ) -> CalendarViewController {
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        return makeCalendarViewController(configuration: .default, explosionAnimator: animator)
    }

    // MARK: - Convenience Methods

    /// Создание календаря для тестирования
    @MainActor public static func makeTestingCalendarViewController(
        with initialDates: [Date] = [],
        explosionAnimator: CalendarExplosionAnimator? = nil
    ) -> CalendarViewController {
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeForTesting()
        let configuration = DependencyFactories.ConfigurationFactory.makeForTesting(with: initialDates)
        return makeCalendarViewController(configuration: configuration, explosionAnimator: animator)
    }

    /// Создание календаря для конкретной локали
    @MainActor public static func makeLocalizedCalendarViewController(
        for locale: Locale,
        explosionAnimator: CalendarExplosionAnimator? = nil
    ) -> CalendarViewController {
        let animator = explosionAnimator ?? DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        let configuration = DependencyFactories.ConfigurationFactory.make(for: locale)
        return makeCalendarViewController(configuration: configuration, explosionAnimator: animator)
    }
}
