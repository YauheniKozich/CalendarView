//
//  CalendarViewController.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import UIKit
import Combine

public final class CalendarViewController: UIViewController {
    private enum Section: Sendable {
        case main
    }

    private enum Constants {
        static let cellReuseIdentifier = "CalendarCell"
        static let buttonHeight: CGFloat = 24
        static let verticalSpacing: CGFloat = 8
        static let horizontalMargin: CGFloat = 16
        static let monthLabelHeight: CGFloat = 30
        static let topMargin: CGFloat = 8
    }

    private var collectionView: UICollectionView?
    private var dataSource: UICollectionViewDiffableDataSource<Section, CalendarDay>?
    private let viewModel: any CalendarViewModelProtocol
    private let explosionAnimator: CalendarExplosionAnimator
    private let hapticFeedbackProvider: HapticFeedbackProvider
    private var cancellables = Set<AnyCancellable>()
    private var gestureCancellables = Set<AnyCancellable>()

    private var isUpdatingSubject = CurrentValueSubject<Bool, Never>(false)

    private let monthLabel = UILabel()

    private let clearButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    
    private var gestureCoordinator: GestureCoordinator?

    @MainActor
    init(
        viewModel: any CalendarViewModelProtocol,
        explosionAnimator: CalendarExplosionAnimator,
        hapticFeedbackProvider: HapticFeedbackProvider,
        gestureCoordinator: GestureCoordinator? = nil
    ) {
        self.viewModel = viewModel
        self.explosionAnimator = explosionAnimator
        self.hapticFeedbackProvider = hapticFeedbackProvider
        self.gestureCoordinator = gestureCoordinator

        super.init(nibName: nil, bundle: nil)

        // Настройка callback для восстановления после анимации взрыва
        self.explosionAnimator.onAnimationComplete = { [weak self] in
            guard let self = self else { return }

            // После анимации взрыва получаем все ячейки календаря
            guard let collectionView = self.collectionView else { return }
            let allCells = (0..<collectionView.numberOfItems(inSection: 0)).compactMap { indexPath in
                collectionView.cellForItem(at: IndexPath(item: indexPath, section: 0))
            }

            // Восстанавливаем взаимодействие после анимации взрыва
            self.explosionAnimator.restoreUserInteraction(items: allCells, in: self.view)

            // Принудительно переконфигурируем видимые ячейки для корректного отображения состояний
            for cell in allCells {
                if let calendarCell = cell as? CalendarCell,
                   let indexPath = collectionView.indexPath(for: calendarCell),
                   indexPath.item < self.viewModel.calendarDays.count {
                    // Переконфигурируем ячейку с текущими данными
                    let calendarDay = self.viewModel.calendarDays[indexPath.item]
                    if let date = calendarDay.date {
                        // Используем уже вычисленные значения из CalendarDay для производительности
                        let isSelected = calendarDay.isSelected
                        let isInRange = calendarDay.isInRange
                        let isPast = date < self.viewModel.today

                        calendarCell.configure(with: date, isSelected: isSelected, isInRange: isInRange, isPlaceholder: false, calendar: self.viewModel.calendar)
                        calendarCell.isUserInteractionEnabled = !isPast
                    }
                }
            }
        }
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupMonthLabel()
        setupCollectionView()
        setupButtons()

        viewModel.calendarDaysPublisher
            .sink { [weak self] _ in
                self?.applySnapshot(animatingDifferences: false)
            }
            .store(in: &cancellables)

        viewModel.load()

        clearButton.publisher(for: .touchUpInside)
            .sink { [weak self] in
                self?.viewModel.clear()
                self?.updateMonthLabel()
            }
            .store(in: &cancellables)

        // Настройка кнопки восстановления
        resetButton.publisher(for: .touchUpInside)
            .sink { [weak self] in
                guard let self = self else { return }

                Logger.debug("Reset button tapped", category: .general)

                // Haptic feedback
                self.hapticFeedbackProvider.selectionChanged()

                // Очищаем кеш модели перед обновлением
                // (восстановление может использовать старые данные из кеша)
                self.viewModel.clearDatesCache()

                // Обновляем модель данных
                self.viewModel.updateDays()

                // После анимации взрыва получаем все ячейки календаря
                guard let collectionView = self.collectionView else {
                    Logger.warning("CollectionView not available for reset", category: .general)
                    return
                }
                let allCells = (0..<collectionView.numberOfItems(inSection: 0)).compactMap { indexPath in
                    collectionView.cellForItem(at: IndexPath(item: indexPath, section: 0))
                }

                Logger.debug("Resetting \(allCells.count) cells", category: .general)

                // Восстанавливаем взаимодействие после анимации взрыва
                self.explosionAnimator.restoreUserInteraction(items: allCells, in: self.view)

                // Исследуем проблему с остаточными ячейками
                Logger.debug("Investigating residual cells issue", category: .general)
                Logger.debug("Visible cells before cleanup: \(collectionView.visibleCells.count)", category: .general)

                // Проверяем, есть ли ячейки в collectionView.subviews
                let calendarCellsInSubviews = collectionView.subviews.compactMap { $0 as? CalendarCell }
                Logger.debug("CalendarCell instances in collectionView.subviews: \(calendarCellsInSubviews.count)", category: .general)

                // Проверяем, есть ли ячейки в superview collectionView
                if let superview = collectionView.superview {
                    let allCalendarCells = superview.subviews.compactMap { $0 as? CalendarCell }
                    Logger.debug("Total CalendarCell instances in superview: \(allCalendarCells.count)", category: .general)

                    // Показываем frames остаточных ячеек
                    allCalendarCells.forEach { cell in
                        Logger.debug("Residual cell frame: \(cell.frame)", category: .general)
                    }
                }

                // Агрессивная очистка всех ячеек перед восстановлением
                Logger.debug("Removing all visible cells from view hierarchy", category: .general)
                collectionView.visibleCells.forEach { cell in
                    cell.removeFromSuperview()
                }

                // Также проверяем и удаляем любые CalendarCell из superview
                if let superview = collectionView.superview {
                    let residualCells = superview.subviews.compactMap { $0 as? CalendarCell }
                    Logger.debug("Removing \(residualCells.count) residual CalendarCell instances", category: .general)
                    residualCells.forEach { $0.removeFromSuperview() }
                }

                // Полностью перезагружаем collection view для сброса всех позиций после взрыва
                Logger.debug("Performing full collection view reload after explosion", category: .general)
                collectionView.reloadData()

                // Сбрасываем contentOffset на всякий случай
                collectionView.contentOffset = .zero

                // После перезагрузки пересчитываем layout для правильной сетки
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.setNeedsLayout()
                collectionView.layoutIfNeeded()

                // Не применяем snapshot после reloadData, так как reloadData уже обновил данные
                // self.applySnapshot(animatingDifferences: false)

                Logger.debug("Reset completed - visible cells after reset: \(collectionView.visibleCells.count)", category: .general)
            }
            .store(in: &cancellables)

        viewModel.updateDays()
        updateMonthLabel()
        setupGestureCoordinatorIfNeeded()
    }

    @MainActor
    private func setupGestureCoordinatorIfNeeded() {
        guard gestureCoordinator == nil,
              let collectionView = collectionView else { return }
        let gestureCoordinator = DependencyFactories.GestureCoordinatorFactory.make(for: self.view, gestureView: collectionView)
        setGestureCoordinator(gestureCoordinator)
    }

    @MainActor
    internal func setGestureCoordinator(_ coordinator: GestureCoordinator) {
        gestureCoordinator?.removeGestures()
        self.gestureCoordinator = coordinator
        coordinator.setupGestures()
        gestureCancellables.removeAll()

        coordinator.gestureEventPublisher
            .sink { [weak self] event in
                self?.handleGesture(event)
            }
            .store(in: &gestureCancellables)
    }

    @MainActor
    private func handleGesture(_ event: GestureEvent) {
        switch event.kind {
        case .singleTap:
            // Подсчет тапов для активации взрыва на 5-м тапе
            guard let collectionView = collectionView else { return }
            let visibleCells = collectionView.visibleCells
            explosionAnimator.registerTap(on: visibleCells, in: view)
        case .doubleTap:
            break
        case .swipeLeft:
            handleSwipeReactive(withDirection: .left)
        case .swipeRight:
            handleSwipeReactive(withDirection: .right)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let topInset = view.safeAreaInsets.top
        let bottomInset = view.safeAreaInsets.bottom
        let contentWidth = view.bounds.width - Constants.horizontalMargin * 2

        guard view.bounds.width > 0 && view.bounds.height > 0 else {
            return
        }

        monthLabel.frame = CGRect(
            x: Constants.horizontalMargin,
            y: topInset + Constants.topMargin,
            width: contentWidth,
            height: Constants.monthLabelHeight
        )

        guard let collectionView = collectionView else { return }
        let collectionViewTop = monthLabel.frame.maxY + Constants.topMargin
        let buttonsHeight = Constants.buttonHeight * 2 + Constants.verticalSpacing
        let collectionViewHeight = view.bounds.height - collectionViewTop - bottomInset - buttonsHeight

        collectionView.frame = CGRect(
            x: 0,
            y: collectionViewTop,
            width: view.bounds.width,
            height: collectionViewHeight
        )

        let buttonsY = view.bounds.height - bottomInset - buttonsHeight
        
        clearButton.frame = CGRect(
            x: Constants.horizontalMargin,
            y: buttonsY,
            width: contentWidth,
            height: Constants.buttonHeight
        )

        // Установка frame для кнопки восстановления
        resetButton.frame = CGRect(
            x: Constants.horizontalMargin,
            y: clearButton.frame.maxY + Constants.verticalSpacing,
            width: contentWidth,
            height: Constants.buttonHeight
        )

        Logger.debug("Reset button frame set to: \(resetButton.frame)", category: .general)
    }

    // MARK: - Setup UI

    private func setupMonthLabel() {
        monthLabel.font = UIFont.boldSystemFont(ofSize: 20)
        monthLabel.textAlignment = .center
        monthLabel.textColor = .black
        view.addSubview(monthLabel)
    }

    private func setupCollectionView() {
        let layout = CalendarFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        let newCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        newCollectionView.register(CalendarCell.self, forCellWithReuseIdentifier: Constants.cellReuseIdentifier)
        newCollectionView.delegate = self
        newCollectionView.backgroundColor = .white
        view.addSubview(newCollectionView)
        collectionView = newCollectionView
        
        dataSource = UICollectionViewDiffableDataSource<Section, CalendarDay>(collectionView: newCollectionView) { [weak self] collectionView, indexPath, calendarDay in
            guard let self = self else { return UICollectionViewCell() }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellReuseIdentifier, for: indexPath) as? CalendarCell else {
                return UICollectionViewCell()
            }


            if let date = calendarDay.date {
                let isSelected = calendarDay.isSelected
                let isInRange = calendarDay.isInRange
                let isPast = date < self.viewModel.today

                cell.configure(with: date, isSelected: isSelected, isInRange: isInRange, isPlaceholder: false, calendar: self.viewModel.calendar)
                cell.isUserInteractionEnabled = !isPast

                let dateString = self.viewModel.dateFormatter.string(from: date, format: "d MMMM yyyy")
                cell.configureAccessibility(
                    date: date,
                    dateString: dateString,
                    isSelected: isSelected,
                    isInRange: isInRange,
                    isPast: isPast
                )
            } else {
                cell.configure(with: nil, isSelected: false, isInRange: false, isPlaceholder: true, calendar: self.viewModel.calendar)
                cell.isUserInteractionEnabled = false
                cell.isAccessibilityElement = false
            }
            return cell
        }
    }

    @MainActor
    private func applySnapshot(animatingDifferences: Bool = true) {
        guard let dataSource = dataSource else {
            Logger.error("DataSource is not initialized", category: .calendar)
            return
        }

        let items = viewModel.calendarDays
        var snapshot = NSDiffableDataSourceSnapshot<Section, CalendarDay>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func setupButtons() {
        clearButton.setTitle("Очистить даты", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(clearButton)

        // Настройка кнопки восстановления
        resetButton.setTitle("Восстановить", for: .normal)
        resetButton.setTitleColor(.systemBlue, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        resetButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1) // Для лучшей видимости
        resetButton.layer.borderColor = UIColor.systemBlue.cgColor
        resetButton.layer.borderWidth = 1
        resetButton.layer.cornerRadius = 8
        view.addSubview(resetButton)

        Logger.debug("Reset button added to view", category: .general)
    }

    // MARK: - Reactive Actions

    @MainActor
    private func handleSwipeReactive(withDirection direction: UISwipeGestureRecognizer.Direction) {
        guard !isUpdatingSubject.value else { return }

        isUpdatingSubject.send(true)
        let delta = (direction == .left) ? 1 : -1

        self.viewModel.changeMonth(by: delta)

        self.viewModel.updateDays()

        self.updateMonthLabel()

        guard let collectionView = self.collectionView else { return }
        UIView.transition(with: collectionView, duration: 0.3, options: [.transitionCrossDissolve]) {
            self.applySnapshot()
        } completion: { [weak self] _ in
            self?.isUpdatingSubject.send(false)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func updateMonthLabel() {
        monthLabel.text = viewModel.monthFormatter.string(from: viewModel.currentMonth).capitalized
    }

    deinit {
        cancellables.removeAll()
        gestureCancellables.removeAll()
    }
}

extension CalendarViewController: UICollectionViewDelegate {
    @MainActor
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = dataSource,
              let calendarDay = dataSource.itemIdentifier(for: indexPath),
              let date = calendarDay.date,
              date >= viewModel.today,
              let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        
        hapticFeedbackProvider.selectionChanged()
        
        UIView.animate(withDuration: 0.1, animations: {
            cell.transform = CGAffineTransform(scaleX: 2.2, y: 2.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                cell.transform = CGAffineTransform.identity
            }
        })
        
        viewModel.select(date)
        updateMonthLabel()
    }
}
