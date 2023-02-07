//
//  DatePickerContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/20/22.
//

import UIKit

struct DatePickerContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return DatePickerContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> DatePickerContentConfiguration {
        return self
    }
    
    var date = Date.now
    var dateUpdateHandler: ((Date) -> Void)?
}
