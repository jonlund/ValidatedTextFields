//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct Length: Validating, InputResponder {
		let min: Int?
		let max: Int?
		init(min: Int) {
			self.min = min
			max = nil
		}
		init(min: Int, max: Int) {
			self.min = min
			self.max = max
		}
		init(max: Int) {
			self.min = nil
			self.max = max
		}
		init(exact: Int) {
			self.min = exact
			self.max = exact
		}
		public func hasProblem(_ str: String) -> String? {
			let n = str.count
			switch (min,max) {
			case (.some(let x),.none): return (n >= x) ? nil : "too short"
			case (.none,.some(let x)): return (n <= x) ? nil : "too long"
			case (.some(let x), .some(let y)):
				if n < x { return "too short" }
				if n > y { return "too long" }
			default:
				assert(false,"Shouldn't happen. ever.")
				()
			}
			return nil
		}
		public func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {
			if let max = max, updated.count > max { return false }
			return true
		}
		public func shouldStopWithValue(_ value: String) -> Bool {
			if let max = max,
			   value.count == max {
				return true
			}
			return false
		}
	}

	
}
