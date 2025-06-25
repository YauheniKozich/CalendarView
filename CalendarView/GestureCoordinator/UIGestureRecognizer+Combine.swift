//
//  UIGestureRecognizer+Combine.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import UIKit
import Combine

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
