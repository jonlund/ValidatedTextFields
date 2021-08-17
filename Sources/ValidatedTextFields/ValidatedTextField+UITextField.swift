//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


public extension UITextField {
	
	func addValidator(_ validator: TextFieldValidator) {
		validator.originalDelegate = self.delegate ?? validator.originalDelegate
		self.delegate = validator
		validator.apply(self)
	}
}
