//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct NumericTemplate: Validating, ValidationPreprocessing, InputResponder {	// "\d\d--\d\d--\d\d"   "(ddd) ddd-dddd"  "ddd-dd-dddd"  "$ d,ddd"
		let template: String
		
		public func hasProblem(_ str: String) -> String? {
			let justNumbers = str.filter{ "1234567890".contains($0) }
			let justDs = template.filter{ "d".contains($0) }
			switch (justDs.count, justNumbers.count) {
			case (let x, let y) where x == y: 		return nil
			case (let x, let y) where x < y:		return "too many digits"
			case (let x, let y) where x > y:		return "incomplete"
			default:
				return nil
			}
		}
		
		public func process(_ markedUp: String) -> String {
			let onlyNumbers = markedUp.filter { "1234567890".contains($0) }
			return String(onlyNumbers)
		}
		
		public func unprocess(_ stored: String) -> String {
			return fillinTemplate(stored)
		}
		
		public func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {
			guard updated.count <= template.count else { return false }
			return added.filter({ "1234567890".contains($0) == false }).isEmpty
		}
		
		public func fillinTemplate(_ value: String, greedy: Bool = true) -> String {
			var onlyNums = value.filter {"1234567890".contains($0) }
			var newStr = ""
			for char in template {
				if char == "d" {
					guard onlyNums.count > 0 else { return newStr }
					let num = onlyNums.removeFirst()
					newStr.append(num)
				}
				else {
					if greedy == false {
						guard onlyNums.count > 0 else { return newStr }
					}
					newStr.append(char)
				}
			}
			return newStr
		}
		
		public func replacementForAfterAdd(_ value: String) -> String? {
			return fillinTemplate(value)
		}
		
		public func replacementForAfterDel(_ value: String) -> String? {			// build a minimal string from the template
			return fillinTemplate(value, greedy: false)
		}
		
		public func shouldStopWithValue(_ value: String) -> Bool {
			return value.count == template.count && hasProblem(value) == nil
		}
	}

	
}
