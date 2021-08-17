//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import Foundation


public extension Validator {

	struct Email: Validating, RegexpValidator {
		let regexp = Regexp(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z0-9](?:[a-zA-Z0-9-\\.]{0,61}[a-zA-Z0-9])?$")
	}

	
}
