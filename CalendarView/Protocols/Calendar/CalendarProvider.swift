//
import Foundation

/// Протокол для абстракции календаря
/// Позволяет использовать разные календари (григорианский, юлианский и т.д.)
public protocol CalendarProvider {
    /// Текущая дата
    var today: Date { get }

    /// Компоненты даты
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents

    /// Создание даты из компонентов
    func date(from components: DateComponents) -> Date?

    /// Проверка, является ли дата в тот же день
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool

    /// Диапазон дней в месяце
    func range(of component: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>?

    /// Добавление компонентов к дате
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date?

    /// Компонент weekday от даты
    func component(_ component: Calendar.Component, from date: Date) -> Int

    /// Первый день недели
    var firstWeekday: Int { get }

    /// Сравнение дат по гранулярности
    func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult

    /// Начало дня для указанной даты
    func startOfDay(for date: Date) -> Date
}

// Удалено расширение Calendar.Component для избежания конфликтов имен
// Используйте Calendar.Component.day, Calendar.Component.month и т.д. напрямую
