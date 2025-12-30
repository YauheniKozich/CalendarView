//
//  UsageExamples.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Примеры использования переиспользуемой архитектуры календаря
enum CalendarUsageExamples {

    /// Пример использования календаря с дефолтными настройками
    @MainActor
    static func createDefaultCalendar() -> CalendarViewController {
        let explosionAnimator = DependencyFactories.ExplosionAnimatorFactory.makeDefault()
        return CalendarAssembly.makeDefaultCalendarViewController(explosionAnimator: explosionAnimator)
    }

    /// Пример использования календаря с русской локалью
    @MainActor
    static func createRussianCalendar() -> CalendarViewController {
        CalendarAssembly.makeLocalizedCalendarViewController(for: Locale(identifier: "ru_RU"))
    }

    /// Пример использования календаря с пользовательским хранилищем в памяти
    @MainActor
    static func createInMemoryCalendar() -> CalendarViewController {
        let configuration = DependencyFactories.ConfigurationFactory.makeForTesting()
        return CalendarAssembly.makeCalendarViewController(configuration: configuration)
    }

    /// Пример создания ViewModel отдельно для использования в SwiftUI или других фреймворках
    @MainActor
    static func createCalendarViewModel() -> CalendarViewModel {
        let configuration = CalendarConfiguration(
            calendar: DependencyFactories.CalendarProviderFactory.makeDefault(),
            storage: DependencyFactories.DateStorageFactory.make(with: "customCalendar"),
            dateFormatter: DependencyFactories.DateFormatterFactory.make(with: "MMM yyyy")
        )

        return CalendarAssembly.makeCalendarViewModel(configuration: configuration)
    }

    /// Пример использования async/await для загрузки данных
    @MainActor
    static func createCalendarWithAsyncLoading() async throws -> CalendarViewController {
        let configuration = CalendarConfiguration(
            calendar: CalendarProviderImpl(),
            storage: UserDefaultsDateStorage(key: "asyncCalendar"),
            dateFormatter: DateFormatterProviderImpl()
        )

        let viewModel = CalendarAssembly.makeCalendarViewModel(configuration: configuration)

        // Асинхронная загрузка данных
        try await viewModel.loadAsync()

        // CalendarExplosionAnimator должен создаваться на main actor, так как работает с UIKit
        let animator = await MainActor.run { DependencyFactories.ExplosionAnimatorFactory.makeDefault() }
        return CalendarAssembly.makeCalendarViewController(configuration: configuration, explosionAnimator: animator)
    }

    /// Пример использования календаря с пользовательским календарем (например, юлианским)
    @MainActor
    static func createJulianCalendar() -> CalendarViewController {
        let julianCalendar = Calendar(identifier: .gregorian) // Для примера используем григорианский

        let configuration = DependencyFactories.ConfigurationFactory.make(
            calendar: DependencyFactories.CalendarProviderFactory.make(with: julianCalendar),
            storage: DependencyFactories.DateStorageFactory.make(with: "julianCalendar"),
            dateFormatter: DependencyFactories.DateFormatterFactory.make(for: Locale(identifier: "en_US"))
        )

        return CalendarAssembly.makeCalendarViewController(configuration: configuration)
    }

    /// Пример тестирования с mock зависимостями
    @MainActor
    static func createTestCalendar() -> CalendarViewController {
        let testDates = [
            Date().addingTimeInterval(-86400), // Вчера
            Date(), // Сегодня
            Date().addingTimeInterval(86400)  // Завтра
        ]
        return CalendarAssembly.makeTestingCalendarViewController(with: testDates)
    }
}
