//
//  GestureCoordinator.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 18.06.25.
//

import Combine
import UIKit

enum GestureEvent {
    case doubleTap
    case swipeLeft
    case swipeRight
}

final class GestureCoordinator: NSObject {
    private weak var view: UIView?
    private weak var gestureView: UIView?

    private let gestureEventSubject = PassthroughSubject<GestureEvent, Never>()
    var gestureEventPublisher: AnyPublisher<GestureEvent, Never> {
        gestureEventSubject.eraseToAnyPublisher()
    }

    init(view: UIView, gestureView: UIView) {
        self.view = view
        self.gestureView = gestureView
    }

    func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        gestureView?.addGestureRecognizer(doubleTap)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view?.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view?.addGestureRecognizer(swipeRight)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        gestureEventSubject.send(.doubleTap)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            gestureEventSubject.send(.swipeLeft)
        case .right:
            gestureEventSubject.send(.swipeRight)
        default:
            break
        }
    }
}
