//
//  File.swift
//  CalendarView
//
//  Created by Yauheni Kozich on 13.05.25.
//

import UIKit

final class CalendarCell: UICollectionViewCell {
    private let label = UILabel()
    private let calendar = Calendar.current

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
        setupContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with date: Date?, isSelected: Bool, isInRange: Bool, isPlaceholder: Bool) {
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
        label.frame = contentView.bounds
        contentView.addSubview(label)
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
        contentView.layer.borderColor = isInRange ? UIColor.systemBlue.cgColor : nil
        isUserInteractionEnabled = true
    }

    private func setBackground(for weekday: Int, isSelected: Bool, isInRange: Bool) {
        if isSelected {
            contentView.backgroundColor = .systemBlue
        } else if isInRange {
            contentView.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        } else if weekday == 1 {
            contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        } else if weekday == 7 {
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        } else {
            contentView.backgroundColor = .gray.withAlphaComponent(0.1)
        }
    }

    private func setTextColor(isSelected: Bool, isInRange: Bool) {
        label.textColor = isSelected ? .white : .black
    }
}
