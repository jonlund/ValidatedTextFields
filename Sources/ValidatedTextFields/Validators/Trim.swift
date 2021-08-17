//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {
	
	struct Trim: Validating, ValidationPreprocessing {
		public func hasProblem(_ str: String) -> String? {
			return nil
		}
		
		public func process(_ markedUp: String) -> String {
			return markedUp.trimmingCharacters(in: .whitespaces)
		}
		
		public func unprocess(_ stored: String) -> String {
			return stored.trimmingCharacters(in: .whitespaces)
		}
	}
	
}
