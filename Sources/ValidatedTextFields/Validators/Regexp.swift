//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct Regexp: Validating {
		let pattern: String
		
		public func hasProblem(_ str: String) -> String? {
			if let _ = str.range(of: pattern, options: .regularExpression) { return nil }
			return "is invalid"
		}
	}

	
}
