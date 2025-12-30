//
//  GestureEvent.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Combine
import UIKit

// MARK: - Logger

/// Координатор жестов для обработки различных типов взаимодействий пользователя
/// Интегрирует UIKit жесты с Combine для реактивного программирования
/// Изолирован на MainActor, так как работает с UIKit компонентами
@MainActor
public final class GestureCoordinator: NSObject {
    private weak var view: UIView?
    private weak var gestureView: UIView?
    private let gestureEventSubject = PassthroughSubject<GestureEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var addedGestures: [UIGestureRecognizer] = []

    /// Publisher для событий жестов
    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> {
        gestureEventSubject.eraseToAnyPublisher()
    }

    /// Инициализация координатора жестов
    /// - Parameters:
    ///   - view: Основной view для жестов (например, для swipe)
    ///   - gestureView: View для тапов (например, ячейка календаря)
    init(view: UIView, gestureView: UIView) {
        self.view = view
        self.gestureView = gestureView
        super.init()
        setupGestures()
    }

    /// Настройка всех жестов
    func setupGestures() {
        guard let view = view, let gestureView = gestureView else {
            Logger.warning("view или gestureView не установлены", category: .gesture)
            return
        }

        setupTapGestures(on: gestureView)
        setupSwipeGestures(on: view)
    }
    
    /// Настройка тап-жестов
    private func setupTapGestures(on view: UIView) {
        let singleTap = UITapGestureRecognizer()
        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false

        // Для тестирования убираем doubleTap, чтобы singleTap работал правильно
        // let doubleTap = UITapGestureRecognizer()
        // doubleTap.numberOfTapsRequired = 2
        // doubleTap.cancelsTouchesInView = false

        // singleTap.require(toFail: doubleTap)

        addGesture(singleTap, to: view, kind: .singleTap)
        // addGesture(doubleTap, to: view, kind: .doubleTap)
    }
    
    /// Настройка swipe-жестов
    private func setupSwipeGestures(on view: UIView) {
        let swipeLeft = UISwipeGestureRecognizer()
        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false
        
        let swipeRight = UISwipeGestureRecognizer()
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        
        addGesture(swipeLeft, to: view, kind: .swipeLeft)
        addGesture(swipeRight, to: view, kind: .swipeRight)
    }
    
    /// Добавление жеста с подпиской на события
    private func addGesture(_ gesture: UIGestureRecognizer, to view: UIView, kind: GestureKind) {
        view.addGestureRecognizer(gesture)
        addedGestures.append(gesture)
        subscribe(gesture, in: view, kind: kind)
    }
    
    /// Подписка на события жеста
    /// - Parameters:
    ///   - gesture: Жест для подписки
    ///   - view: View, в котором происходит жест
    ///   - kind: Тип события жеста
    private func subscribe<T: UIGestureRecognizer>(
        _ gesture: T,
        in view: UIView,
        kind: GestureKind
    ) {
        gesture.publisher()
            .sink { [weak self] gesture in
                let location = gesture.location(in: view)
                let event = GestureEvent(kind: kind, location: location)
                self?.gestureEventSubject.send(event)
            }
            .store(in: &cancellables)
    }

    /// Удаление всех жестов и очистка ресурсов
    func removeGestures() {
        for gesture in addedGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        addedGestures.removeAll()
        cancellables.removeAll()
    }
    
    /// Проверка, активен ли координатор
    var isActive: Bool {
        return !addedGestures.isEmpty && !cancellables.isEmpty
    }

    deinit {
        // deinit вызывается в не-изолированном контексте
        // Удаление жестов из view требует main actor, но в deinit мы не можем гарантировать это
        // Поэтому просто очищаем массивы - когда view будет освобожден, жесты автоматически удалятся системой
        // Очистка массивов безопасна в любом контексте
        addedGestures.removeAll()
        cancellables.removeAll()
    }
}
