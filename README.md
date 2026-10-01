# CalendarView - UIKit календарь с эффектом взрыва ячеек

Мощный и гибкий компонент календаря для iOS с поддержкой выбора диапазонов дат и анимированным эффектом "взрыва" ячеек.

## Особенности

- **Разделение UI, состояния и хранения** с dependency injection
- **Выбор диапазона дат** с визуальным выделением
- **Анимированный эффект взрыва** ячеек при 5‑кратном тапе
- **Гибкая конфигурация** календаря, хранения и форматирования
- **Поддержка календарей Foundation** с согласованным форматированием дат
- **Тестируемый дизайн** с протоколами и mock зависимостями
- **Структурированное логирование** с категориями
- **UIKit экран календаря** с отдельными провайдерами хранения и дат
- **Кеширование** для оптимизации производительности
- **Async/await для анимации** эффекта взрыва
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

Примеры предназначены для кода внутри приложения. Создание контроллера, ViewModel и аниматора, а также работа с ними выполняются в `MainActor`-контексте.

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
    dateFormatter: DateFormatterProviderImpl(
        locale: Locale(identifier: "ru_RU"),
        dateFormat: "MMMM yyyy"
    )
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
try viewModel.select(Date())
```

### Async-анимация

`explodeAsync` ожидает завершения анимации, включая завершение по таймауту, и возвращает `true`. При отмене, сбросе, недопустимых элементах или невозможности начать новую анимацию возвращается `false`. Завершение не восстанавливает сетку автоматически.

```swift
// Выполняйте вызов из MainActor-контекста.
let animator = CalendarExplosionAnimator()
let completed = await animator.explodeAsync(items: cells, in: view)
Logger.debug("Анимация завершена: \(completed)", category: .animation)
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

- `CalendarProviderImpl(calendar: Calendar(identifier: .buddhist))`
- `UserDefaultsDateStorage(key: "calendar")`
- `InMemoryDateStorage(initialDates: [])`
- `DateFormatterProviderImpl(locale: Locale(identifier: "ru_RU"), dateFormat: "MMMM yyyy")`

## Требования

- iOS 18.4+
- iOS 18.4+ Simulator для тестовых таргетов
- Swift language mode 5 (`SWIFT_VERSION = 5.0`); компилятор из поддерживаемой версии Xcode
- Xcode 26.0+

## Поведение календаря

- Даты раньше сегодняшнего дня нельзя выбрать; `select(_:)` игнорирует их без ошибки.
- Выбираются максимум две даты. При третьем выборе заменяется более ранняя граница, затем даты сортируются.
- «Очистить даты» сбрасывает выбор на сегодняшнюю дату и показывает текущий месяц; выбранная дата сохраняется в хранилище.
- После пяти одиночных тапов запускается взрыв ячеек. Завершение анимации оставляет их в изменённом положении. Кнопка восстановления возвращает сетку; очистка дат и смена месяца также восстанавливают её.

## Запуск тестов

Откройте `CalendarView.xcodeproj`, выберите схему `CalendarView` и iOS Simulator версии 18.4 или новее. Запустите тесты через **Product → Test** (`⌘U`).

Для запуска из терминала сначала найдите доступный симулятор:

```sh
xcodebuild -project CalendarView.xcodeproj -scheme CalendarView -showdestinations
```

Подставьте его идентификатор вместо `SIMULATOR_UDID`:

```sh
# Только unit-тесты
xcodebuild -project CalendarView.xcodeproj -scheme CalendarView \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -only-testing:CalendarViewTests test

# Unit- и UI-тесты
xcodebuild -project CalendarView.xcodeproj -scheme CalendarView \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' test
```

`CalendarViewTests` проверяет выбор и сохранение дат, локализацию и состояние аниматора. `CalendarViewTestsUI` проверяет заголовки дней недели, взрыв после пяти тапов, восстановление сетки и запуск приложения в разных UI-конфигурациях.
