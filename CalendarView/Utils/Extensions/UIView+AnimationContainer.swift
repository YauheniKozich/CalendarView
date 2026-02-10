 import UIKit

extension UIView: AnimationContainer {
    var visibleItems: [AnimatableItem] {
        if let collectionView = self as? UICollectionView {
            return collectionView.visibleCells
        }
        return []
    }
}

