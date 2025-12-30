//
//  AnimationContainer.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation
import UIKit

/// Контейнер для анимации
public protocol AnimationContainer: AnyObject {
    /// Обновление layout
    func setNeedsLayout()

    /// Принудительное обновление layout
    func layoutIfNeeded()

    /// Видимые элементы
    var visibleItems: [AnimatableItem] { get }
}

// MARK: - Default Implementation for UIView
extension AnimationContainer where Self: UIView {
    public func setNeedsLayout() {
        self.setNeedsLayout()
    }

    public func layoutIfNeeded() {
        self.layoutIfNeeded()
    }
}

