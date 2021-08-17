//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


@available(iOS 14.0, *)
public extension UITableViewCell {
	
	/// for table cells, 1) cover with button. 2) user taps 3) validated TF placed on cell & activated 4) when finished, value gathered and placed back in cell
	func inputGetter(configurer: ((UITextField)->Void)? = nil, validator: TextFieldValidator? = nil, completion: @escaping (String?)->Void) {
		let button = buttonOnCell()
		
		// skip if it's read only (FUTURE: Maybe we could make some visible "Can't-edit-this" animation
		if let ro = validator?.readonly, ro == true {
			return
		}
		
		if let fixedValues = validator?.listOfValues {
			let actions = fixedValues.map { value in
				UIAction(title: value) { _ in
					completion(value)
				}
			}
			button.menu = UIMenu(children: actions)
			return
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
			textField.text = self.detailTextLabel?.text
			textField.placeholder = self.textLabel?.text
			if let f = self.detailTextLabel?.font {
				textField.font = f
			}
			//self.textLabel?.isHidden = true
			self.detailTextLabel?.isHidden = true
			
			let validator = validator ?? TextFieldValidator()
			textField.addValidator(validator)
			
			
			
			validator.onFinish = { string in
				textField.removeFromSuperview()
				//self.textLabel?.isHidden = false
				self.detailTextLabel?.isHidden = false
				self.detailTextLabel?.text = string
				completion(string)
				validator.onFinish = nil
			}
			
			textField.becomeFirstResponder()
		}
		button.addAction(action, for: .touchDown)
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

