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
    }

    private var collectionView: UICollectionView!
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, CalendarDay> = {
        return UICollectionViewDiffableDataSource<Section, CalendarDay>(collectionView: collectionView) { [weak self] collectionView, indexPath, calendarDay in
            guard let self = self else { return UICollectionViewCell() }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellReuseIdentifier, for: indexPath) as? CalendarCell else {
                return UICollectionViewCell()
            }

            Logger.debug("Configuring cell at \(indexPath) with calendarDay: date=\(calendarDay.date?.description ?? "nil"), isSelected=\(calendarDay.isSelected), isPlaceholder=\(calendarDay.isPlaceholder)", category: .calendar)

            if let date = calendarDay.date {
                // Используем уже вычисленные значения из CalendarDay для производительности
                let isSelected = calendarDay.isSelected
                let isInRange = calendarDay.isInRange
                let isPast = date < self.viewModel.today

                cell.configure(with: date, isSelected: isSelected, isInRange: isInRange, isPlaceholder: false, calendar: self.viewModel.calendar)
                cell.isUserInteractionEnabled = !isPast
                cell.isAccessibilityElement = true

                // Улучшенная accessibility поддержка
                let dateString = self.accessibilityDateFormatter.string(from: date)

                var accessibilityLabel = dateString

                if isSelected {
                    accessibilityLabel += ", выбрана"
                } else if isInRange {
                    accessibilityLabel += ", в диапазоне"
                }

                if isPast {
                    accessibilityLabel += ", прошедшая дата"
                }

                cell.accessibilityLabel = accessibilityLabel

                if isPast {
                    cell.accessibilityHint = "Эта дата уже прошла и недоступна для выбора"
                } else if !isSelected {
                    cell.accessibilityHint = "Двойное нажатие для выбора даты"
                } else {
                    cell.accessibilityHint = "Дата уже выбрана"
                }

                cell.accessibilityTraits = isSelected ? [.button, .selected] : .button
            } else {
                cell.configure(with: nil, isSelected: false, isInRange: false, isPlaceholder: true, calendar: self.viewModel.calendar)
                cell.isUserInteractionEnabled = false
                cell.isAccessibilityElement = false
            }
            return cell
        }
    }()
    private let viewModel: any CalendarViewModelProtocol
    private let explosionAnimator: CalendarExplosionAnimator
    private var cancellables = Set<AnyCancellable>()
    private var gestureCancellables = Set<AnyCancellable>()

    private var isUpdatingSubject = CurrentValueSubject<Bool, Never>(false)

    private let monthLabel = UILabel()

    private lazy var accessibilityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private let clearButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    
    private var gestureCoordinator: GestureCoordinator?

    @MainActor
    init(viewModel: any CalendarViewModelProtocol, explosionAnimator: CalendarExplosionAnimator, gestureCoordinator: GestureCoordinator? = nil) {
        self.viewModel = viewModel
        self.explosionAnimator = explosionAnimator
        self.gestureCoordinator = gestureCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        viewModel.load()

        viewModel.calendarDaysPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
            }
            .store(in: &cancellables)

        setupMonthLabel()
        setupCollectionView()
        setupButtons()

        clearButton.publisher(for: .touchUpInside)
            .sink { [weak self] in
                self?.viewModel.clear()
                self?.updateMonthLabel()
            }
            .store(in: &cancellables)

        resetButton.publisher(for: .touchUpInside)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                Logger.info("Reset button pressed - restoring interaction", category: .gesture)

                // После анимации взрыва получаем все ячейки календаря
                let allCells = (0..<self.collectionView.numberOfItems(inSection: 0)).compactMap { indexPath in
                    self.collectionView.cellForItem(at: IndexPath(item: indexPath, section: 0))
                }
                Logger.info("Found \(allCells.count) total cells to restore", category: .gesture)

                // Восстанавливаем взаимодействие после анимации взрыва
                self.explosionAnimator.restoreUserInteraction(items: allCells, in: self.view)

                // Обновляем отображение календаря
                self.viewModel.updateDays()
                self.applySnapshot()

                Logger.info("Interaction and display restored", category: .gesture)
            }
            .store(in: &cancellables)

        viewModel.updateDays()
        updateMonthLabel()

        // Настройка gesture coordinator после инициализации view
        setupGestureCoordinatorIfNeeded()
    }

    @MainActor
    private func setupGestureCoordinatorIfNeeded() {
        guard gestureCoordinator == nil else { return }
        let gestureCoordinator = DependencyFactories.GestureCoordinatorFactory.make(for: self.view, gestureView: collectionView)
        setGestureCoordinator(gestureCoordinator)
    }

    @MainActor
    internal func setGestureCoordinator(_ coordinator: GestureCoordinator) {
        // Очищаем предыдущий gestureCoordinator
        gestureCoordinator?.removeGestures()
        self.gestureCoordinator = coordinator
        coordinator.setupGestures()

        // Очищаем старые gesture подписки перед добавлением новой
        gestureCancellables.removeAll()

        coordinator.gestureEventPublisher
            .sink { [weak self] event in
                self?.handleGesture(event)
            }
            .store(in: &gestureCancellables)
    }

    @MainActor
    private func handleGesture(_ event: GestureEvent) {
        Logger.debug("Gesture received: \(event.kind)", category: .gesture)

        switch event.kind {
        case .singleTap:
            // Подсчет тапов для активации взрыва на 5-м тапе
            let visibleCells = collectionView.visibleCells
            Logger.debug("Single tap: registering with \(visibleCells.count) visible cells", category: .gesture)
            explosionAnimator.registerTap(on: visibleCells, in: view)
        case .doubleTap:
            // Double tap временно отключен для тестирования
            Logger.debug("Double tap received (ignored)", category: .gesture)
            break
        case .swipeLeft:
            Logger.debug("Swipe left received", category: .gesture)
            handleSwipeReactive(withDirection: .left)
        case .swipeRight:
            Logger.debug("Swipe right received", category: .gesture)
            handleSwipeReactive(withDirection: .right)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let topInset = view.safeAreaInsets.top
        let bottomInset = view.safeAreaInsets.bottom
        let buttonHeight: CGFloat = 24
        let verticalSpacing: CGFloat = 8

        monthLabel.frame = CGRect(x: 16, y: topInset + 8,
                                  width: view.bounds.width - 32,
                                  height: 30)

        collectionView.frame = CGRect(x: 0,
                                      y: monthLabel.frame.maxY + 8,
                                      width: view.bounds.width,
                                      height: view.bounds.height - monthLabel.frame.maxY - 8 - bottomInset - (buttonHeight * 2 + verticalSpacing * 2))

        clearButton.frame = CGRect(x: 16,
                                   y: view.bounds.height - bottomInset - buttonHeight * 2 - verticalSpacing,
                                   width: view.bounds.width - 32,
                                   height: buttonHeight)

        resetButton.frame = CGRect(x: 16,
                                   y: clearButton.frame.maxY + verticalSpacing,
                                   width: view.bounds.width - 32,
                                   height: buttonHeight)
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

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: Constants.cellReuseIdentifier)
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
    }

    @MainActor
    private func applySnapshot(animatingDifferences: Bool = true) {
        let items = viewModel.makeCalendarDays()
        Logger.info("Applying snapshot with \(items.count) calendar days, animating: \(animatingDifferences)", category: .calendar)

        // Логируем первые несколько элементов для проверки
        if let firstItem = items.first {
            Logger.debug("First calendar day: date=\(firstItem.date?.description ?? "nil"), isSelected=\(firstItem.isSelected)", category: .calendar)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, CalendarDay>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)

        // Принудительно перезагружаем видимые ячейки для обновления отображения
        if !animatingDifferences {
            Logger.debug("Reloading visible cells to force UI update", category: .calendar)
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }

    private func setupButtons() {
        clearButton.setTitle("Очистить даты", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(clearButton)

        resetButton.setTitle("Восстановить", for: .normal)
        resetButton.setTitleColor(.systemBlue, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(resetButton)
    }

    // MARK: - Reactive Actions

    @MainActor
    private func handleSwipeReactive(withDirection direction: UISwipeGestureRecognizer.Direction) {
        // Предотвращаем одновременные swipe анимации
        guard !isUpdatingSubject.value else { return }

        isUpdatingSubject.send(true)
        let delta = (direction == .left) ? 1 : -1

        Logger.info("Swipe \(direction == .left ? "left" : "right") - changing month by \(delta)", category: .gesture)

        self.viewModel.changeMonth(by: delta)
        Logger.info("Month changed, current month: \(self.viewModel.currentMonth)", category: .gesture)

        self.viewModel.updateDays()
        Logger.info("Days updated", category: .gesture)

        self.updateMonthLabel()
        Logger.info("Month label updated to: \(self.monthLabel.text ?? "nil")", category: .gesture)

        UIView.transition(with: self.collectionView, duration: 0.3, options: [.transitionCrossDissolve]) {
            Logger.info("Applying snapshot with animation", category: .gesture)
            self.applySnapshot()
        } completion: { [weak self] _ in
            Logger.info("Swipe animation completed", category: .gesture)
            self?.isUpdatingSubject.send(false)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func updateMonthLabel() {
        monthLabel.text = viewModel.monthFormatter.string(from: viewModel.currentMonth).capitalized
    }

    deinit {
        gestureCancellables.removeAll()
    }
}

extension CalendarViewController: UICollectionViewDelegate {
    @MainActor
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let calendarDay = dataSource.itemIdentifier(for: indexPath),
              let date = calendarDay.date,
              date >= viewModel.today else {
            return
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        
        // Haptic feedback
        feedbackGenerator.selectionChanged()
        
        UIView.animate(withDuration: 0.1, animations: {
            cell.transform = CGAffineTransform(scaleX: 2.2, y: 2.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                cell.transform = CGAffineTransform.identity
            }
        })
        
        viewModel.select(date)
    }
}
