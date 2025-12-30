//
//  CalendarCell.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 13.05.25.
//

import UIKit

public final class CalendarCell: UICollectionViewCell {
    private let label = UILabel()
    private var calendar: CalendarProvider = CalendarProviderImpl()
    
    private enum Colors: Sendable {
        static let weekendBackground = UIColor.systemGray.withAlphaComponent(0.15)
        static let weekdayBackground = UIColor.gray.withAlphaComponent(0.05)
        static let selectedBackground = UIColor.systemBlue
        static let rangeBackground = UIColor.systemBlue.withAlphaComponent(0.2)
        static let rangeBorder = UIColor.systemBlue
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        setupContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with date: Date?, isSelected: Bool, isInRange: Bool, isPlaceholder: Bool, calendar: CalendarProvider) {
        self.calendar = calendar
        if isPlaceholder {
            configurePlaceholder()
        } else {
            configureDateAppearance(date: date ?? Date(), isSelected: isSelected, isInRange: isInRange)
        }
    }

    private func setupLabel() {
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func setupContentView() {
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
    }

    private func configurePlaceholder() {
        label.text = ""
        label.textColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil
        isUserInteractionEnabled = false
    }

    private func configureDateAppearance(date: Date, isSelected: Bool, isInRange: Bool) {
        let day = calendar.component(.day, from: date)
        label.text = "\(day)"

        let weekday = calendar.component(.weekday, from: date)
        setBackground(for: weekday, isSelected: isSelected, isInRange: isInRange)
        setTextColor(isSelected: isSelected, isInRange: isInRange)

        contentView.layer.borderWidth = isInRange ? 2 : 0
        contentView.layer.borderColor = isInRange ? Colors.rangeBorder.cgColor : nil
        isUserInteractionEnabled = true
    }

    private func setBackground(for weekday: Int, isSelected: Bool, isInRange: Bool) {
        if isSelected {
            contentView.backgroundColor = Colors.selectedBackground
        } else if isInRange {
            contentView.backgroundColor = Colors.rangeBackground
        } else if weekday == 1 || weekday == 7 {
            contentView.backgroundColor = Colors.weekendBackground
        } else {
            contentView.backgroundColor = Colors.weekdayBackground
        }
    }

    private func setTextColor(isSelected: Bool, isInRange: Bool) {
        label.textColor = isSelected ? .white : .black
    }
}
