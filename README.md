# CalendarView - Переиспользуемый календарь с эффектом взрыва ячеек

Мощный и гибкий компонент календаря для iOS с поддержкой выбора диапазонов дат и анимированным эффектом "взрыва" ячеек.

## ✨ Особенности

- **Полностью переиспользуемая архитектура** с dependency injection
- **Выбор диапазона дат** с визуальным выделением
- **Анимированный эффект взрыва** ячеек при двойном тапе
- **Гибкая конфигурация** календаря, хранения и форматирования
- **Поддержка разных календарей** (григорианский, юлианский и др.)
- **Тестируемый дизайн** с протоколами и mock зависимостями
- **Структурированное логирование** с категориями
- **UIKit компонент** для интеграции в приложения
- **Кеширование** для оптимизации производительности
- **Async/await поддержка** для асинхронных операций
- **Валидация данных** и bounds checking
- **Haptic feedback** для лучшего UX
- **Современные Swift возможности** (structured concurrency)

## 🏗️ Архитектура

Проект построен на принципах **чистой архитектуры** с разделением ответственности:

### Протоколы (Protocols/)
- `CalendarProvider` - абстракция календаря
- `DateStorage` - абстракция хранения данных
- `DateFormatterProvider` - абстракция форматирования дат
- `GestureHandler` - абстракция обработки жестов
- `ExplosionAnimator` - абстракция анимации

### Реализации
- `CalendarProviderImpl` - реализация на основе Calendar
- `UserDefaultsDateStorage` - хранение в UserDefaults
- `InMemoryDateStorage` - хранение в памяти (для тестов)
- `DateFormatterProviderImpl` - реализация на основе DateFormatter

## 🆕 Новые возможности (v2.0)

- **Property Wrappers**: `@Cached`, `@Clamped`, `@Validated`, `@Logged` для лучшей организации кода
- **Улучшенная Accessibility**: Полная поддержка VoiceOver с детальными описаниями
- **Timeout для анимаций**: Предотвращение бесконечных анимаций
- **Кеширование**: Оптимизированное кеширование вычисляемых значений
- **Структурированные ошибки**: `CalendarError` enum с локализацией
- **Swift Concurrency**: Async/await поддержка для всех операций

## 📖 Использование

### Базовое использование

```swift
// Создание календаря с настройками по умолчанию
let explosionAnimator = CalendarExplosionAnimator()
let calendarVC = CalendarAssembly.makeDefaultCalendarViewController(explosionAnimator: explosionAnimator)
```

### Кастомная конфигурация

```swift
let configuration = CalendarConfiguration(
    calendar: CalendarProviderImpl(calendar: Calendar(identifier: .gregorian)),
    storage: UserDefaultsDateStorage(key: "myCalendar"),
    dateFormatter: DateFormatterProviderImpl(locale: Locale(identifier: "ru_RU"))
)

let calendarVC = CalendarAssembly.makeCalendarViewController(
    configuration: configuration,
    explosionAnimator: explosionAnimator
)
```

### Использование ViewModel отдельно

```swift
let viewModel = CalendarAssembly.makeCalendarViewModel(configuration: configuration)
// ViewModel можно использовать для бизнес-логики без UI
viewModel.load()
viewModel.select(Date())
```

## 🏭 Фабрики зависимостей

Проект использует фабричный паттерн для централизованного создания всех зависимостей:

```swift
// Создание зависимостей через фабрики
let calendar = DependencyFactories.CalendarProviderFactory.makeDefault()
let storage = DependencyFactories.DateStorageFactory.makeForTesting()
let formatter = DependencyFactories.DateFormatterFactory.makeDefault()

// Или через конфигурацию
let config = DependencyFactories.ConfigurationFactory.makeForTesting()

// Создание календаря через Assembly
let calendarVC = CalendarAssembly.makeTestingCalendarViewController()
```

### Async/Await поддержка

```swift
// Асинхронная загрузка данных
let viewModel = CalendarAssembly.makeCalendarViewModel(configuration: config)
try await viewModel.loadAsync()

// Асинхронное сохранение
try await viewModel.saveAsync()

// Асинхронная анимация
let animator = CalendarExplosionAnimator()
let success = await animator.explodeAsync(items: cells, in: view)
if success {
    print("Анимация запущена успешно")
}
```

### Обработка ошибок

```swift
do {
    try animator.explode(items: cells, in: view)
} catch CalendarError.animationInProgress {
    print("Анимация уже выполняется")
} catch CalendarError.invalidAnimationParameters(let reason) {
    print("Ошибка параметров: \(reason)")
} catch {
    print("Неизвестная ошибка: \(error)")
}

// Или использовать безопасную версию без обработки ошибок
animator.explodeSafely(items: cells, in: view)
```

### Оптимизации производительности

- **Кеширование** часто вычисляемых значений (`currentMonth`, `selectedRange`)
- **Инвалидация кеша** при изменении состояния
- **Bounds checking** для анимаций
- **Валидация входных данных** с логированием
- **Haptic feedback** для лучшего пользовательского опыта

### Property Wrappers

```swift
// Автоматическое кеширование
@Cached var currentMonth: String { computeMonth() }

// Ограничение диапазона значений (применяется в init)
@Clamped(wrappedValue: 0.6, range: 0.0...1.0) var elasticity: CGFloat

// Валидация значений
@Validated(wrappedValue: 10.0, validator: { $0 > 0 }, errorMessage: "Must be positive")
var timeout: TimeInterval

// Логирование изменений
@Logged(wrappedValue: false, label: "animation state") var isAnimating: Bool
```

### Конфигурация анимации

```swift
// Параметры автоматически валидируются диапазонами
let animator = CalendarExplosionAnimator(
    minPushMagnitude: 0.5,     // 0.0...2.0
    maxPushMagnitude: 1.5,     // 0.0...5.0
    elasticity: 0.6,           // 0.0...1.0
    bottomBoundaryOffset: 80.0, // 0.0...200.0
    animationTimeout: 10.0     // 1.0...60.0
)
```

### Тестирование

```swift
let testConfig = CalendarConfiguration(
    calendar: CalendarProviderImpl(),
    storage: InMemoryDateStorage(),
    dateFormatter: DateFormatterProviderImpl()
)

let testCalendar = CalendarAssembly.makeCalendarViewController(
    configuration: testConfig,
    explosionAnimator: explosionAnimator
)
```

## 🔧 Конфигурация

### CalendarConfiguration
```swift
struct CalendarConfiguration {
    let calendar: CalendarProvider      // Тип календаря
    let storage: DateStorage           // Хранилище данных
    let dateFormatter: DateFormatterProvider // Форматирование дат
}
```

### Доступные реализации

#### Календари
- `CalendarProviderImpl(calendar: Calendar(identifier: .gregorian))` - Григорианский
- `CalendarProviderImpl(calendar: Calendar(identifier: .hebrew))` - Иврит
- `CalendarProviderImpl(calendar: Calendar(identifier: .islamic))` - Исламский

#### Хранилища
- `UserDefaultsDateStorage(key: "calendar")` - UserDefaults
- `InMemoryDateStorage(initialDates: [])` - Память (для тестов)

#### Форматтеры
- `DateFormatterProviderImpl(locale: Locale(identifier: "ru_RU"), dateFormat: "MMMM yyyy")`

## 🎯 Переиспользование

Компоненты спроектированы для максимальной переиспользуемости:

- **CalendarProvider** позволяет использовать разные календари
- **DateStorage** абстрагирует хранение данных
- **GestureHandler** позволяет заменить обработку жестов
- **ExplosionAnimator** можно заменить на другие анимации

## 📝 Логирование

Используется структурированное логирование с категориями:

```swift
Logger.info("Календарь загружен", category: .calendar)
Logger.error("Ошибка сохранения", category: .storage)
Logger.warning("Неизвестный жест", category: .gesture)
```

## 🧪 Тестирование

Архитектура поддерживает тестирование с mock зависимостями:

```swift
// Используйте InMemoryDateStorage для тестов
// Передавайте тестовые реализации протоколов
// Все компоненты разделены и тестируемы независимо
```

## 📋 Требования

- iOS 13.0+
- Swift 5.0+
- Xcode 11.0+
