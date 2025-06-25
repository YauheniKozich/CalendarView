//
//  UIControl+EX.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import UIKit
import Combine

extension UIControl {
    func publisher(for events: UIControl.Event) -> UIControl.Publisher {
        return Publisher(control: self, events: events)
    }

    struct Publisher: Combine.Publisher {
        typealias Output = Void
        typealias Failure = Never

        let control: UIControl
        let events: UIControl.Event

        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = Subscription(subscriber: subscriber, control: control, event: events)
            subscriber.receive(subscription: subscription)
        }

        private final class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Void {
            private var subscriber: S?
            weak private var control: UIControl?
            let event: UIControl.Event

            init(subscriber: S, control: UIControl, event: UIControl.Event) {
                self.subscriber = subscriber
                self.control = control
                self.event = event
                control.addTarget(self, action: #selector(eventHandler), for: event)
            }

            func request(_ demand: Subscribers.Demand) {
                // No-op
            }

            func cancel() {
                subscriber = nil
                control?.removeTarget(self, action: #selector(eventHandler), for: event)
            }

            @objc func eventHandler() {
                _ = subscriber?.receive(())
            }
        }
    }
}
