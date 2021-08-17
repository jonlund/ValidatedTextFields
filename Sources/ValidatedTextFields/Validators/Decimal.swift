//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	
	struct Decimal: Validating, InputResponder {
		let decimalPlaces: Int
		var numberFormatter: NumberFormatter
		let allowedDigits = "1234567890."
		
		public init(decimalPlaces _dp: Int) {
			decimalPlaces = _dp
			numberFormatter = NumberFormatter()
			numberFormatter.minimumIntegerDigits = 1
			numberFormatter.alwaysShowsDecimalSeparator = true
			numberFormatter.minimumFractionDigits = _dp
			numberFormatter.maximumFractionDigits = _dp
		}
		
		public func hasProblem(_ str: String) -> String? {
			let noSymbol = str.filter { allowedDigits.contains($0)}
			guard let _ = Float(noSymbol) else { return "Invalid amount" }
			return nil
		}
		
		public func replacementForAfterAdd(_ value: String) -> String? {
			let digits = value.filter { "1234567890".contains($0)}
			guard let fltVal = Float(digits) else { return nil }
			let divisor: Float = pow(10.0, Float(decimalPlaces))
			let decimalValue = fltVal / divisor
			return numberFormatter.string(for: decimalValue)
		}
	}
	
	
}
