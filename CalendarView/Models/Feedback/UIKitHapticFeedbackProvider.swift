//
//  UIKitHapticFeedbackProvider.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import UIKit

/// Реализация HapticFeedbackProvider на основе UIKit
final class UIKitHapticFeedbackProvider: HapticFeedbackProvider {
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator
    
    public init() {
        self.selectionGenerator = UISelectionFeedbackGenerator()
        self.notificationGenerator = UINotificationFeedbackGenerator()
        // Подготавливаем генераторы для лучшей производительности
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    public func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Подготавливаем для следующего использования
    }
    
    public func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    public func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    public func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
}

