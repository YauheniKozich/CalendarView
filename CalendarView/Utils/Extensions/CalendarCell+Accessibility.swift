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
        isPast: Bool
    ) {
        isAccessibilityElement = true

        var accessibilityLabel = dateString

        if isSelected {
            accessibilityLabel += ", выбрана"
        } else if isInRange {
            accessibilityLabel += ", в диапазоне"
        }

        if isPast {
            accessibilityLabel += ", прошедшая дата"
        }

        self.accessibilityLabel = accessibilityLabel

        if isPast {
            accessibilityHint = "Эта дата уже прошла и недоступна для выбора"
        } else if !isSelected {
            accessibilityHint = "Двойное нажатие для выбора даты"
        } else {
            accessibilityHint = "Дата уже выбрана"
        }

        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}

