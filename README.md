# CalendarView - Переиспользуемый календарь с эффектом взрыва ячеек

Мощный и гибкий компонент календаря для iOS с поддержкой выбора диапазонов дат и анимированным эффектом "взрыва" ячеек.

## Особенности

- **Полностью переиспользуемая архитектура** с dependency injection
- **Выбор диапазона дат** с визуальным выделением
- **Анимированный эффект взрыва** ячеек при 5‑кратном тапе
- **Гибкая конфигурация** календаря, хранения и форматирования
- **Поддержка разных календарей** (григорианский, юлианский и др.)
- **Тестируемый дизайн** с протоколами и mock зависимостями
- **Структурированное логирование** с категориями
- **UIKit компонент** для интеграции в приложения
- **Кеширование** для оптимизации производительности
- **Async/await поддержка** для асинхронных операций
- **Восстановление выбранного диапазона** после перезапуска
- **Валидация данных** и bounds checking
- **Haptic feedback** для лучшего UX
- **Современные Swift возможности** (structured concurrency)

## Архитектура

Проект разделён по слоям и файлам, чтобы логика, хранение и UI не смешивались:

### Слои
- **Assembly/Factories**: сборка зависимостей и конфигураций (`CalendarAssembly`, `DependencyFactories`)
- **ViewModel**: бизнес‑логика выбора дат и диапазона (`CalendarViewModel`)
- **UI**: контроллер, layout и ячейки (`CalendarViewController`, `CalendarFlowLayout`, `CalendarCell`)
- **Services**: провайдеры календаря/форматтера/хранилища
- **Animations & Gestures**: взрыв, жесты, отслеживание тапов
- **Utils**: логгер, ошибки, утилиты

### Основные протоколы
- `CalendarProvider` — абстракция календаря
- `DateStorage` — хранение выбранных дат
- `DateFormatterProvider` — форматирование дат
- `ExplosionAnimator` — анимация взрыва

## Использование

### Базовое использование

```swift
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

### ViewModel без UI

```swift
let viewModel = CalendarAssembly.makeCalendarViewModel(configuration: configuration)
viewModel.load()
viewModel.select(Date())
```

### Async/Await поддержка

```swift
// Асинхронная загрузка
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

### Конфигурация анимации

```swift
// Параметры автоматически валидируются диапазонами
let animator = CalendarExplosionAnimator(
    minPushMagnitude: 0.5,     // 0.0...2.0
    maxPushMagnitude: 1.5,     // 0.0...5.0
    elasticity: 0.6,           // 0.0...1.0
    bottomBoundaryOffset: 80.0, // 0.0...200.0
    animationTimeout: 10.0,     // 1.0...60.0
    tapThreshold: 5            // количество тапов для взрыва
)
```

## Конфигурация

### CalendarConfiguration
```swift
struct CalendarConfiguration {
    let calendar: CalendarProvider      // Тип календаря
    let storage: DateStorage           // Хранилище данных
    let dateFormatter: DateFormatterProvider // Форматирование дат
}
```

### Примеры реализаций

- `CalendarProviderImpl(calendar: Calendar(identifier: .gregorian))`
- `UserDefaultsDateStorage(key: "calendar")`
- `InMemoryDateStorage(initialDates: [])`
- `DateFormatterProviderImpl(locale: Locale(identifier: "ru_RU"), dateFormat: "MMMM yyyy")`

## Требования

- iOS 13.0+
- Swift 5.0+
- Xcode 11.0+
