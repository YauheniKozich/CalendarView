 import UIKit

extension CalendarCell {
    /// Настройка accessibility для ячейки календаря
    /// - Parameters:
    ///   - date: Дата ячейки
    ///   - dateString: Отформатированная строка даты
    ///   - isSelected: Выбрана ли дата
    ///   - isInRange: Находится ли дата в диапазоне
    ///   - isPast: Прошедшая ли дата
    func configureAccessibility(
        date: Date,
        dateString: String,
        isSelected: Bool,
        isInRange: Bool,
        isPast: Bool,
        locale: Locale?
    ) {
        isAccessibilityElement = true

        var accessibilityLabel = dateString
        if isSelected {
            accessibilityLabel += ", \(CalendarStrings.localized(.selected, locale: locale))"
        } else if isInRange {
            accessibilityLabel += ", \(CalendarStrings.localized(.inRange, locale: locale))"
        }

        if isPast {
            accessibilityLabel += ", \(CalendarStrings.localized(.past, locale: locale))"
        }

        self.accessibilityLabel = accessibilityLabel

        if isPast {
            accessibilityHint = CalendarStrings.localized(.pastHint, locale: locale)
        } else if !isSelected {
            accessibilityHint = CalendarStrings.localized(.selectHint, locale: locale)
        } else {
            accessibilityHint = CalendarStrings.localized(.selectedHint, locale: locale)
        }

        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
