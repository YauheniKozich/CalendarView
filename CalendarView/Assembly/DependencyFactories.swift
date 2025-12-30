//
//  DependencyFactories.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation
import UIKit

/// Фабрики для создания зависимостей
/// Предоставляет централизованный способ создания всех зависимостей приложения
public enum DependencyFactories {

    // MARK: - Calendar Provider Factory

    public enum CalendarProviderFactory {
        /// Создает стандартный calendar provider
        @MainActor
        public static func makeDefault() -> CalendarProvider {
            CalendarProviderImpl()
        }

        /// Создает calendar provider для тестирования
        @MainActor
        public static func makeForTesting() -> CalendarProvider {
            CalendarProviderImpl(calendar: Calendar(identifier: .gregorian))
        }

        /// Создает calendar provider с кастомным календарем
        @MainActor
        public static func make(with calendar: Calendar) -> CalendarProvider {
            CalendarProviderImpl(calendar: calendar)
        }

        /// Создает calendar provider для конкретной локали
        @MainActor
        public static func make(for locale: Locale) -> CalendarProvider {
            let calendar = Calendar.current
            return CalendarProviderImpl(calendar: calendar)
        }
    }

    // MARK: - Date Storage Factory

    public enum DateStorageFactory {
        /// Создает стандартное хранилище (UserDefaults)
        @MainActor
        public static func makeDefault() -> DateStorage {
            UserDefaultsDateStorage()
        }

        /// Создает хранилище для тестирования (in-memory)
        @MainActor
        public static func makeForTesting() -> DateStorage {
            InMemoryDateStorage()
        }

        /// Создает хранилище с кастомным ключом
        @MainActor
        public static func make(with key: String) -> DateStorage {
            UserDefaultsDateStorage(key: key)
        }

        /// Создает хранилище с начальными данными
        @MainActor
        public static func makeForTesting(with initialDates: [Date]) -> DateStorage {
            InMemoryDateStorage(initialDates: initialDates)
        }
    }

    // MARK: - Date Formatter Factory

    public enum DateFormatterFactory {
        /// Создает стандартный date formatter
        @MainActor
        public static func makeDefault() -> DateFormatterProvider {
            DateFormatterProviderImpl(dateFormat: "MMMM yyyy")
        }

        /// Создает date formatter для тестирования
        @MainActor
        public static func makeForTesting() -> DateFormatterProvider {
            DateFormatterProviderImpl(dateFormat: "yyyy-MM-dd")
        }

        /// Создает date formatter с кастомным форматом
        @MainActor
        public static func make(with format: String, locale: Locale = .current) -> DateFormatterProvider {
            DateFormatterProviderImpl(locale: locale, dateFormat: format)
        }

        /// Создает date formatter для конкретной локали
        @MainActor
        public static func make(for locale: Locale) -> DateFormatterProvider {
            DateFormatterProviderImpl(locale: locale, dateFormat: "MMMM yyyy")
        }
    }

    // MARK: - Explosion Animator Factory

    public enum ExplosionAnimatorFactory {
        /// Создает стандартный animator
        @MainActor public static func makeDefault() -> CalendarExplosionAnimator {
            CalendarExplosionAnimator()
        }

        /// Создает animator с кастомными параметрами
        @MainActor public static func make(minMagnitude: CGFloat = 0.5,
                               maxMagnitude: CGFloat = 1.5,
                               elasticity: CGFloat = 0.6,
                               bottomBoundaryOffset: CGFloat = 80.0,
                               animationTimeout: TimeInterval = 10.0,
                               tapThreshold: Int = 5) -> CalendarExplosionAnimator {
            return CalendarExplosionAnimator(
                minPushMagnitude: minMagnitude,
                maxPushMagnitude: maxMagnitude,
                elasticity: elasticity,
                bottomBoundaryOffset: bottomBoundaryOffset,
                animationTimeout: animationTimeout,
                tapThreshold: tapThreshold
            )
        }

        /// Создает animator для тестирования
        @MainActor
        public static func makeForTesting() -> CalendarExplosionAnimator {
            make(minMagnitude: 0.1, maxMagnitude: 0.2, elasticity: 0.1, bottomBoundaryOffset: 20.0, animationTimeout: 2.0, tapThreshold: 1)
        }
    }

    // MARK: - Gesture Coordinator Factory

    public enum GestureCoordinatorFactory {
        /// Создает gesture coordinator для view
        @MainActor
        public static func make(for view: UIView, gestureView: UIView) -> GestureCoordinator {
            GestureCoordinator(view: view, gestureView: gestureView)
        }

        /// Создает gesture coordinator для тестирования
        @MainActor
        public static func makeForTesting(view: UIView? = nil,
                                         gestureView: UIView? = nil) -> GestureCoordinator {
            let testView = view ?? UIView()
            let testGestureView = gestureView ?? UIView()
            return make(for: testView, gestureView: testGestureView)
        }
    }

    // MARK: - Configuration Factory

    public enum ConfigurationFactory {
        /// Создает стандартную конфигурацию
        @MainActor
        public static func makeDefault() -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeDefault(),
                storage: DateStorageFactory.makeDefault(),
                dateFormatter: DateFormatterFactory.makeDefault()
            )
        }

        /// Создает конфигурацию для тестирования
        @MainActor
        public static func makeForTesting() -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeForTesting(),
                storage: DateStorageFactory.makeForTesting(),
                dateFormatter: DateFormatterFactory.makeForTesting()
            )
        }

        /// Создает конфигурацию для тестирования с начальными данными
        @MainActor
        public static func makeForTesting(with initialDates: [Date]) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeForTesting(),
                storage: DateStorageFactory.makeForTesting(with: initialDates),
                dateFormatter: DateFormatterFactory.makeForTesting()
            )
        }

        /// Создает кастомную конфигурацию
        @MainActor
        public static func make(calendar: CalendarProvider,
                               storage: DateStorage,
                               dateFormatter: DateFormatterProvider) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: calendar,
                storage: storage,
                dateFormatter: dateFormatter
            )
        }

        /// Создает конфигурацию для конкретной локали
        @MainActor
        public static func make(for locale: Locale) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.make(for: locale),
                storage: DateStorageFactory.makeDefault(),
                dateFormatter: DateFormatterFactory.make(for: locale)
            )
        }
    }
    
    // MARK: - Haptic Feedback Factory
    
    public enum HapticFeedbackFactory {
        /// Создает стандартный haptic feedback provider (UIKit)
        @MainActor
        public static func makeDefault() -> HapticFeedbackProvider {
            UIKitHapticFeedbackProvider()
        }
        
        /// Создает haptic feedback provider для тестирования (no-op)
        @MainActor
        public static func makeForTesting() -> HapticFeedbackProvider {
            NoOpHapticFeedbackProvider()
        }
    }
}
