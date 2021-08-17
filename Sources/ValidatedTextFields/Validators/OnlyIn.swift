//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct OnlyIn: Validating, InputResponder, ValidationPreprocessing {
		let chars: String
		static var numbers: OnlyIn {
			return .init(chars: "1234567890")
		}
		public func hasProblem(_ str: String) -> String? {
			let notAllowed = str.filter{ chars.contains($0) == false }
			if notAllowed.count > 0 {
				return "invalid character(s): `\(notAllowed)`"
			}
			return nil
		}
		public func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {
			guard hasProblem(updated) == nil else { return false }
			return true
		}
		public func process(_ markedUp: String) -> String {
			return String( markedUp.filter({chars.contains($0)}))
		}
		public func unprocess(_ stored: String) -> String {
			return stored
		}
	}

	
}
