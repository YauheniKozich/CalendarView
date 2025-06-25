//
//  CalendarViewModel.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 14.06.25.
//

import UIKit
import Combine

final class CalendarViewController: UIViewController {
    private enum Section {
        case main
    }

    var collectionView: UICollectionView!
    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, CalendarDay> = {
        return UICollectionViewDiffableDataSource<Section, CalendarDay>(collectionView: collectionView) { [weak self] collectionView, indexPath, calendarDay in
            guard let self = self else { return UICollectionViewCell() }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CalendarCell else {
                return UICollectionViewCell()
            }
            if let date = calendarDay.date {
                cell.configure(
                    with: date,
                    isSelected: self.viewModel.isDateSelected(date),
                    isInRange: self.viewModel.isDateInRange(date),
                    isPlaceholder: false
                )
                cell.isUserInteractionEnabled = date >= self.viewModel.today
                cell.isAccessibilityElement = true
                cell.accessibilityLabel = self.accessibilityDateFormatter.string(from: date)
            } else {
                cell.configure(with: nil, isSelected: false, isInRange: false, isPlaceholder: true)
                cell.isUserInteractionEnabled = false
                cell.isAccessibilityElement = false
            }
            return cell
        }
    }()
    private let viewModel: any CalendarViewModelProtocol
    private let explosionAnimator: CalendarExplosionAnimator
    private var tapCount = 0
    private var cancellables = Set<AnyCancellable>()

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

    init(viewModel: any CalendarViewModelProtocol, explosionAnimator: CalendarExplosionAnimator, gestureCoordinator: GestureCoordinator) {
        self.viewModel = viewModel
        self.explosionAnimator = explosionAnimator
        self.gestureCoordinator = gestureCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
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
            .sink { [weak self] in
                guard let self = self else { return }
                self.explosionAnimator.restoreUserInteraction(collectionView: self.collectionView, in: self.view)
                self.applySnapshot(animatingDifferences: false)
                self.viewModel.updateDays()
                self.updateMonthLabel()
            }
            .store(in: &cancellables)

        viewModel.updateDays()
        updateMonthLabel()
    }

    func setGestureCoordinator(_ coordinator: GestureCoordinator) {
        self.gestureCoordinator = coordinator
        coordinator.setupGestures()

        coordinator.gestureEventPublisher
            .sink { [weak self] event in
                self?.handleGesture(event)
            }
            .store(in: &cancellables)
    }

    private func handleGesture(_ event: GestureEvent) {
        switch event.kind {
        case .doubleTap:
            explosionAnimator.registerTap(on: collectionView, in: view)
        case .swipeLeft:
            handleSwipeReactive(withDirection: .left)
        case .swipeRight:
            handleSwipeReactive(withDirection: .right)
        case .singleTap:
            break
        }
    }

    override func viewDidLayoutSubviews() {
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
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
    }

    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, CalendarDay>()
        snapshot.appendSections([.main])
        let items = viewModel.makeCalendarDays()
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
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

    private func handleSwipeReactive(withDirection direction: UISwipeGestureRecognizer.Direction) {
        isUpdatingSubject
            .first(where: { !$0 })
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isUpdatingSubject.send(true)

                let delta = (direction == .left) ? 1 : -1

                UIView.transition(with: self.collectionView, duration: 0.3, options: [.transitionCrossDissolve]) {
                    self.viewModel.changeMonth(by: delta)
                    self.updateMonthLabel()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isUpdatingSubject.send(false)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    private func destroyCalendar() {
        explosionAnimator.explode(cells: collectionView.visibleCells, in: view)
        collectionView.isUserInteractionEnabled = false
    }

    private func updateMonthLabel() {
        monthLabel.text = viewModel.monthFormatter.string(from: viewModel.currentMonth).capitalized
    }
}

extension CalendarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let calendarDay = dataSource.itemIdentifier(for: indexPath),
              let date = calendarDay.date,
              date >= viewModel.today else {
            return
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        
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
