//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct FormattedNumber: Validating, InputResponder {
		var formatter: NumberFormatter
		
		public func hasProblem(_ str: String) -> String? {
			if formatter.number(from: str) == nil {
				return "cannot make anumber for \(str)"
			}
			return nil
		}
		
		public func replacementForAfterAdd(_ value: String) -> String? {
			//let digits = value.filter{ "1234567890".contains($0)}
			let number = formatter.number(from: value) ?? 0
			return formatter.string(from: number)
		}
	}
	
}
