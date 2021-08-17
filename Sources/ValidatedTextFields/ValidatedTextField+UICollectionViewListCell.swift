//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


@available(iOS 14.0, *)
extension UICollectionViewListCell {
	
	@discardableResult
	func inputGetter(configurer: ((UITextField)->Void)? = nil, validator: TextFieldValidator? = nil, completion: @escaping (String?)->Void) -> UIButton {
		let button = buttonOnCell()
		
		// skip if it's read only (FUTURE: Maybe we could make some visible "Can't-edit-this" animation
		if let ro = validator?.readonly, ro == true {
			return button
		}
		
		if let fixedValues = validator?.listOfValues {
			let actions = fixedValues.map { value in
				UIAction(title: value) { _ in
					completion(value)
				}
			}
			button.menu = UIMenu(children: actions)
			return button
		}
		
		let action = UIAction(title: "input", image: nil, identifier: .init("input"), discoverabilityTitle: "input") { [weak self] action in
			guard let self = self else { return }
			let textField = UITextField(frame: .zero)
			configurer?(textField)
			self.contentView.addSubview(textField)
			textField.translatesAutoresizingMaskIntoConstraints = false
			textField.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor).isActive = true
			textField.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
			textField.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor).isActive = true
			textField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
			textField.textAlignment = .right
			var config = self.contentConfiguration as! UIListContentConfiguration
			textField.text = config.secondaryText
			textField.placeholder = config.text
			textField.font = config.secondaryTextProperties.font
			let originalValue = config.secondaryText
			config.secondaryText = nil
			self.contentConfiguration = config
			
			let theValidator = validator ?? TextFieldValidator()
			textField.addValidator(theValidator)
			
			// call this before we add the onFinish (cause another could need to finish still)
			textField.becomeFirstResponder()
			
			theValidator.onFinish = { string in
				textField.delegate = nil
				textField.endEditing(true)
				textField.removeFromSuperview()
				config.secondaryText = originalValue	// put the original back in. if the delegate wants to change it it can
				self.contentConfiguration = config
				completion(string)
				theValidator.onFinish = nil
			}
			
			
		}
		button.addAction(action, for: .touchDown)
		return button
	}
	
	func buttonOnCell() -> UIButton {
		let kTag = 2304234
		if let btn = self.contentView.viewWithTag(kTag) as? UIButton {
			btn.removeTarget(nil, action: nil, for: .allEvents)
			btn.menu = nil
			return btn
		}
		let btn = UIButton()
		btn.translatesAutoresizingMaskIntoConstraints = false
		btn.tag = kTag
		btn.layer.zPosition = 999
		self.contentView.addSubview(btn)
		btn.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
		btn.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
		btn.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
		btn.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
		btn.showsMenuAsPrimaryAction = true
		return btn
	}
	
}

