//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct ValidURL: Validating {
		public func hasProblem(_ str: String) -> String? {
			return (URL(string: str) == nil) ? "Unable to make valid URL" : nil
		}
	}

	
}
