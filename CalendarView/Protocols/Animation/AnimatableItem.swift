//
//  AnimatableItem.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import Foundation

/// Абстрактный элемент для анимации
public protocol AnimatableItem: AnyObject {
    /// Проверка возможности взаимодействия
    var isUserInteractionEnabled: Bool { get set }
}

