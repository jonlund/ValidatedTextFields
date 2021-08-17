//
//  File.swift
//  
//
//  Created by Jon Lund on 8/16/21.
//

import UIKit


/// A collection of settings and validators for configuring and validating a textfield
public struct ValidationBundle {
	public var validators = [Validating]()
	public var keyboardType: UIKeyboardType?
	public var suffix: String?
	public var prefix: String?
	public var alignment: NSTextAlignment?
	public var placeholder: String?
	public var preselect: Bool?
	public var capitalizationType: UITextAutocapitalizationType?
	
	public init() {}
	
	public static var percent: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.Decimal(decimalPlaces: 3),
			Validator.OnlyIn(chars: "1234567890.")
		]
		bundle.keyboardType = .numberPad
		bundle.suffix = "%"
		bundle.alignment = .right
		bundle.preselect = true
		return bundle
	}
	
	public static var hexColor: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.OnlyIn(chars: "01234567ABCDEF"),
			Validator.Length(exact: 8)
		]
		bundle.keyboardType = .asciiCapable
		bundle.preselect = true
		bundle.capitalizationType = .allCharacters
		return bundle
	}
	
	public static var integerPercent: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.ComparableValue(greaterThan: -1, lessThan: 101),
			Validator.OnlyIn.numbers,
			Validator.Length(min: 1, max: 2)
		]
		bundle.keyboardType = .numberPad
		bundle.suffix = "%"
		bundle.alignment = .right
		return bundle
	}
	
	
	public static func integerWithin(min: Int?=nil, max: Int?=nil) -> ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.OnlyIn(chars: "1234567890"),
		]
		switch (min,max) {
		case (.some(let n),.some(let x)): 	bundle.validators.append(Validator.ComparableValue(greaterThan: n-1, lessThan: x+1))
		case (.some(let n),_): 				bundle.validators.append(Validator.ComparableValue(greaterThan: n-1))
		case (_,.some(let x)): 				bundle.validators.append(Validator.ComparableValue(lessThan: x+1))
		default: ()
		}
		bundle.keyboardType = .numberPad
		bundle.alignment = .right
		bundle.preselect = true
		return bundle
	}
	
	public static var email: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.keyboardType = .emailAddress
		bundle.validators = [
			Validator.Email()
		]
		return bundle
	}
	
	public static var title: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.keyboardType = .default
		bundle.capitalizationType = .words
		return bundle
	}
	
	public static var date: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.NumericTemplate(template: "dd/dd/dd")
		]
		bundle.keyboardType = .numberPad
		bundle.placeholder = "dd/dd/dd"
		return bundle
	}
	
	public static var url: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.keyboardType = .URL
		bundle.validators = [ Validator.ValidURL() ]
		return bundle
	}
	
	public static var phone: ValidationBundle {
		var bundle = ValidationBundle()
		bundle.validators = [
			Validator.NumericTemplate(template: "ddd-ddd-dddd")
		]
		bundle.keyboardType = .numberPad
		return bundle
	}
}
