//
//  UIView+AnimationContainer.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 28.12.2025.
//

import UIKit

extension UIView: AnimationContainer {
    public var visibleItems: [AnimatableItem] {
        if let collectionView = self as? UICollectionView {
            return collectionView.visibleCells
        }
        return []
    }
}

