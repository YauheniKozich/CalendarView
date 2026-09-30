 import UIKit

/// Аниматор для создания эффекта "взрыва" календарных ячеек
/// Использует UIKit Dynamics для реалистичной физической анимации
/// Изолирован на MainActor, так как работает с UIKit компонентами

@MainActor
final class CalendarExplosionAnimator: NSObject, UIDynamicAnimatorDelegate, ExplosionAnimator, TapTracking {

    @MainActor
    private final class AnimatedCellReference {
        weak var cell: UIView?
        let indexPath: IndexPath?
        let frame: CGRect
        let transform: CGAffineTransform
        let transform3D: CATransform3D
        let isUserInteractionEnabled: Bool

        init(cell: UIView, indexPath: IndexPath?) {
            self.cell = cell
            self.indexPath = indexPath
            self.frame = cell.frame
            self.transform = cell.transform
            self.transform3D = cell.transform3D
            self.isUserInteractionEnabled = cell.isUserInteractionEnabled
        }
    }

    /// Минимальная сила толчка для ячеек
    private var minPushMagnitude: CGFloat
    /// Максимальная сила толчка для ячеек
    private var maxPushMagnitude: CGFloat
    /// Эластичность ячеек при столкновении
    private var elasticity: CGFloat
    /// Высота нижней границы для коллизии (область кнопок)
    private var bottomBoundaryOffset: CGFloat
    /// Максимальное время анимации в секундах
    private var animationTimeout: TimeInterval

    private let minPushMagnitudeRange: ClosedRange<CGFloat> = 0.0...2.0
    private let maxPushMagnitudeRange: ClosedRange<CGFloat> = 0.0...5.0
    private let elasticityRange: ClosedRange<CGFloat> = 0.0...1.0
    private let bottomBoundaryOffsetRange: ClosedRange<CGFloat> = 0.0...200.0
    private let animationTimeoutRange: ClosedRange<TimeInterval> = 1.0...60.0

    private var animator: UIDynamicAnimator?
    private var timeoutTimer: Timer?
    private var gravity: UIGravityBehavior?
    private var collision: UICollisionBehavior?
    private var itemBehavior: UIDynamicItemBehavior?
    private var explosionTask: Task<Void, Never>?
    private var isExploding = false
    private var asyncContinuation: CheckedContinuation<Bool, Never>?
    private var asyncContinuationID: UUID?
    private var animatedCells: [AnimatedCellReference] = []
    private weak var animationContainer: UIView?

    private let tapTracker: TapTracker
    /// Количество тапов для активации взрыва
    var tapThreshold: Int {
        get { tapTracker.tapThreshold }
        set { tapTracker.tapThreshold = newValue }
    }

    /// Callback, вызываемый при завершении анимации
    var onAnimationComplete: (() -> Void)?

    /// Async версия анимации взрыва
    /// - Parameters:
    ///   - items: Массив элементов для анимации
    ///   - container: Контейнер для анимации
    /// - Returns: true если анимация запущена успешно
    @discardableResult
    func explodeAsync(items: [AnimatableItem], in container: AnimationContainer) async -> Bool {
        guard canStartExplosion else {
            return false
        }

        let continuationID = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                do {
                    let (cells, view) = try validatedAnimationTargets(items: items, container: container)
                    guard !cells.isEmpty else {
                        throw CalendarError.invalidAnimationParameters(reason: "No items to animate")
                    }
                    startExplosion(
                        cells: cells,
                        in: view,
                        continuation: continuation,
                        continuationID: continuationID
                    )
                } catch {
                    Logger.error("Async animation failed: \(error.localizedDescription)", category: .animation)
                    continuation.resume(returning: false)
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.cancelAsyncExplosion(id: continuationID)
            }
        }
    }

    /// Инициализация аниматора взрыва
    /// - Parameters:
    ///   - minPushMagnitude: Минимальная сила толчка (по умолчанию 0.5)
    ///   - maxPushMagnitude: Максимальная сила толчка (по умолчанию 1.5)
    ///   - elasticity: Эластичность ячеек при столкновении (по умолчанию 0.6)
    ///   - bottomBoundaryOffset: Отступ нижней границы от safe area (по умолчанию 80.0)
    ///   - animationTimeout: Максимальное время анимации в секундах (по умолчанию 10.0)
    init(minPushMagnitude: CGFloat = 0.5, maxPushMagnitude: CGFloat = 1.5, elasticity: CGFloat = 0.6, bottomBoundaryOffset: CGFloat = 80.0, animationTimeout: TimeInterval = 10.0, tapThreshold: Int = 5) {
        // Применяем валидацию диапазонов
        self.minPushMagnitude = min(max(minPushMagnitude, minPushMagnitudeRange.lowerBound), minPushMagnitudeRange.upperBound)
        self.maxPushMagnitude = min(max(maxPushMagnitude, maxPushMagnitudeRange.lowerBound), maxPushMagnitudeRange.upperBound)
        self.elasticity = min(max(elasticity, elasticityRange.lowerBound), elasticityRange.upperBound)
        self.bottomBoundaryOffset = min(max(bottomBoundaryOffset, bottomBoundaryOffsetRange.lowerBound), bottomBoundaryOffsetRange.upperBound)
        self.animationTimeout = min(max(animationTimeout, animationTimeoutRange.lowerBound), animationTimeoutRange.upperBound)
        self.tapTracker = TapTracker(tapThreshold: tapThreshold)
    }

    /// Запускает анимацию взрыва для указанных элементов
    /// - Parameters:
    ///   - items: Массив элементов для анимации
    ///   - container: Контейнер для анимации
    /// - Throws: CalendarError при ошибках валидации
    func explode(items: [AnimatableItem], in container: AnimationContainer) throws {
        let (cells, view) = try validatedAnimationTargets(items: items, container: container)

        guard !cells.isEmpty else {
            Logger.warning("Нет элементов для анимации", category: .animation)
            throw CalendarError.invalidAnimationParameters(reason: "No items to animate")
        }

        guard canStartExplosion else {
            Logger.warning("Анимация уже выполняется", category: .animation)
            throw CalendarError.animationInProgress
        }

        // Bounds checking - проверяем что все элементы в пределах контейнера
        let itemsOutsideBounds = cells.filter { !view.bounds.contains($0.frame) }
        if !itemsOutsideBounds.isEmpty {
            Logger.warning("Найдено \(itemsOutsideBounds.count) элементов вне границ контейнера", category: .animation)
        }

        startExplosion(cells: cells, in: view)
    }

    private func validatedAnimationTargets(
        items: [AnimatableItem],
        container: AnimationContainer
    ) throws -> ([UIView], UIView) {
        guard let cells = items as? [UIView], let view = container as? UIView else {
            Logger.error("Unsupported types for animation", category: .animation)
            throw CalendarError.invalidAnimationParameters(reason: "Unsupported types for animation")
        }
        return (cells, view)
    }

    private func startExplosion(
        cells: [UIView],
        in view: UIView,
        continuation: CheckedContinuation<Bool, Never>? = nil,
        continuationID: UUID? = nil
    ) {
        reset()
        animationContainer = view
        let collectionView = cells
            .compactMap { ($0 as? UICollectionViewCell)?.superview as? UICollectionView }
            .first
        animatedCells = cells.map { cell in
            let indexPath = (cell as? UICollectionViewCell).flatMap { collectionView?.indexPath(for: $0) }
            return AnimatedCellReference(cell: cell, indexPath: indexPath)
        }
        isExploding = true
        asyncContinuation = continuation
        asyncContinuationID = continuationID

        setupDynamicAnimator(in: view)
        setupPhysicsBehaviors(for: cells)
        applyExplosionForces(to: cells)
        // Анимация завершится автоматически через UIDynamicAnimatorDelegate
    }

    /// Безопасная версия запуска анимации (не выбрасывает ошибки)
    /// - Parameters:
    ///   - items: Массив элементов для анимации
    ///   - container: Контейнер для анимации
    func explodeSafely(items: [AnimatableItem], in container: AnimationContainer) {
        do {
            try explode(items: items, in: container)
        } catch {
            Logger.error("Animation failed: \(error.localizedDescription)", category: .animation)
        }
    }
    
    /// Настройка динамического аниматора
    private func setupDynamicAnimator(in view: UIView) {
        animator = UIDynamicAnimator(referenceView: view)
        animator?.delegate = self

        // Запускаем таймер для предотвращения бесконечной анимации
        startTimeoutTimer()
    }

    /// Запуск таймера таймаута анимации
    private func startTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: animationTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Logger.warning("Animation timeout reached, forcing completion", category: .animation)
            // Timer выполняется на main run loop, но для безопасности используем Task
            Task { @MainActor [weak self] in
                self?.forceAnimationCompletion()
            }
        }
    }

    /// Принудительное завершение анимации
    private func forceAnimationCompletion() {
        guard isExploding else { return }
        completeAnimation()
    }
    
    /// Настройка физических поведений
    private func setupPhysicsBehaviors(for cells: [UIView]) {
        gravity = UIGravityBehavior(items: cells)

        collision = UICollisionBehavior(items: cells)
        collision?.translatesReferenceBoundsIntoBoundary = false

        // Добавляем границы view
        if let referenceView = animator?.referenceView {
            let bounds = referenceView.bounds
            // Верхняя граница
            collision?.addBoundary(withIdentifier: "top" as NSCopying, from: CGPoint(x: bounds.minX, y: bounds.minY), to: CGPoint(x: bounds.maxX, y: bounds.minY))
            // Левая граница
            collision?.addBoundary(withIdentifier: "left" as NSCopying, from: CGPoint(x: bounds.minX, y: bounds.minY), to: CGPoint(x: bounds.minX, y: bounds.maxY))
            // Правая граница
            collision?.addBoundary(withIdentifier: "right" as NSCopying, from: CGPoint(x: bounds.maxX, y: bounds.minY), to: CGPoint(x: bounds.maxX, y: bounds.maxY))

            // Нижняя граница устанавливается выше, чтобы ячейки падали на область кнопок
            // Используем safe area bottom inset для расчета
            let safeAreaInsets = referenceView.safeAreaInsets
            let bottomBoundaryY = bounds.maxY - safeAreaInsets.bottom - bottomBoundaryOffset
            collision?.addBoundary(withIdentifier: "bottom" as NSCopying, from: CGPoint(x: bounds.minX, y: bottomBoundaryY), to: CGPoint(x: bounds.maxX, y: bottomBoundaryY))
        }

        itemBehavior = UIDynamicItemBehavior(items: cells)
        itemBehavior?.elasticity = elasticity
        itemBehavior?.allowsRotation = true

        [gravity, collision, itemBehavior].compactMap { $0 }.forEach { behavior in
            animator?.addBehavior(behavior)
        }
    }
    
    /// Применение сил взрыва к элементам
    private func applyExplosionForces(to cells: [UIView]) {
        explosionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            for cell in cells {
                let delay = TimeInterval.random(in: 0...0.2)
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }

                guard !Task.isCancelled, let animator = self.animator else { return }
                
                let push = UIPushBehavior(items: [cell], mode: .instantaneous)
                push.angle = CGFloat.random(in: 0...(.pi * 2))
                push.magnitude = CGFloat.random(in: self.minPushMagnitude...self.maxPushMagnitude)
                animator.addBehavior(push)
            }
        }
    }

    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        guard isExploding, self.animator === animator else { return }
        completeAnimation()
    }

    private func completeAnimation() {
        isExploding = false
        explosionTask?.cancel()
        explosionTask = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        asyncContinuation?.resume(returning: true)
        asyncContinuation = nil
        asyncContinuationID = nil
        onAnimationComplete?()
    }

    private func cancelAsyncExplosion(id: UUID) {
        guard asyncContinuationID == id else { return }
        restoreUserInteraction(items: [], in: animationContainer ?? UIView())
    }

    /// Сброс всех анимаций и состояний
    func reset() {
        explosionTask?.cancel()
        explosionTask = nil
        asyncContinuation?.resume(returning: false)
        asyncContinuation = nil
        asyncContinuationID = nil
        animator?.removeAllBehaviors()
        animator = nil
        gravity = nil
        collision = nil
        itemBehavior = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        animationContainer = nil
        animatedCells.removeAll()
        isExploding = false
        tapTracker.resetTapCount()  // Сбрасываем счетчик тапов через TapTracker
    }

    /// Регистрирует тап и запускает взрыв при достижении порога
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    func registerTap(on items: [AnimatableItem], in container: AnimationContainer) {
        guard canStartExplosion else { return }

        if tapTracker.registerTap() {
            explodeSafely(items: items, in: container)
            // Отключаем взаимодействие только для UIView элементов
            (items as? [UIView])?.forEach { $0.isUserInteractionEnabled = false }
            tapTracker.resetTapCount()
        }
    }

    /// Восстанавливает пользовательское взаимодействие и сбрасывает анимацию
    /// - Parameters:
    ///   - items: Элементы для восстановления
    ///   - container: Контейнер для обновления
    func restoreUserInteraction(items: [AnimatableItem], in container: AnimationContainer) {
        let trackedCells = animatedCells
        let trackedStates = Dictionary(
            trackedCells.compactMap { reference -> (ObjectIdentifier, AnimatedCellReference)? in
                guard let cell = reference.cell else { return nil }
                return (ObjectIdentifier(cell), reference)
            },
            uniquingKeysWith: { first, _ in first }
        )
        let trackedIndexPaths = Dictionary(
            trackedCells.compactMap { reference -> (ObjectIdentifier, IndexPath)? in
                guard let cell = reference.cell, let indexPath = reference.indexPath else { return nil }
                return (ObjectIdentifier(cell), indexPath)
            },
            uniquingKeysWith: { first, _ in first }
        )
        var seenItems = Set<ObjectIdentifier>()
        let uiItems = (items.compactMap { $0 as? UIView } + trackedCells.compactMap(\.cell))
            .filter { seenItems.insert(ObjectIdentifier($0)).inserted }

        reset()

        uiItems.forEach { uiItem in
            if let originalState = trackedStates[ObjectIdentifier(uiItem)] {
                uiItem.isUserInteractionEnabled = originalState.isUserInteractionEnabled
                uiItem.frame = originalState.frame
                uiItem.transform = originalState.transform
                uiItem.transform3D = originalState.transform3D
            } else {
                uiItem.transform = .identity
            }
        }

        if let collectionView = container as? UICollectionView {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()

            for cell in uiItems.compactMap({ $0 as? UICollectionViewCell }) {
                let indexPath = trackedIndexPaths[ObjectIdentifier(cell)]
                    ?? collectionView.indexPath(for: cell)
                guard
                    let indexPath,
                    let attributes = collectionView.collectionViewLayout
                        .layoutAttributesForItem(at: indexPath)
                else { continue }

                cell.transform = .identity
                cell.frame = attributes.frame
                cell.transform3D = attributes.transform3D
            }

            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
        } else if let uiContainer = container as? UIView {
            uiContainer.setNeedsLayout()
            uiContainer.layoutIfNeeded()
        }

        animatedCells.removeAll()
    }
    
    /// Проверяет, выполняется ли анимация
    var isAnimating: Bool {
        return isExploding
    }

    private var canStartExplosion: Bool {
        !isExploding && animatedCells.isEmpty
    }
    
    /// Сбрасывает счетчик тапов
    func resetTapCount() {
        tapTracker.resetTapCount()
    }
}
