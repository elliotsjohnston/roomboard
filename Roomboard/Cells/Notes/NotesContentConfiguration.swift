//
//  NotesContentConfiguration.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/24/22.
//

import UIKit

struct NotesContentConfiguration: UIContentConfiguration {
    func makeContentView() -> UIView & UIContentView {
        return NotesContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> NotesContentConfiguration {
        return self
    }
    
    var text = ""
    var notesUpdateHandler: ((String) -> Void)?
    var textViewSelectionHandler: (() -> Void)?
}
