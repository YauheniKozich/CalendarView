 import UIKit

final class CalendarViewController: UIViewController {

    private enum Section {
        case main
    }

    private enum Constants {
        static let cellReuseIdentifier = "CalendarCell"
        static let horizontalMargin: CGFloat = 16
        static let layoutSpacing: CGFloat = 8
        static let weekdayHeaderHeight: CGFloat = 32
        static let minimumButtonHeight: CGFloat = 44
    }

    private let viewModel: any CalendarViewModelProtocol
    private let explosionAnimator: CalendarExplosionAnimator
    private let hapticFeedbackProvider: HapticFeedbackProvider

    private let monthLabel = UILabel()
    private let weekdayStackView = UIStackView()
    private let buttonsStackView = UIStackView()
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
        cv.backgroundColor = .systemBackground
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

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
        do {
            try viewModel.clear()
        } catch {
            Logger.error("Failed to clear selected dates: \(error.localizedDescription)", category: .storage)
        }
        render()
    }

    @objc private func resetButtonTapped() {
        handleReset()
    }

    @MainActor
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
                    isPast: isPast,
                    locale: viewModel.dateFormatter.locale
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

    private func handleReset() {
        hapticFeedbackProvider.selectionChanged()
        viewModel.clearDatesCache()
        viewModel.updateDays()
        explosionAnimator.restoreUserInteraction(items: collectionView.visibleCells, in: collectionView)
        explosionAnimator.resetTapCount()
        render(animated: false)
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
        setupWeekdayHeader()
        view.addSubview(collectionView)
        setupButtons()
        setupLayout()
    }

    private func setupMonthLabel() {
        let descriptor = UIFont.preferredFont(forTextStyle: .title3).fontDescriptor
            .withSymbolicTraits(.traitBold) ?? UIFont.preferredFont(forTextStyle: .title3).fontDescriptor
        monthLabel.font = UIFont(descriptor: descriptor, size: 0)
        monthLabel.adjustsFontForContentSizeCategory = true
        monthLabel.numberOfLines = 0
        monthLabel.textAlignment = .center
        monthLabel.textColor = .label
        view.addSubview(monthLabel)
    }

    private func setupWeekdayHeader() {
        weekdayStackView.axis = .horizontal
        weekdayStackView.alignment = .fill
        weekdayStackView.distribution = .fillEqually
        weekdayStackView.spacing = 0
        weekdayStackView.accessibilityIdentifier = "calendarWeekdayHeader"
        view.addSubview(weekdayStackView)

        let symbols = viewModel.calendar.shortWeekdaySymbols
        guard symbols.count == 7 else { return }

        let firstWeekdayIndex = (viewModel.calendar.firstWeekday - 1 + symbols.count) % symbols.count
        for offset in 0..<symbols.count {
            let label = UILabel()
            label.text = symbols[(firstWeekdayIndex + offset) % symbols.count]
            label.font = .preferredFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.75
            label.accessibilityIdentifier = "calendarWeekday_\(offset)"
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            weekdayStackView.addArrangedSubview(label)
        }
    }

    private func setupButtons() {
        clearButton.setTitle(
            CalendarStrings.localized(.clearDates, locale: viewModel.dateFormatter.locale),
            for: .normal
        )
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        clearButton.titleLabel?.adjustsFontForContentSizeCategory = true
        clearButton.accessibilityIdentifier = "calendarClearButton"

        resetButton.setTitle(
            CalendarStrings.localized(.restore, locale: viewModel.dateFormatter.locale),
            for: .normal
        )
        resetButton.accessibilityIdentifier = "calendarRestoreButton"
        resetButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        resetButton.layer.cornerRadius = 8
        resetButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        resetButton.titleLabel?.adjustsFontForContentSizeCategory = true

        buttonsStackView.axis = .vertical
        buttonsStackView.alignment = .fill
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = Constants.layoutSpacing
        buttonsStackView.addArrangedSubview(clearButton)
        buttonsStackView.addArrangedSubview(resetButton)
        view.addSubview(buttonsStackView)
    }

    private func setupLayout() {
        [monthLabel, weekdayStackView, collectionView, buttonsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        collectionView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.layoutSpacing),
            monthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalMargin),
            monthLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalMargin),

            weekdayStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: Constants.layoutSpacing),
            weekdayStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weekdayStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            weekdayStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.weekdayHeaderHeight),

            collectionView.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor, constant: -Constants.layoutSpacing),

            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.horizontalMargin),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.horizontalMargin),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.layoutSpacing),
            clearButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minimumButtonHeight),
            resetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minimumButtonHeight)
        ])
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

        do {
            try viewModel.select(date)
        } catch {
            Logger.error("Failed to select date: \(error.localizedDescription)", category: .storage)
            render()
            return
        }
        updateMonthLabel()
        applySnapshot()
    }
}
