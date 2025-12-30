//
//  CalendarCell.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 13.05.25.
//

import UIKit

final class CalendarCell: UICollectionViewCell {
    private let label = UILabel()
    
    private enum Colors {
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

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        label.textColor = .black
        contentView.backgroundColor = .white
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil
        isUserInteractionEnabled = true

        // Reset accessibility state
        isAccessibilityElement = false
        accessibilityLabel = nil
        accessibilityHint = nil
        accessibilityTraits = []
    }

    func configure(with date: Date?, isSelected: Bool, isInRange: Bool, isPlaceholder: Bool, calendar: CalendarProvider) {
        if isPlaceholder || date == nil {
            configurePlaceholder()
        } else {
            configureDateAppearance(date: date!, isSelected: isSelected, isInRange: isInRange, calendar: calendar)
        }
    }

    private func setupLabel() {
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .black
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func setupContentView() {
        contentView.layer.cornerRadius = 10
        contentView.backgroundColor = .white
    }

    private func configurePlaceholder() {
        label.text = ""
        label.textColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil

        isAccessibilityElement = false
        accessibilityLabel = nil
        accessibilityHint = nil
        accessibilityTraits = []
    }

    private func configureDateAppearance(date: Date, isSelected: Bool, isInRange: Bool, calendar: CalendarProvider) {
        let day = calendar.component(.day, from: date)
        label.text = "\(day)"

        let isWeekend = calendar.isDateInWeekend(date)
        setBackground(isWeekend: isWeekend, isSelected: isSelected, isInRange: isInRange)
        setTextColor(isSelected: isSelected, isInRange: isInRange)

        contentView.layer.borderWidth = isInRange ? 2 : 0
        contentView.layer.borderColor = isInRange ? Colors.rangeBorder.cgColor : nil
    }

    private func setBackground(isWeekend: Bool, isSelected: Bool, isInRange: Bool) {
        if isSelected {
            contentView.backgroundColor = Colors.selectedBackground
        } else if isInRange {
            contentView.backgroundColor = Colors.rangeBackground
        } else if isWeekend {
            contentView.backgroundColor = Colors.weekendBackground
        } else {
            contentView.backgroundColor = Colors.weekdayBackground
        }
    }

    private func setTextColor(isSelected: Bool, isInRange: Bool) {
        label.textColor = (isSelected || isInRange) ? .white : .black
    }
}
