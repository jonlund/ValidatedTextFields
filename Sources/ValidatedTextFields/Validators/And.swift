//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


public extension Validator {

	struct And: Validating, InputResponder {
		var validators: [Validating]
		public func hasProblem(_ str: String) -> String? {
			let problems = validators.compactMap { $0.hasProblem(str) }
			guard problems.count > 0 else { return nil }
			return problems.compactMap({ $0 }).joined(separator: "\n")
		}
		public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
			for v in validators {
				if let v = v as? InputResponder {
					let should = v.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
					if should == false { return false }
				}
			}
			return true
		}
		/// stops if any think we should (and all are valid?)
		public func shouldStopWithValue(_ value: String) -> Bool {
			let irs = validators.compactMap { $0 as? InputResponder }
			for r  in irs {
				if r.shouldStopWithValue(value) { return true }
			}
			return false
		}
	}

	
}
