//
//  CalendarExplosionAnimator.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import UIKit

// MARK: - Logger

/// Аниматор для создания эффекта "взрыва" календарных ячеек
/// Использует UIKit Dynamics для реалистичной физической анимации
/// Изолирован на MainActor, так как работает с UIKit компонентами

public final class CalendarExplosionAnimator: NSObject, UIDynamicAnimatorDelegate, ExplosionAnimator, TapTracking {

    // MARK: - Configuration Properties

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

    // MARK: - Validation Ranges

    private let minPushMagnitudeRange: ClosedRange<CGFloat> = 0.0...2.0
    private let maxPushMagnitudeRange: ClosedRange<CGFloat> = 0.0...5.0
    private let elasticityRange: ClosedRange<CGFloat> = 0.0...1.0
    private let bottomBoundaryOffsetRange: ClosedRange<CGFloat> = 0.0...200.0
    private let animationTimeoutRange: ClosedRange<TimeInterval> = 1.0...60.0

    // MARK: - Animation Properties

    private var animator: UIDynamicAnimator?
    private var timeoutTimer: Timer?
    private var gravity: UIGravityBehavior?
    private var collision: UICollisionBehavior?
    private var itemBehavior: UIDynamicItemBehavior?
    private var isExploding = false

    // MARK: - Tap Tracking

    private let tapTracker: TapTracker
    /// Количество тапов для активации взрыва
    public var tapThreshold: Int {
        get { tapTracker.tapThreshold }
        set { tapTracker.tapThreshold = newValue }
    }

    // MARK: - Callbacks

    /// Callback, вызываемый при завершении анимации
    public var onAnimationComplete: (() -> Void)?

    /// Async версия анимации взрыва
    /// - Parameters:
    ///   - items: Массив элементов для анимации
    ///   - container: Контейнер для анимации
    /// - Returns: true если анимация запущена успешно
    @discardableResult
    public func explodeAsync(items: [AnimatableItem], in container: AnimationContainer) async -> Bool {
        // Если анимация уже идет, завершаем немедленно
        if self.isExploding {
            return false
        }

        do {
            try self.explode(items: items, in: container)
            return await withCheckedContinuation { continuation in
                self.onAnimationComplete = {
                    continuation.resume(returning: true)
                }
            }
        } catch {
            Logger.error("Async animation failed: \(error.localizedDescription)", category: .animation)
            return false
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
    public func explode(items: [AnimatableItem], in container: AnimationContainer) throws {
        // Поскольку это UIKit-специфичная реализация, приводим типы
        guard let cells = items as? [UIView],
              let view = container as? UIView else {
            Logger.error("Unsupported types for animation", category: .animation)
            throw CalendarError.invalidAnimationParameters(reason: "Unsupported types for animation")
        }

        // Метод уже изолирован на MainActor через @MainActor на классе
        // Проверка Thread.isMainThread оставлена для дополнительной безопасности
        guard Thread.isMainThread else {
            // Если вызван не с main thread, перенаправляем на main actor
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                try? self.explode(items: items, in: container)
            }
            return
        }

        guard !cells.isEmpty else {
            Logger.warning("Нет элементов для анимации", category: .animation)
            throw CalendarError.invalidAnimationParameters(reason: "No items to animate")
        }

        guard !isExploding else {
            Logger.warning("Анимация уже выполняется", category: .animation)
            throw CalendarError.animationInProgress
        }

        // Bounds checking - проверяем что все элементы в пределах контейнера
        let itemsOutsideBounds = cells.filter { !view.bounds.contains($0.frame) }
        if !itemsOutsideBounds.isEmpty {
            Logger.warning("Найдено \(itemsOutsideBounds.count) элементов вне границ контейнера", category: .animation)
        }

        reset()
        isExploding = true

        setupDynamicAnimator(in: view)
        setupPhysicsBehaviors(for: cells)
        applyExplosionForces(to: cells)
        // Анимация завершится автоматически через UIDynamicAnimatorDelegate
    }

    /// Безопасная версия запуска анимации (не выбрасывает ошибки)
    /// - Parameters:
    ///   - items: Массив элементов для анимации
    ///   - container: Контейнер для анимации
    public func explodeSafely(items: [AnimatableItem], in container: AnimationContainer) {
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
        isExploding = false
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        onAnimationComplete?()
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
        Task { @MainActor [weak self] in
            guard let self  else { return }
            
            for cell in cells {
                let delay = TimeInterval.random(in: 0...0.2)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                let push = UIPushBehavior(items: [cell], mode: .instantaneous)
                push.angle = CGFloat.random(in: 0...(.pi * 2))
                push.magnitude = CGFloat.random(in: self.minPushMagnitude...self.maxPushMagnitude)
                self.animator?.addBehavior(push)
            }
        }
    }
    
    // MARK: - UIDynamicAnimatorDelegate

    public func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        isExploding = false
        onAnimationComplete?()
    }

    /// Сброс всех анимаций и состояний
    public func reset() {
        animator?.removeAllBehaviors()
        animator = nil
        gravity = nil
        collision = nil
        itemBehavior = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        isExploding = false
        tapTracker.resetTapCount()  // Сбрасываем счетчик тапов через TapTracker
    }

    /// Регистрирует тап и запускает взрыв при достижении порога
    /// - Parameters:
    ///   - items: Элементы для анимации
    ///   - container: Контейнер для анимации
    public func registerTap(on items: [AnimatableItem], in container: AnimationContainer) {
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
    public func restoreUserInteraction(items: [AnimatableItem], in container: AnimationContainer) {
        reset()

        let uiItems = items.compactMap { $0 as? UIView }

        uiItems.forEach { uiItem in
            uiItem.isUserInteractionEnabled = true
            // Сбрасываем трансформации к единичной матрице для восстановления нормального вида
            uiItem.transform = .identity
        }

        // Дополнительно сбрасываем любые изменения center, которые мог внести UIDynamicAnimator
        // Это поможет восстановить правильные позиции ячеек
        if let uiContainer = container as? UIView {
            uiContainer.subviews.forEach { subview in
                // Если subview - это ячейка календаря, сбрасываем любые смещения
                if uiItems.contains(subview) {
                    // Центр должен соответствовать оригинальной позиции
                    // Для collection view ячеек center обычно соответствует center их frame
                    let originalCenter = CGPoint(x: subview.frame.midX, y: subview.frame.midY)
                    if subview.center != originalCenter {
                        subview.center = originalCenter
                    }
                }
            }
        }

        if let uiContainer = container as? UIView {
            uiContainer.setNeedsLayout()
            uiContainer.layoutIfNeeded()
        }
    }
    
    /// Проверяет, выполняется ли анимация
    public var isAnimating: Bool {
        return isExploding
    }
    
    /// Сбрасывает счетчик тапов
    public func resetTapCount() {
        tapTracker.resetTapCount()
    }
}
