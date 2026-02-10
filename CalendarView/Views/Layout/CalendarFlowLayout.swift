 import UIKit

final class CalendarFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        let numberOfColumns: CGFloat = 7
        let spacing = minimumInteritemSpacing
        let totalSpacing = spacing * (numberOfColumns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        guard availableWidth > 0 else { return }
        let itemWidth = floor(availableWidth / numberOfColumns)
        guard itemWidth > 0 else { return }

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }

    override func invalidateLayout() {
        super.invalidateLayout()
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
        let column = indexPath.item % 7
        if column == 0 || column == 6 {
            attributes.zIndex = 1
        }
        return attributes
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)
    }
}
