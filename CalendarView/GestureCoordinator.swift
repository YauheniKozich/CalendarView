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
        guard let view = view, let gestureView = gestureView else {
            print("View or gestureView is nil, cannot setup gestures")
            return
        }

        let singleTap = UITapGestureRecognizer()
        singleTap.numberOfTapsRequired = 1
        singleTap.cancelsTouchesInView = false
        gestureView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer()
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        gestureView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)

        let swipeLeft = UISwipeGestureRecognizer()
        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer()
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeRight)

        subscribe(singleTap, in: gestureView, kind: .singleTap)
        subscribe(doubleTap, in: gestureView, kind: .doubleTap)
        subscribe(swipeLeft, in: view, kind: .swipeLeft)
        subscribe(swipeRight, in: view, kind: .swipeRight)
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
