 import UIKit

final class CalendarViewController: UIViewController {

    private enum Section {
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

    private let viewModel: any CalendarViewModelProtocol
    private let explosionAnimator: CalendarExplosionAnimator
    private let hapticFeedbackProvider: HapticFeedbackProvider

    private let monthLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    private lazy var collectionView: UICollectionView = {
        let layout = CalendarFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.accessibilityIdentifier = "calendarCollectionView"
        cv.register(
            CalendarCell.self,
            forCellWithReuseIdentifier: Constants.cellReuseIdentifier
        )
        cv.delegate = self
        cv.backgroundColor = .white
        return cv
    }()

    private lazy var dataSource = DataSourceBuilder.make(
        for: collectionView,
        viewModel: viewModel
    )

    /// Флаг предотвращения одновременных анимаций переключения месяцев
    /// Доступ только из main thread (UI operations)
    private var isMonthTransitionInProgress = false
    private var gestureCoordinator: GestureCoordinator?
    private var isGestureCoordinatorSetup = false

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
        configureExplosionCallback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        bindViewModel()

        viewModel.load()
        render()

        setupGestureCoordinatorIfNeeded()
    }

    private func bindViewModel() {
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
    }

    @objc private func clearButtonTapped() {
        viewModel.clear()
        render()
    }

    @objc private func resetButtonTapped() {
        handleReset()
    }

    private enum DataSourceBuilder {
        static func make(
            for collectionView: UICollectionView,
            viewModel: CalendarViewModelProtocol
        ) -> UICollectionViewDiffableDataSource<Section, CalendarDay> {
            UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, calendarDay in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: Constants.cellReuseIdentifier,
                    for: indexPath
                ) as? CalendarCell else {
                    return UICollectionViewCell()
                }

                configure(
                    cell,
                    with: calendarDay,
                    viewModel: viewModel
                )

                return cell
            }
        }

        private static func configure(
            _ cell: CalendarCell,
            with calendarDay: CalendarDay,
            viewModel: CalendarViewModelProtocol
        ) {
            if let date = calendarDay.date {
                let isSelected = calendarDay.isSelected
                let isInRange = calendarDay.isInRange
                let isPast = date < viewModel.today

                cell.configure(
                    with: date,
                    isSelected: isSelected,
                    isInRange: isInRange,
                    isPlaceholder: false,
                    calendar: viewModel.calendar
                )

                cell.isUserInteractionEnabled = !isPast

                let dateString = viewModel.dateFormatter
                    .string(from: date, format: "d MMMM yyyy")

                cell.configureAccessibility(
                    date: date,
                    dateString: dateString,
                    isSelected: isSelected,
                    isInRange: isInRange,
                    isPast: isPast
                )
            } else {
                cell.configure(
                    with: nil,
                    isSelected: false,
                    isInRange: false,
                    isPlaceholder: true,
                    calendar: viewModel.calendar
                )
                cell.isUserInteractionEnabled = false
                cell.isAccessibilityElement = false
            }
        }
    }

    private func applySnapshot(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CalendarDay>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.calendarDays)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func configureExplosionCallback() {
        explosionAnimator.onAnimationComplete = { [weak self] in
            self?.restoreAfterExplosion()
        }
    }

    private func restoreAfterExplosion() {
        let cells = collectionView.visibleCells
        explosionAnimator.restoreUserInteraction(items: cells, in: view)
        render(animated: false)
    }

    private func handleReset() {
        hapticFeedbackProvider.selectionChanged()
        viewModel.clearDatesCache()
        viewModel.updateDays()
        explosionAnimator.restoreUserInteraction(items: collectionView.visibleCells, in: view)
        explosionAnimator.resetTapCount()
        render(animated: false)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupGestureCoordinatorIfNeeded() {
        guard !isGestureCoordinatorSetup else { return }

        if let existingCoordinator = gestureCoordinator {
            setGestureCoordinator(existingCoordinator)
            isGestureCoordinatorSetup = true
            return
        }

        let coordinator = DependencyFactories
            .GestureCoordinatorFactory
            .make(for: view, gestureView: collectionView)

        setGestureCoordinator(coordinator)
        isGestureCoordinatorSetup = true
    }

    internal func setGestureCoordinator(_ coordinator: GestureCoordinator) {
        if gestureCoordinator === coordinator {
            coordinator.onGestureEvent = { [weak self] event in
                self?.handleGesture(event)
            }

            if !coordinator.isActive {
                coordinator.setupGestures()
            }
            return
        }

        gestureCoordinator?.removeGestures()
        gestureCoordinator = coordinator

        coordinator.onGestureEvent = { [weak self] event in
            self?.handleGesture(event)
        }

        if !coordinator.isActive {
            coordinator.setupGestures()
        }
    }

    private func handleGesture(_ event: GestureEvent) {
        switch event.kind {
        case .singleTap:
            explosionAnimator.registerTap(
                on: collectionView.visibleCells,
                in: view
            )

        case .doubleTap:
            break

        case .swipeLeft:
            handleSwipe(direction: .left)

        case .swipeRight:
            handleSwipe(direction: .right)
        }
    }

    private func handleSwipe(direction: UISwipeGestureRecognizer.Direction) {
        guard !isMonthTransitionInProgress else { return }
        isMonthTransitionInProgress = true

        let delta = direction == .left ? 1 : -1
        viewModel.changeMonth(by: delta)
        updateMonthLabel()

        UIView.transition(
            with: collectionView,
            duration: 0.3,
            options: [.transitionCrossDissolve]
        ) {
            self.applySnapshot()
        } completion: { [weak self] _ in
            self?.isMonthTransitionInProgress = false
        }
    }

    private func setupUI() {
        setupMonthLabel()
        view.addSubview(collectionView)
        setupButtons()
    }

    private func setupMonthLabel() {
        monthLabel.font = .boldSystemFont(ofSize: 20)
        monthLabel.textAlignment = .center
        monthLabel.textColor = .black
        view.addSubview(monthLabel)
    }

    private func setupButtons() {
        clearButton.setTitle("Очистить даты", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)

        resetButton.setTitle("Восстановить", for: .normal)
        resetButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        resetButton.layer.cornerRadius = 8

        view.addSubview(clearButton)
        view.addSubview(resetButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let width = view.bounds.width - Constants.horizontalMargin * 2

        monthLabel.frame = CGRect(
            x: Constants.horizontalMargin,
            y: safeTop + Constants.topMargin,
            width: width,
            height: Constants.monthLabelHeight
        )

        let buttonsHeight =
            Constants.buttonHeight * 2 + Constants.verticalSpacing

        let collectionTop = monthLabel.frame.maxY + Constants.topMargin

        collectionView.frame = CGRect(
            x: 0,
            y: collectionTop,
            width: view.bounds.width,
            height: view.bounds.height
                - collectionTop
                - buttonsHeight
                - safeBottom
        )

        clearButton.frame = CGRect(
            x: Constants.horizontalMargin,
            y: view.bounds.height - safeBottom - buttonsHeight,
            width: width,
            height: Constants.buttonHeight
        )

        resetButton.frame = CGRect(
            x: Constants.horizontalMargin,
            y: clearButton.frame.maxY + Constants.verticalSpacing,
            width: width,
            height: Constants.buttonHeight
        )
    }

    private func updateMonthLabel() {
        monthLabel.text = viewModel.monthFormatter
            .string(from: viewModel.currentMonth)
            .capitalized
    }

    private func render(animated: Bool = true) {
        updateMonthLabel()
        applySnapshot(animated: animated)
    }
}

extension CalendarViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard
            let calendarDay = dataSource.itemIdentifier(for: indexPath),
            let date = calendarDay.date,
            date >= viewModel.today,
            let cell = collectionView.cellForItem(at: indexPath)
        else { return }

        hapticFeedbackProvider.selectionChanged()

        UIView.animate(withDuration: 0.1) {
            cell.transform = CGAffineTransform(scaleX: 2.2, y: 2.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                cell.transform = .identity
            }
        }

        viewModel.select(date)
        updateMonthLabel()
        applySnapshot()
    }
}
