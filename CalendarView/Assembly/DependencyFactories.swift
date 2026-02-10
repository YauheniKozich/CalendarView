 import UIKit

/// Фабрики для создания зависимостей
/// Предоставляет централизованный способ создания всех зависимостей приложения
enum DependencyFactories {

    enum CalendarProviderFactory {
        /// Создает стандартный calendar provider
        static func makeDefault() -> CalendarProvider {
            CalendarProviderImpl()
        }

        /// Создает calendar provider для тестирования
        static func makeForTesting() -> CalendarProvider {
            CalendarProviderImpl(calendar: Calendar(identifier: .gregorian))
        }

        /// Создает calendar provider с кастомным календарем
        static func make(with calendar: Calendar) -> CalendarProvider {
            CalendarProviderImpl(calendar: calendar)
        }

        /// Создает calendar provider для конкретной локали
        static func make(for locale: Locale) -> CalendarProvider {
            let calendar = Calendar.current
            return CalendarProviderImpl(calendar: calendar)
        }
    }
    
    enum DateStorageFactory {
        /// Создает стандартное хранилище (UserDefaults)
        
        static func makeDefault() -> DateStorage {
            UserDefaultsDateStorage()
        }

        /// Создает хранилище для тестирования (in-memory)
        static func makeForTesting() -> DateStorage {
            InMemoryDateStorage()
        }

        /// Создает хранилище с кастомным ключом
        static func make(with key: String) -> DateStorage {
            UserDefaultsDateStorage(key: key)
        }

        /// Создает хранилище с начальными данными
        static func makeForTesting(with initialDates: [Date]) -> DateStorage {
            InMemoryDateStorage(initialDates: initialDates)
        }
    }

    enum DateFormatterFactory {
        /// Создает стандартный date formatter
        static func makeDefault() -> DateFormatterProvider {
            DateFormatterProviderImpl(dateFormat: "MMMM yyyy")
        }

        /// Создает date formatter для тестирования
        static func makeForTesting() -> DateFormatterProvider {
            DateFormatterProviderImpl(dateFormat: "yyyy-MM-dd")
        }

        /// Создает date formatter с кастомным форматом
        static func make(with format: String, locale: Locale = .current) -> DateFormatterProvider {
            DateFormatterProviderImpl(locale: locale, dateFormat: format)
        }

        /// Создает date formatter для конкретной локали
        static func make(for locale: Locale) -> DateFormatterProvider {
            DateFormatterProviderImpl(locale: locale, dateFormat: "MMMM yyyy")
        }
    }
    
    enum ExplosionAnimatorFactory {
        /// Создает стандартный animator
         static func makeDefault() -> CalendarExplosionAnimator {
            CalendarExplosionAnimator()
        }

        /// Создает animator с кастомными параметрами
         static func make(minMagnitude: CGFloat = 0.5,
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
        static func makeForTesting() -> CalendarExplosionAnimator {
            make(minMagnitude: 0.1, maxMagnitude: 0.2, elasticity: 0.1, bottomBoundaryOffset: 20.0, animationTimeout: 2.0, tapThreshold: 1)
        }
    }

    enum GestureCoordinatorFactory {
        /// Создает gesture coordinator для view
  
        static func make(for view: UIView, gestureView: UIView) -> GestureCoordinator {
            GestureCoordinator(view: view, gestureView: gestureView)
        }

        /// Создает gesture coordinator для тестирования
        static func makeForTesting(view: UIView? = nil,
                                         gestureView: UIView? = nil) -> GestureCoordinator {
            let testView = view ?? UIView()
            let testGestureView = gestureView ?? UIView()
            return make(for: testView, gestureView: testGestureView)
        }
    }
    
    enum ConfigurationFactory {
        /// Создает стандартную конфигурацию
        static func makeDefault() -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeDefault(),
                storage: DateStorageFactory.makeDefault(),
                dateFormatter: DateFormatterFactory.makeDefault()
            )
        }

        /// Создает конфигурацию для тестирования
        static func makeForTesting() -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeForTesting(),
                storage: DateStorageFactory.makeForTesting(),
                dateFormatter: DateFormatterFactory.makeForTesting()
            )
        }

        /// Создает конфигурацию для тестирования с начальными данными
        static func makeForTesting(with initialDates: [Date]) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.makeForTesting(),
                storage: DateStorageFactory.makeForTesting(with: initialDates),
                dateFormatter: DateFormatterFactory.makeForTesting()
            )
        }

        /// Создает кастомную конфигурацию
        static func make(calendar: CalendarProvider,
                               storage: DateStorage,
                               dateFormatter: DateFormatterProvider) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: calendar,
                storage: storage,
                dateFormatter: dateFormatter
            )
        }

        /// Создает конфигурацию для конкретной локали
        static func make(for locale: Locale) -> CalendarConfiguration {
            CalendarConfiguration(
                calendar: CalendarProviderFactory.make(for: locale),
                storage: DateStorageFactory.makeDefault(),
                dateFormatter: DateFormatterFactory.make(for: locale)
            )
        }
    }
    
    enum HapticFeedbackFactory {
        /// Создает стандартный haptic feedback provider (UIKit)
        static func makeDefault() -> HapticFeedbackProvider {
            UIKitHapticFeedbackProvider()
        }
        
        /// Создает haptic feedback provider для тестирования (no-op)
        static func makeForTesting() -> HapticFeedbackProvider {
            NoOpHapticFeedbackProvider()
        }
    }
}
