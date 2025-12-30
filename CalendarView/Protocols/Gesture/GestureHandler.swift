//
//  GestureHandler.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Foundation
import Combine

/// Протокол для абстракции обработки жестов
/// Позволяет использовать разные реализации обработки жестов
public protocol GestureHandler: AnyObject {
    /// Publisher для событий жестов
    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> { get }

    /// Настройка жестов на view
    func setupGestures(on view: GestureView)

    /// Удаление всех жестов
    func removeGestures()

    /// Проверка, активен ли обработчик
    var isActive: Bool { get }
}
