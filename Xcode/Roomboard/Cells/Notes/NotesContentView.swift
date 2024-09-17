//
//  NotesContentView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/24/22.
//

import UIKit

class NotesContentView: UIView, UIContentView, UITextViewDelegate {
    
    var configuration: UIContentConfiguration {
        didSet {
            guard let configuration = configuration as? NotesContentConfiguration else { return }
            apply(configuration)
        }
    }
    
    private var notesUpdateHandler: ((String) -> Void)?
    
    private var textViewSelectionHandler: (() -> Void)?
    
    private lazy var notesView: UITextView = {
        let notesView = UITextView()
        notesView.textAlignment = .left
        notesView.textContainer.lineFragmentPadding = 0.0
        notesView.textContainerInset = .zero
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.backgroundColor = nil
        notesView.attributedPlaceholder = NSAttributedString("Notes")
        notesView.translatesAutoresizingMaskIntoConstraints = false
        notesView.delegate = self
        return notesView
    }()
    
    init(configuration: NotesContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        apply(configuration)
        sharedNotesContentViewInitialization()
    }
    
    required init?(coder: NSCoder) {
        let configuration = NotesContentConfiguration()
        self.configuration = configuration
        super.init(coder: coder)
        sharedNotesContentViewInitialization()
        apply(configuration)
    }
    
    private func sharedNotesContentViewInitialization() {
        addSubview(notesView)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12.0, leading: 20.0, bottom: 12.0, trailing: 20.0)
        NSLayoutConstraint.activate([
            notesView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            notesView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            notesView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            notesView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 125.0)
        ])
    }
    
    private func apply(_ configuration: NotesContentConfiguration) {
        notesView.text = configuration.text
        self.notesUpdateHandler = configuration.notesUpdateHandler
        self.textViewSelectionHandler = configuration.textViewSelectionHandler
    }
    
    func textViewDidChange(_ textView: UITextView) {
        notesUpdateHandler?(textView.text)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textViewSelectionHandler?()
    }
    
}

extension UITextView {
    var attributedPlaceholder: NSAttributedString? {
        get {
            return perform(NSSelectorFromString("attributedPlaceholder"))?.takeUnretainedValue() as? NSAttributedString
        }
        
        set {
            perform(NSSelectorFromString("setAttributedPlaceholder:"), with: newValue)
        }
    }
}
