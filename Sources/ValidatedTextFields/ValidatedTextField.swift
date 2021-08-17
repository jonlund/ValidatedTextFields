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



public struct Validator {}

	
//	struct HexColor: Validating {
//		func hasProblem(_ str: String) -> String? {
//			guard str.count == 8 else { return "Invalid number of characters" }
//			let allowedDigits = "01234567ABCDEF"
//			let filtered = str.filter { allowedDigits.contains($0)}
//			guard filtered.count == 8 else { return "Invalid character" }
//			return nil
//		}
//	}


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
	
	/// chose a value from the list of Values popup menu
	func pickedValue(_ value: String) {
		onFinish?(value)
	}
	
	@available(iOS 14.0, *)
	func setupListOfValues(_ values: [String], tf: UITextField) {
		let kTag = 1241234
		let button: UIButton
		if let btn = tf.viewWithTag(kTag) as? UIButton {
			btn.removeTarget(nil, action: nil, for: .allEvents)
			btn.menu = nil
			button = btn
		} else {
			button = UIButton(type: .custom)
			tf.addSubview(button)
			button.translatesAutoresizingMaskIntoConstraints = true
			button.frame = CGRect(origin: .zero, size: tf.bounds.size)
			button.autoresizingMask = [.flexibleWidth,.flexibleHeight]
		}
		let actions = values.map { value in
			UIAction(title: value) { [weak self] _ in
				tf.text = value
				self?.originalDelegate?.textFieldDidEndEditing?(tf)
				self?.pickedValue(value)
			}
		}
		button.menu = UIMenu(children: actions)
		button.showsMenuAsPrimaryAction = true
	}
	
	/// apply appropriate attributes to textfield initially
	internal func apply(_ to: UITextField) {
		
		// if we have a list then cover with a button
		if #available(iOS 14.0, *),
			let fixedValues = self.listOfValues {
			setupListOfValues(fixedValues, tf: to)
			return
		}
		
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

