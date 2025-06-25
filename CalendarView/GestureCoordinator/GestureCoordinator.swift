//
//  GestureEvent.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 25.06.25.
//

import Combine
import UIKit

final class GestureCoordinator: NSObject {
    private weak var view: UIView?
    private weak var gestureView: UIView?
    private let gestureEventSubject = PassthroughSubject<GestureEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var addedGestures: [UIGestureRecognizer] = []

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
            addedGestures.append(gesture)
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
                let location = gesture.location(in: view)
                self?.gestureEventSubject.send(GestureEvent(kind: kind, location: location))
            }
            .store(in: &cancellables)
    }

    func removeGestures() {
        for gesture in addedGestures {
            gesture.view?.removeGestureRecognizer(gesture)
        }
        addedGestures.removeAll()
        cancellables.removeAll()
    }

    deinit {
        removeGestures()
    }
}
