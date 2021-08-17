//
//  ValidatedTextfield.swift
//  The Wash
//
//  Created by Jon Lund on 10/22/20.
//  Copyright © 2020 Mana Mobile, LLC. All rights reserved.
//

import UIKit


/*

Desired usage:

let tf = ValidatedTextField()
tf.template = Template("XXX-XXX-XXXX")
tf.validators = [.email,.nonblank]
tf.whenInvalid = .force(jiggle)
tf.whenInvalid = .warn
tf.whenInvalid = .chickenSwitch("You might have problems")
tf.whenInvalid = .ignore
tf.whenValid = .resign
tf.whenValid = .callback(()->Error?)


tf.validators = [.regexp(".*")]


// get a percentage
tf.template = Template("x %")		// x is many
tf.validators = [.between(-1,101)]
tf.whenInvalid = [.revert]

*/


public extension UITextField {
	
	func addValidator(_ validator: TextFieldValidator) {
		validator.originalDelegate = self.delegate ?? validator.originalDelegate
		self.delegate = validator
		validator.apply(self)
	}
}


/// makes decisions on what to do when someone types or pastes things
public protocol InputResponder {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	
	/// should they be allowed to add to a textfield resulting in `updated`
	func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool
	
	/// should end user input
	func shouldStopWithValue(_ value: String) -> Bool
	
	/// optionally tweak value after user adds text
	func replacementForAfterAdd(_ value: String) -> String?
	
	/// optionally tweak value after user removes text
	func replacementForAfterDel(_ value: String) -> String?
}

public extension InputResponder {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let adding = string.count > 0
		let should: Bool
		let updatedText: String
		
		// existing text (includes backspacing)
		if let text = textField.text,
		   let textRange = Range(range, in: text) {
			updatedText = text.replacingCharacters(in: textRange, with: string)
			if !adding {
				if let tweaked = replacementForAfterDel(updatedText) {
					textField.text = tweaked
					(textField.delegate as? TextFieldValidator)?.textFieldChangedByRemoving(textField)
					return false
				}
				return true // no replacement
			}
			should = shouldAllowUpdateTo(updatedText, added: string)
		}
		else {
			assert(string.count != 0, "I thought there was no backspacing possible here")
			should = shouldAllowUpdateTo(string, added: string)
			updatedText = string
		}
		if should,
		   let tweaked = replacementForAfterAdd(updatedText) {
			textField.text = tweaked
			assert(adding)
			(textField.delegate as? TextFieldValidator)?.textFieldChangedByAdding(textField)
			return false
		}
		return should
	}
	
	func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {	// default to true
		return true
	}
	
	func shouldStopWithValue(_ value: String) -> Bool {		// default to false
		return false
	}
	
	func replacementForAfterAdd(_ value: String) -> String? {
		return nil
	}
	
	func replacementForAfterDel(_ value: String) -> String? {
		return nil
	}
}

/// something that will validate a chunk of text
public protocol Validating {
	func hasProblem(_ str: String) -> String?
}
extension Validating {
	public func isValid(_ str: String) -> Bool {
		return hasProblem(str) == nil
	}
}

/// a subtype (somewhat) of Validating to provide a default implementation
protocol RegexpValidator {
	var regexp: Validator.Regexp { get }
}
extension RegexpValidator {
	public func hasProblem(_ str: String) -> String? {
		return regexp.hasProblem(str)
	}
}

/// removes markup (like whitespace, symbols ($) and commas before validation and value saving)
public protocol ValidationPreprocessing {
	
	/// remove markup to produce raw value
	func process(_ markedUp: String) -> String
	
	/// add markup from storage to display value
	func unprocess(_ stored: String) -> String
}



public struct Validator {
	
	public struct Trim: Validating, ValidationPreprocessing {
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
	
	public struct Decimal: Validating, InputResponder {
		let decimalPlaces: Int
		var numberFormatter: NumberFormatter
		let allowedDigits = "1234567890."
		
		init(decimalPlaces _dp: Int) {
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
	

	//	struct HexColor: Validating {
	//		func hasProblem(_ str: String) -> String? {
	//			guard str.count == 8 else { return "Invalid number of characters" }
	//			let allowedDigits = "01234567ABCDEF"
	//			let filtered = str.filter { allowedDigits.contains($0)}
	//			guard filtered.count == 8 else { return "Invalid character" }
	//			return nil
	//		}
	//	}
	
	public struct FormattedNumber: Validating, InputResponder {
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
	
	public struct NumericTemplate: Validating, ValidationPreprocessing, InputResponder {	// "\d\d--\d\d--\d\d"   "(ddd) ddd-dddd"  "ddd-dd-dddd"  "$ d,ddd"
		let template: String
		
		public func hasProblem(_ str: String) -> String? {
			let justNumbers = str.filter{ "1234567890".contains($0) }
			let justDs = template.filter{ "d".contains($0) }
			switch (justDs.count, justNumbers.count) {
			case (let x, let y) where x == y: 		return nil
			case (let x, let y) where x < y:		return "too many digits"
			case (let x, let y) where x > y:		return "incomplete"
			default:
				return nil
			}
		}
		
		public func process(_ markedUp: String) -> String {
			let onlyNumbers = markedUp.filter { "1234567890".contains($0) }
			return String(onlyNumbers)
		}
		
		public func unprocess(_ stored: String) -> String {
			return fillinTemplate(stored)
		}
		
		public func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {
			guard updated.count <= template.count else { return false }
			return added.filter({ "1234567890".contains($0) == false }).isEmpty
		}
		
		public func fillinTemplate(_ value: String, greedy: Bool = true) -> String {
			var onlyNums = value.filter {"1234567890".contains($0) }
			var newStr = ""
			for char in template {
				if char == "d" {
					guard onlyNums.count > 0 else { return newStr }
					let num = onlyNums.removeFirst()
					newStr.append(num)
				}
				else {
					if greedy == false {
						guard onlyNums.count > 0 else { return newStr }
					}
					newStr.append(char)
				}
			}
			return newStr
		}
		
		public func replacementForAfterAdd(_ value: String) -> String? {
			return fillinTemplate(value)
		}
		
		public func replacementForAfterDel(_ value: String) -> String? {			// build a minimal string from the template
			return fillinTemplate(value, greedy: false)
		}
		
		public func shouldStopWithValue(_ value: String) -> Bool {
			return value.count == template.count && hasProblem(value) == nil
		}
	}
	
	public struct Regexp: Validating {
		let pattern: String
		
		public func hasProblem(_ str: String) -> String? {
			if let _ = str.range(of: pattern, options: .regularExpression) { return nil }
			return "is invalid"
		}
	}
	
	
	public struct Email: Validating, RegexpValidator {
		let regexp = Regexp(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z0-9](?:[a-zA-Z0-9-\\.]{0,61}[a-zA-Z0-9])?$")
	}
	
	public struct ValidURL: Validating {
		public func hasProblem(_ str: String) -> String? {
			return (URL(string: str) == nil) ? "Unable to make valid URL" : nil
		}
	}
	
	public struct Length: Validating, InputResponder {
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
	
	public struct And: Validating, InputResponder {
		var validators: [Validating]
		public func hasProblem(_ str: String) -> String? {
			let problems = validators.compactMap { $0.hasProblem(str) }
			guard problems.count > 0 else { return nil }
			return problems.compactMap({ $0 }).joined(separator: "\n")
		}
		public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
			for v in validators {
				if let v = v as? InputResponder {
					let should = v.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
					if should == false { return false }
				}
			}
			return true
		}
		/// stops if any think we should (and all are valid?)
		public func shouldStopWithValue(_ value: String) -> Bool {
			let irs = validators.compactMap { $0 as? InputResponder }
			for r  in irs {
				if r.shouldStopWithValue(value) { return true }
			}
			return false
		}
	}
	
	public struct OnlyIn: Validating, InputResponder, ValidationPreprocessing {
		let chars: String
		static var numbers: OnlyIn {
			return .init(chars: "1234567890")
		}
		public func hasProblem(_ str: String) -> String? {
			let notAllowed = str.filter{ chars.contains($0) == false }
			if notAllowed.count > 0 {
				return "invalid character(s): `\(notAllowed)`"
			}
			return nil
		}
		public func shouldAllowUpdateTo(_ updated: String, added: String) -> Bool {
			guard hasProblem(updated) == nil else { return false }
			return true
		}
		public func process(_ markedUp: String) -> String {
			return String( markedUp.filter({chars.contains($0)}))
		}
		public func unprocess(_ stored: String) -> String {
			return stored
		}
	}
	
	public struct ComparableValue<T: Comparable & LosslessStringConvertible>: Validating {
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

var _readonly: TextFieldValidator?

public class TextFieldValidator: NSObject, UITextFieldDelegate {
	weak var originalDelegate: UITextFieldDelegate?
	
	public var onFinish: ((String?)->Void)?
	
	
	public var bundle: ValidationBundle?
	public var oneOffValidators = [Validating]()
	public var validators: [Validating] {
		var all = oneOffValidators
		if let bv = bundle?.validators { all.append(contentsOf: bv)}
		return all
	}
	public var uiProcessors: [InputResponder] { return validators.compactMap { $0 as? InputResponder } }
	public var dataTransformers: [ValidationPreprocessing] { return validators.compactMap{ $0 as? ValidationPreprocessing } }
	
	public var errorView: UIView?			// view that indicates it is invalid
	public var observers = [NSObjectProtocol]()
	public weak var currentlyEditing: UITextField? = nil
	public var currentTranslation: (textField: UITextField, translated: UIView)?
	public var delayingKeboardWillShowNotification: Notification?
	public var listOfValues: [String]?
	public let readonly: Bool
	public var rfid: Bool = false
	
	public static var readOnly: TextFieldValidator {
		if _readonly == nil {
			_readonly = TextFieldValidator(readonly: true)
		}
		return _readonly!
	}
	
	public static func options(_ options: [String]) -> TextFieldValidator {
		let v = TextFieldValidator()
		v.listOfValues = options
		return v
	}
	
	public static func rfid(_ values: [String]? = nil) -> TextFieldValidator {
		let v = TextFieldValidator()
		v.listOfValues = values
		v.rfid = true
		return v
	}
	
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
	
	public static func ensuring(_ bundle: ValidationBundle) -> TextFieldValidator {
		let validator = TextFieldValidator()
		validator.bundle = bundle
		return validator
	}
	
	public init(readonly: Bool = false) {
		self.readonly = readonly
		super.init()
		
		if readonly { return }
		
		// Select A, Select B
		// didBegin,
		observers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
			self?.keyboardWillShow(notification)
		})
		
		//		observers.append(NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: .main) { [weak self] notification in
		//			print("Did begin editing")
		//			self?.currentlyEditing = notification.object as? UITextField
		//		})
		//		observers.append(NotificationCenter.default.addObserver(forName: UITextField.textDidEndEditingNotification, object: nil, queue: .main) { [weak self] notification in
		//			print("Did end editing")
		//		})
	}
	
	public convenience init(_ bundle: ValidationBundle) {
		self.init()
		self.bundle = bundle
	}
	
	deinit {
		observers.forEach { NotificationCenter.default.removeObserver($0) }
		print("Deallocd'!")
	}
	
	func keyboardWillShow(_ notification: Notification) {
		guard let textField = currentlyEditing else { return }
		guard textField.delegate === self else { return }
		guard currentTranslation == nil else {						// because this can arrive before a textfield begins editing we'll save it
			delayingKeboardWillShowNotification = notification
			return
		}
		delayingKeboardWillShowNotification = nil					// reset this once we're through
		print("Keyboard will show")
		
		guard let parentToTranslate = textField.parentToTranslate,
			  let window = textField.window,
			  let myParent = textField.superview,
			  let sizeValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
			  let durationValue = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
		else {
			return
		}
		// See if the top of the keyboard is higher (lower value) than my bottom
		let size = sizeValue.cgRectValue
		let duration = durationValue.doubleValue as TimeInterval
		let myRect = myParent.convert(textField.frame, to: window)
		var visibleRect = window.bounds
		visibleRect.size.height -= size.height
		let bottomVisible = visibleRect.maxY
		var bottomOfMe = myRect.maxY
		var transformed = false
		
		// First figure it out taking into account transform
		if parentToTranslate.transform.ty < 0 {
			assert(false)
			bottomOfMe -= parentToTranslate.transform.ty
			transformed = true
		}
		
		if bottomOfMe > bottomVisible - 70 {
			UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState]) {
				parentToTranslate.transform = CGAffineTransform(translationX: 0, y: bottomVisible - bottomOfMe - 70)
			} completion: { (success) in
				
			}
			currentTranslation = (textField, parentToTranslate)
		}
		else if transformed {
			parentToTranslate.transform = CGAffineTransform.identity
		}
	}
	
	fileprivate func apply(_ to: UITextField) {
		guard let bundle = bundle else { return }
		if let kt = bundle.keyboardType {
			to.keyboardType = kt
		}
		if let p = bundle.placeholder, to.placeholder == nil {
			to.placeholder = p
		}
		if let s = bundle.prefix {
			let label = UILabel()
			label.font = to.font
			label.text = " " + s + " "
			to.leftView = label
			to.leftViewMode = .always
		}
		if let s = bundle.suffix {
			let label = UILabel()
			label.font = to.font
			label.text = " " + s + " "
			to.rightView = label
			to.rightViewMode = .always
		}
		if let alignment = bundle.alignment {
			to.textAlignment = alignment
		}
		if validators.contains(where: {$0 is NumberFormatter}) {
			to.makeTextWritingDirectionRightToLeft(nil)
		}
	}
	
	func updateDoneButton(textField: UITextField) {
		//guard let text = textField.text else {
		//	textField.shows
		//}
		//
	}
	
	func textFieldChangedByAdding(_ textField: UITextField) {
		guard let text = textField.text else {
			assert(false,"What???")
			return
		}
		
		guard textFieldShouldEndEditing(textField) else {
			return
		}
		
		// check for should end
		for r in uiProcessors {
			if r.shouldStopWithValue(text) {
				textField.resignFirstResponder()
				return
			}
		}
	}
	
	func textFieldChangedByRemoving(_ textField: UITextField) {
		errorView?.removeFromSuperview()
		errorView = nil
	}
	
	// Actual Delegate
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		if readonly { return false }
		if rfid {
			#if targetEnvironment(macCatalyst)
			#else
			#endif
			return false
		}
		
		apply(textField)
		let shouldBegin = originalDelegate?.textFieldShouldBeginEditing?(textField) ?? true
		guard shouldBegin else { return false }
		if var text = textField.text {
			for processor in dataTransformers {
				text = processor.process(text)
			}
			textField.text = text
		}
		return true
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		print("Did begin")
		apply(textField)
		originalDelegate?.textFieldDidBeginEditing?(textField)
		currentlyEditing = textField
		
		if let n = delayingKeboardWillShowNotification {
			keyboardWillShow(n)
		}
		// apply preprocessors
		if let text = textField.text {
			textField.text = processText(text)
			if let preselect = bundle?.preselect,
			   preselect {
				let start = textField.beginningOfDocument
				let end = textField.endOfDocument
				let range = textField.textRange(from: start, to: end)
				textField.selectedTextRange = range
			}
		}
		if let capitalization = self.bundle?.capitalizationType {
			textField.autocapitalizationType = capitalization
		}
	}
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		for processor in uiProcessors {
			guard processor.textField(textField, shouldChangeCharactersIn: range, replacementString: string) else {
				return false
			}
		}
		if let d = originalDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string),
		   d == false {
			return false
		}
		
		// true. we'll make the change ourself
		if let text = textField.text,
		   let textRange = Range(range, in: text) {
			textField.text = text.replacingCharacters(in: textRange, with: string)
		}
		else {
			assert(false,"What the?")
		}
		
		// if replacement is empty we must be adding
		if string.count > 0 {
			self.textFieldChangedByAdding(textField)
		}
		else {
			self.textFieldChangedByRemoving(textField)
		}
		return false
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if let d = originalDelegate?.textFieldShouldReturn {
			return d(textField)
		}
		// TODO: maybe a non-return validator?
		textField.resignFirstResponder()
		return true
	}
	
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		// allow blank so they can back out for now
		guard let text = textField.text, text.count > 0 else { return true }
		let issues = validators.compactMap { $0.hasProblem(text) }
		// TODO: maybe jiggle when they don't pass
		if issues.count > 0 {
			return false
		}
		return true
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		print("Did end")
		
		// apply ValidationPreprocessing
		// let the processors clean up the string
		if let text = textField.text {
			let updated = unprocessText(text)
			if updated != text {
				textField.text = updated
			}
		}
		
		originalDelegate?.textFieldDidEndEditing?(textField)
		
		errorView?.removeFromSuperview()
		errorView = nil
		
		onFinish?(textField.text)
		
		// undo translation
		if let t = currentTranslation,
		   t.textField === textField {
			UIView.animate(withDuration: 0.5, delay: 0.0, options: [.beginFromCurrentState]) {
				t.translated.transform = .identity
			} completion: { (success) in
				
			}
		}
		currentTranslation = nil
		currentlyEditing = nil
	}
	
	func unprocessText(_ text: String) -> String {
		var updated = text
		for processor in dataTransformers {
			updated = processor.unprocess(updated)
		}
		return updated
	}
	
	func processText(_ text: String) -> String {
		var updated = text
		for processor in dataTransformers {
			updated = processor.process(updated)
		}
		return updated
	}
	
}



fileprivate extension UIView {
	var translatableParentOrSelf: UIView? {				// if my tag is negative then translate my parent (recursively)
		// first try to find a scrollview
		if let sv = firstAncestorOfType(UIScrollView.self) {
			return sv
		}
		if self.tag < 0, let parent = superview {
			return parent.translatableParentOrSelf
		}
		if let grandparent = superview,
		   grandparent.subviews.contains(where: {$0 is UITextField}) {
			return grandparent.translatableParentOrSelf
		}
		if let array = superview as? UIStackView,			// if it's part of an array then move the array's parent
		   let grandparent = array.superview {
			return grandparent.translatableParentOrSelf
		}
		return self
	}
	var parentToTranslate: UIView? {					// the appropriate view to shift when the keyboard will cover it
		return superview?.translatableParentOrSelf
	}

	func firstAncestorOfType<T> (_ type: T.Type) -> T? where T: UIView {
		if let v = superview as? T { return v }
		return superview?.firstAncestorOfType(type)
	}
}

