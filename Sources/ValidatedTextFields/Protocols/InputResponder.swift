//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


/// makes decisions on what to do when someone types or pastes things
public protocol InputResponder {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	
	/// should they be allowed to add to a textfield resulting in `updated`
	func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool
	
	/// should end user input
	func shouldStopWithValue(_ value: String) -> Bool
	
	/// optionally tweak value after user adds text
	func replacementForAfterAdd(_ value: String) -> String?
	
	/// optionally tweak value after user removes text
	func replacementForAfterDel(_ value: String) -> String?
}

public extension InputResponder {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let adding = string.count > 0
		let should: Bool
		let updatedText: String
		
		// existing text (includes backspacing)
		if let text = textField.text,
		   let textRange = Range(range, in: text) {
			updatedText = text.replacingCharacters(in: textRange, with: string)
			if !adding {
				if let tweaked = replacementForAfterDel(updatedText) {
					textField.text = tweaked
					(textField.delegate as? TextFieldValidator)?.textFieldChangedByRemoving(textField)
					return false
				}
				return true // no replacement
			}
			should = shouldAllowUpdateTo(updatedText, added: string)
		}
		else {
			assert(string.count != 0, "I thought there was no backspacing possible here")
			should = shouldAllowUpdateTo(string, added: string)
			updatedText = string
		}
		if should,
		   let tweaked = replacementForAfterAdd(updatedText) {
			textField.text = tweaked
			assert(adding)
			(textField.delegate as? TextFieldValidator)?.textFieldChangedByAdding(textField)
			return false
		}
		return should
	}
	
	func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {	// default to true
		return true
	}
	
	func shouldStopWithValue(_ value: String) -> Bool {		// default to false
		return false
	}
	
	func replacementForAfterAdd(_ value: String) -> String? {
		return nil
	}
	
	func replacementForAfterDel(_ value: String) -> String? {
		return nil
	}
}
