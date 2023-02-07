//
//  DatePickerContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/20/22.
//

import UIKit

class DatePickerContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? DatePickerContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    private var dateUpdateHandler: ((Date) -> Void)?
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged), for: UIControl.Event.valueChanged)
        return datePicker
    }()
    
    private lazy var listContent: UIListContentView = {
        var config = UIListContentConfiguration.cell()
        config.text = "Date"
        let listContent = UIListContentView(configuration: config)
        return listContent
    }()
    
    private lazy var contentStack: UIStackView = {
        let contentStack = UIStackView(arrangedSubviews: [listContent, datePicker])
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins.trailing = 16.0
        contentStack.directionalLayoutMargins.leading = 4.0
        contentStack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return contentStack
    }()
    
    init(configuration: UIContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        sharedDatePickerContentViewInitialization()
    }
    
    required init?(coder: NSCoder) {
        self.configuration = DatePickerContentConfiguration()
        super.init(coder: coder)
        sharedDatePickerContentViewInitialization()
    }
    
    private func sharedDatePickerContentViewInitialization() {
        addSubview(contentStack)
    }
    
    private func apply(_ configuration: DatePickerContentConfiguration) {
        datePicker.date = configuration.date
        dateUpdateHandler = configuration.dateUpdateHandler
    }
    
    @objc
    private func dateChanged(_ sender: UIDatePicker) {
        dateUpdateHandler?(sender.date)
    }
    
}
