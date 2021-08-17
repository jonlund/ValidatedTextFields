//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct ComparableValue<T: Comparable & LosslessStringConvertible>: Validating {
		private let min: T?
		private let max: T?
		init(greaterThan: T) {
			self.min = greaterThan
			max = nil
		}
		init(greaterThan: T, lessThan: T) {
			self.min = greaterThan
			self.max = lessThan
		}
		init(lessThan: T) {
			self.min = nil
			self.max = lessThan
		}
		init(equalTo: T) {
			self.min = equalTo
			self.max = equalTo
		}
		public func hasProblem(_ str: String) -> String? {
			guard let n = T(str) else {
				return "cannot interpret `\(str)` as comparable value"
			}
			switch (min,max) {
			case (.some(let x),.none): return (n >= x) ? nil : "too small"
			case (.none,.some(let x)): return (n <= x) ? nil : "too big"
			case (.some(let x), .some(let y)):
				if n < x { return "too small" }
				if n > y { return "too big" }
			default:
				assert(false,"Shouldn't happen. ever.")
				()
			}
			return nil
		}
	}

	
}
