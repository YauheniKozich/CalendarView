 import UIKit

/// Координатор жестов для обработки различных типов взаимодействий пользователя
/// Использует традиционные UIKit жесты без Combine
/// Изолирован на MainActor, так как работает с UIKit компонентами
final class GestureCoordinator: NSObject, UIGestureRecognizerDelegate {
    private weak var view: UIView?
    private weak var gestureView: UIView?
    private var addedGestures: [UIGestureRecognizer] = []

    /// Callback для обработки событий жестов
    var onGestureEvent: ((GestureEvent) -> Void)?

    /// Инициализация координатора жестов
    /// - Parameters:
    ///   - view: Основной view для жестов (например, для swipe)
    ///   - gestureView: View для тапов (например, ячейка календаря)
    init(view: UIView, gestureView: UIView) {
        self.view = view
        self.gestureView = gestureView
        super.init()
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
        singleTap.delegate = self

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
        swipeLeft.delegate = self
        
        let swipeRight = UISwipeGestureRecognizer()
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        swipeRight.delegate = self
        
        addGesture(swipeLeft, to: view, kind: .swipeLeft)
        addGesture(swipeRight, to: view, kind: .swipeRight)
    }
    
    /// Добавление жеста с обработчиком событий
    private func addGesture(_ gesture: UIGestureRecognizer, to view: UIView, kind: GestureKind) {
        gesture.addTarget(self, action: #selector(handleGesture(_:)))
        gesture.gestureKind = kind
        view.addGestureRecognizer(gesture)
        addedGestures.append(gesture)
    }

    /// Обработка событий жестов
    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        guard let kind = gesture.gestureKind,
              let view = gesture.view,
              gesture.state == .ended else { return }

        if let swipe = gesture as? UISwipeGestureRecognizer {
            guard swipe.direction == .left || swipe.direction == .right else {
                Logger.warning("Unsupported swipe direction: \(swipe.direction)", category: .gesture)
                return
            }
        }

        let location = gesture.location(in: view)
        let event = GestureEvent(kind: kind, location: location)
        onGestureEvent?(event)
    }

    /// Удаление всех жестов и очистка ресурсов
    func removeGestures() {
        for gesture in addedGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        addedGestures.removeAll()
    }

    /// Проверка, активен ли координатор
    var isActive: Bool {
        return !addedGestures.isEmpty
    }

    deinit {
        // deinit вызывается в не-изолированном контексте
        // Удаление жестов из view требует main actor, но в deinit мы не можем гарантировать это
        // Поэтому просто очищаем массивы - когда view будет освобожден, жесты автоматически удалятся системой
        // Очистка массивов безопасна в любом контексте
        addedGestures.removeAll()
    }
}

private extension UIGestureRecognizer {
    private enum AssociatedKeys {
        static var gestureKind: UInt8 = 0
    }

    var gestureKind: GestureKind? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.gestureKind) as? GestureKind
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.gestureKind, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}
