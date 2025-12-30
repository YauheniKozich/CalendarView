//
//  CalendarFlowLayout.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 13.05.25.
//

import UIKit

final class CalendarFlowLayout: UICollectionViewFlowLayout {

    public override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        let numberOfColumns: CGFloat = 7
        let spacing = minimumInteritemSpacing
        let totalSpacing = spacing * (numberOfColumns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / numberOfColumns)

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.width != collectionView.bounds.width
    }

    public override func invalidateLayout() {
        super.invalidateLayout()
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
        let column = indexPath.item % 7
        if column == 0 || column == 6 {
            attributes.zIndex = 1
        }
        return attributes
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)
    }
}
