//
//  CalendarExplosionAnimator.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import UIKit

final class CalendarExplosionAnimator {
    private var minPushMagnitude: CGFloat
    private var maxPushMagnitude: CGFloat
    private var elasticity: CGFloat

    private var animator: UIDynamicAnimator?
    private var gravity: UIGravityBehavior?
    private var collision: UICollisionBehavior?
    private var itemBehavior: UIDynamicItemBehavior?
    private var isExploding = false

    private var tapCount = 0
    var tapThreshold: Int = 5

    init(minPushMagnitude: CGFloat = 0.5, maxPushMagnitude: CGFloat = 1.5, elasticity: CGFloat = 0.6) {
        self.minPushMagnitude = minPushMagnitude
        self.maxPushMagnitude = maxPushMagnitude
        self.elasticity = elasticity
    }

    func explode(cells: [UICollectionViewCell], in view: UIView) {
        DispatchQueue.main.async {
            guard !cells.isEmpty else { return }
            guard !self.isExploding else {
                self.reset()
                // Начинаем заново
                self.explode(cells: cells, in: view)
                return
            }
            self.reset()
            self.isExploding = true

            self.animator = UIDynamicAnimator(referenceView: view)

            self.gravity = UIGravityBehavior(items: cells)
            self.collision = UICollisionBehavior(items: cells)
            self.collision?.translatesReferenceBoundsIntoBoundary = true

            self.itemBehavior = UIDynamicItemBehavior(items: cells)
            self.itemBehavior?.elasticity = self.elasticity
            self.itemBehavior?.allowsRotation = true

            cells.forEach { cell in
                let delay = TimeInterval.random(in: 0 ... 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    let push = UIPushBehavior(items: [cell], mode: .instantaneous)
                    push.angle = CGFloat.random(in: 0 ... .pi * 2)
                    push.magnitude = CGFloat.random(in: self.minPushMagnitude ... self.maxPushMagnitude)
                    self.animator?.addBehavior(push)
                }
            }

            [self.gravity, self.collision, self.itemBehavior].forEach {
                if let behavior = $0 {
                    self.animator?.addBehavior(behavior)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isExploding = false
            }
        }
    }

    func reset() {
        animator?.removeAllBehaviors()
        animator = nil
        gravity = nil
        collision = nil
        itemBehavior = nil
        isExploding = false
    }

    func registerTap(on collectionView: UICollectionView, in view: UIView) {
        tapCount += 1
        if tapCount >= tapThreshold {
            explode(cells: collectionView.visibleCells, in: view)
            collectionView.isUserInteractionEnabled = false
            tapCount = 0
        }
    }

    func restore(collectionView: UICollectionView, in view: UIView) {
        reset()
        collectionView.isUserInteractionEnabled = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}
