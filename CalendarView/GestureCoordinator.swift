import Combine
import UIKit

struct GestureEvent {
    enum Kind {
        case singleTap
        case doubleTap
        case swipeLeft
        case swipeRight
    }
    let kind: Kind
    let location: CGPoint?
}

final class GestureCoordinator: NSObject {
    private weak var view: UIView?
    private weak var gestureView: UIView?
    private let gestureEventSubject = PassthroughSubject<GestureEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> {
        gestureEventSubject.eraseToAnyPublisher()
    }

    init(view: UIView, gestureView: UIView) {
        self.view = view
        self.gestureView = gestureView
        super.init()
        setupGestures()
    }

    func setupGestures() {
        guard let view = view, let gestureView = gestureView else { return }

        let gestures: [(UIGestureRecognizer, UIView, GestureEvent.Kind)] = [
            (UITapGestureRecognizer(), gestureView, .singleTap),
            (UITapGestureRecognizer(), gestureView, .doubleTap),
            (UISwipeGestureRecognizer(), view, .swipeLeft),
            (UISwipeGestureRecognizer(), view, .swipeRight)
        ]

        guard
            let singleTap = gestures[0].0 as? UITapGestureRecognizer,
            let doubleTap = gestures[1].0 as? UITapGestureRecognizer,
            let swipeLeft = gestures[2].0 as? UISwipeGestureRecognizer,
            let swipeRight = gestures[3].0 as? UISwipeGestureRecognizer
        else {
            return
        }

        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false

        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false

        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false

        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false

        singleTap.require(toFail: doubleTap)

        for (gesture, targetView, kind) in gestures {
            targetView.addGestureRecognizer(gesture)
            subscribe(gesture, in: targetView, kind: kind)
        }
    }
    
    private func subscribe<T: UIGestureRecognizer>(
        _ gesture: T,
        in view: UIView,
        kind: GestureEvent.Kind
    ) {
        gesture.publisher()
            .sink { [weak self] gesture in
                let location = (gesture as? UITapGestureRecognizer)?.location(in: view)
                self?.gestureEventSubject.send(GestureEvent(kind: kind, location: location))
            }
            .store(in: &cancellables)
    }

    func removeGestures() {
        view?.gestureRecognizers?.removeAll()
        gestureView?.gestureRecognizers?.removeAll()
        cancellables.removeAll()
    }

    deinit {
        removeGestures()
    }
}

extension UIGestureRecognizer {
    func publisher() -> AnyPublisher<UIGestureRecognizer, Never> {
        GesturePublisher(gestureRecognizer: self).eraseToAnyPublisher()
    }
}

private struct GesturePublisher: Publisher {
    typealias Output = UIGestureRecognizer
    typealias Failure = Never

    let gestureRecognizer: UIGestureRecognizer

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == UIGestureRecognizer, S.Failure == Never {
        let subscription = GestureSubscription(subscriber: subscriber, gestureRecognizer: gestureRecognizer)
        subscriber.receive(subscription: subscription)
    }
}

private final class GestureSubscription<S: Subscriber>: Subscription where S.Input == UIGestureRecognizer {
    private var subscriber: S?
    private weak var gestureRecognizer: UIGestureRecognizer?

    init(subscriber: S, gestureRecognizer: UIGestureRecognizer) {
        self.subscriber = subscriber
        self.gestureRecognizer = gestureRecognizer
        gestureRecognizer.addTarget(self, action: #selector(handleGesture))
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        subscriber = nil
        gestureRecognizer?.removeTarget(self, action: #selector(handleGesture))
    }

    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        if let swipe = gesture as? UISwipeGestureRecognizer {
            guard swipe.direction == .left || swipe.direction == .right else {
                print("Unsupported swipe direction: \(swipe.direction)")
                return
            }
        }
        _ = subscriber?.receive(gesture)
    }
}
