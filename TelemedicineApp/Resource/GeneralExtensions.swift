//
//  GeneralExtensions.swift
//  Template
//
//  Created by Chandra_Mobiloitte on 15/06/18.
//  Copyright © 2018 Mobiloitte. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

//MARK: - NSMutable data extension

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        // check for cache
        if let cachedImage = imageCache.object(forKey: url.absoluteString as AnyObject) as? UIImage {
            image = cachedImage
            return
        }
        
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                self.image = UIImage(named: "placeholder")
                return
            }
            DispatchQueue.main.async { () -> Void in
                imageCache.setObject(image, forKey: url.absoluteString as AnyObject)
                
                self.image = image
            }
        }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
extension UIView {
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 1
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float) {
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        
        let backgroundCGColor = backgroundColor?.cgColor
        backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    
}

// MARK: - NSUserDefaults Extensions >>>>>>>>>>>>>>>>>>>>>>

extension UserDefaults {
    func colorForKey(_ key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }
        return color
    }
    
    func setColor(_ color: UIColor?, forKey key: String) {
        var colorData: Data?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        }
        set(colorData, forKey: key)
    }
}

//MARK: - UIImage Extensions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension UIImage {
    func maskWithColor(_ color: UIColor) -> UIImage? {
        let maskImage = cgImage
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let bitmapContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) //needs rawValue of bitmapInfo
        bitmapContext!.clip(to: bounds, mask: maskImage!)
        bitmapContext!.setFillColor(color.cgColor)
        bitmapContext!.fill(bounds) //is it nil?
        if let cImage = bitmapContext!.makeImage() {
            let coloredImage = UIImage(cgImage: cImage)
            return coloredImage
        } else {
            return nil
        }
    }
    
}

// MARK: - Array Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension Array {
    func contains<T>(_ obj: T) -> Bool where T: Equatable {
        return filter({ $0 as? T == obj }).count > 0
    }
}

// MARK: - Dictionary Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension Dictionary {
    mutating func unionInPlace(_ dictionary: Dictionary<Key, Value>) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    mutating func unionInPlace<S: Sequence>(_ sequence: S) where S.Iterator.Element == (Key, Value) {
        for (key, value) in sequence {
            self[key] = value
        }
    }
    
    func validatedValue(_ key: Key, expected: AnyObject) -> AnyObject {
        // checking if in case object is nil
        
        if let object = self[key] as? AnyObject {
            // added helper to check if in case we are getting number from server but we want a string from it
            if object is NSNumber, expected is String {
                return "\(object)" as AnyObject
            } else if object is NSNumber, expected is Float {
                return object.floatValue as AnyObject
            } else if object is NSNumber, expected is Double {
                return object.doubleValue as AnyObject
            } else if object.isKind(of: expected.classForCoder) == false {
                return expected
            } else if object is String {
                if (object as! String == "null") || (object as! String == "<null>") || (object as! String == "(null)") {
                    return "" as AnyObject
                }
            }
            return object
        } else {
            if expected is String || expected as! String == "" {
                return "" as AnyObject
            }
            
            return expected
        }
    }
}

// MARK: - NSDictionary Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension NSDictionary {
    func objectForKeyNotNull(_ key: AnyObject, expected: AnyObject?) -> AnyObject {
        // checking if in case object is nil
        if let object = self.object(forKey: key) {
            // added helper to check if in case we are getting number from server but we want a string from it
            if object is NSNumber, expected is String {
                //logInfo("case we are getting number from server but we want a string from it")
                return "\(object)" as AnyObject
            } else if (object as AnyObject).isKind(of: (expected?.classForCoder)!) == false {
                //logInfo("case // checking if object is of desired class....not")
                return expected!
            } else if object is String {
                if (object as! String == "null") || (object as! String == "<null>") || (object as! String == "(null)") {
                    //logInfo("null string")
                    return "" as AnyObject
                }
            }
            return object as AnyObject
            
        } else {
            if expected is String || expected as! String == "" {
                return "" as AnyObject
            }
            return expected!
        }
    }
    
    func objectForKeyNotNull(_ key: AnyObject) -> AnyObject {
        let object = self.object(forKey: key)
        
        if object is NSNull {
            return "" as AnyObject
        }
        
        if object == nil {
            return "" as AnyObject
        }
        
        if object is NSString {
            if (object as! String == "null") || (object as! String == "<null>") || (object as! String == "(null)") {
                return "" as AnyObject
            }
        }
        return object! as AnyObject
    }
    
    func objectForKeyNotNullExpectedObj(_ key: AnyObject, expectedObj: AnyObject) -> AnyObject {
        let object = self.object(forKey: key)
        
        if object is NSNull {
            return expectedObj
        }
        
        if object == nil {
            return expectedObj
        }
        
        if ((object as AnyObject).isKind(of: expectedObj.classForCoder)) == false {
            return expectedObj
        }
        
        return object! as AnyObject
    }
}

// MARK: - UIView Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@IBDesignable
extension UIView {
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    //
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    func shadow(_ color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 1
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 1.5, height: 1.5)
    }
    
    func setNormalRoundedShadow(_ color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 1
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0.3, height: 0.3)
    }
    
    func setBorder(_ color: UIColor, borderWidth: CGFloat) {
        layer.borderColor = color.cgColor
        layer.borderWidth = borderWidth
        clipsToBounds = true
    }
    
    func vibrate() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.02
        animation.repeatCount = 2
        animation.speed = 0.5
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 2.0, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 2.0, y: center.y))
        layer.add(animation, forKey: "position")
    }
    
    func shakeView() {
        transform = CGAffineTransform(translationX: 5, y: 5)
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1.0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func setTapperTriangleShape(_ color: UIColor) {
        // Build a triangular path
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 40, y: 40))
        path.addLine(to: CGPoint(x: 0, y: 100))
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        // Create a CAShapeLayer with this triangular path
        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = path.cgPath
        
        // Mask the view's layer with this shape
        layer.mask = mask
        
        backgroundColor = color
        
        // Transform the view for tapper shape
        transform = CGAffineTransform(rotationAngle: CGFloat(270) * CGFloat(Double.pi / 2) / 180.0)
    }
}

// MARK: - UISlider Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension UISlider {
    @IBInspectable var thumbImage: UIImage {
        get {
            return self.thumbImage(for: UIControl.State())!
        }
        set {
            setThumbImage(thumbImage, for: UIControl.State())
        }
    }
}

// MARK: - NSURL Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension URL {
    func isValid() -> Bool {
        if UIApplication.shared.canOpenURL(self) == true {
            return true
        } else {
            return false
        }
    }
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
    
    
}

// MARK: - NSDate Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension Date {
    func timestamp() -> String {
        return "\(timeIntervalSince1970)"
    }
    
    func dateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        return dateFormatter.string(from: self)
    }
    
    func dateStringFromDate(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: self)
    }
    
    func timeStringFromDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        
        return dateFormatter.string(from: self)
    }
    
    func yearsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.year, from: date, to: self, options: []).year!
    }
    
    func monthsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.month, from: date, to: self, options: []).month!
    }
    
    func weeksFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.weekOfYear, from: date, to: self, options: []).weekOfYear!
    }
    
    func daysFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.day, from: date, to: self, options: []).day!
    }
    
    func hoursFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.hour, from: date, to: self, options: []).hour!
    }
    
    func minutesFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.minute, from: date, to: self, options: []).minute!
    }
    
    func secondsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(.second, from: date, to: self, options: []).second!
    }
    
    func offsetFrom(_ date: Date) -> String {
        if yearsFrom(date) > 0 { return "\(yearsFrom(date))y" }
        if monthsFrom(date) > 0 { return "\(monthsFrom(date))M" }
        if weeksFrom(date) > 0 { return "\(weeksFrom(date))w" }
        if daysFrom(date) > 0 { return "\(daysFrom(date))d" }
        if hoursFrom(date) > 0 { return "\(hoursFrom(date))h" }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))m" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))s" }
        return ""
    }
}

// MARK: - UIViewController Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension UIViewController {
    func backViewController() -> UIViewController? {
        if let stack = self.navigationController?.viewControllers {
            for count in 0...stack.count - 1 {
                if stack[count] == self {
                    //     logInfo("viewController     \(stack[count-1])")
                    
                    return stack[count - 1]
                }
            }
        }
        return nil
    }
    
    // Check selected date with current date and return value by which we can know that the time is passed by more than one minute
    func checkForPassedDate(dateString: String, timeString: String) -> Bool {
        let newDateString = "\(dateString) \(timeString)"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy hh:mm a"
        let date = dateFormatter.date(from: newDateString)
        guard let passedDate = date else { return false }
        if passedDate == Date() {
            return true
        }
        else if passedDate < Date() {
            return true
        }
        else{
            let dayHourMinuteSecond: Set<Calendar.Component> = [.day, .hour, .minute, .second]
            let difference = NSCalendar.current.dateComponents(dayHourMinuteSecond, from: Date(), to:passedDate );
            
            if (difference.minute! <= 30) {
                return true
            } else {
                return false
            }
        }
    }
    
}

// MARK: - Int/Float/Double Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension Int {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)d" as NSString, self) as String
    }
}

extension Double {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension Float {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

// MARK: - UIImageView Extensions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

extension UIImageView {
    /*>>>>>>>>>>>>>>>>>>>>>>>>>>>> Changing icon color according to theme <<<<<<<<<<<<<<<<<<<<<<<<*/
    func setColor(_ color: UIColor) {
        if let image = self.image {
            var s = image.size // CGSize
            s.height *= image.scale
            s.width *= image.scale
            
            UIGraphicsBeginImageContext(s)
            
            var contextRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: s)
            
            // Retrieve source image and begin image context
            let itemImageSize = s //CGSize
            
            let xVal = (contextRect.size.width - itemImageSize.width) / 2
            let yVal = (contextRect.size.height - itemImageSize.height)
            
            //let itemImagePosition = CGPoint(x: ceilf(xFloatVal), y: ceilf(yVal)) //CGPoint
            
            let itemImagePosition = CGPoint(x: xVal, y: yVal) //CGPoint
            
            UIGraphicsBeginImageContext(contextRect.size)
            
            let c = UIGraphicsGetCurrentContext() //CGContextRef
            
            // Setup shadow
            // Setup transparency layer and clip to mask
            c!.beginTransparencyLayer(auxiliaryInfo: nil)
            c!.scaleBy(x: 1.0, y: -1.0)
            
            //CGContextRotateCTM(c, M_1_PI)
            
            c!.clip(to: CGRect(x: itemImagePosition.x, y: -itemImagePosition.y, width: itemImageSize.width, height: -itemImageSize.height), mask: image.cgImage!)
            
            // Fill and end the transparency layer
            let colorSpace = color.cgColor.colorSpace //CGColorSpaceRef
            let model = colorSpace!.model //CGColorSpaceModel
            
            let colors = color.cgColor.components
            
            if model == .monochrome {
                c!.setFillColor(red: (colors?[0])!, green: (colors?[0])!, blue: (colors?[0])!, alpha: (colors?[1])!)
            } else {
                c!.setFillColor(red: (colors?[0])!, green: (colors?[1])!, blue: (colors?[2])!, alpha: (colors?[3])!)
            }
            
            contextRect.size.height = -contextRect.size.height
            contextRect.size.height -= 15
            c!.fill(contextRect)
            c!.endTransparencyLayer()
            
            let img = UIGraphicsGetImageFromCurrentImageContext() //UIImage
            
            let img2 = UIImage(cgImage: img!.cgImage!, scale: image.scale, orientation: image.imageOrientation)
            
            UIGraphicsEndImageContext()
            
            self.image = img2
            
        } else {
            // Debug.log("Unable to chage color of image. Image not found")
        }
    }
}

//MARK: - Date Extension

extension Date {
    var millisecondsSince1970: Int {
        return Int(timeIntervalSince1970.rounded())
    }
    
    init(milliseconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
    
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date) > 0 { return years(from: date) > 1 ? "\(years(from: date)) years ago" : "\(years(from: date)) year ago" }
        if months(from: date) > 0 { return months(from: date) > 1 ? "\(months(from: date)) months ago" : "\(months(from: date)) month ago" }
        if weeks(from: date) > 0 { return weeks(from: date) > 1 ? "\(weeks(from: date)) weeks ago" : "\(weeks(from: date)) week ago" }
        if days(from: date) > 0 { return days(from: date) > 1 ? "\(days(from: date)) days ago" : "\(days(from: date)) day ago" }
        if hours(from: date) > 0 { return hours(from: date) > 1 ? "\(hours(from: date)) hours ago" : "\(hours(from: date)) hour ago" }
        if minutes(from: date) > 0 { return minutes(from: date) > 1 ? "\(minutes(from: date))" : "\(minutes(from: date))" }
        if seconds(from: date) > 0 { return "\(seconds(from: date)) secs ago" }
        return ""
    }
}


extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        leftView = paddingView
        leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        rightView = paddingView
        rightViewMode = .always
    }
}

public extension UITextField {
    func useUnderline() {
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.lightGray.cgColor
        border.frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - borderWidth), size: CGSize(width: frame.size.width, height: frame.size.height))
        border.borderWidth = borderWidth
        layer.addSublayer(border)
        layer.masksToBounds = true
    }
    
    func makeUnderlineInvisible() {
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.lightGray.cgColor
        border.frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - borderWidth), size: CGSize(width: frame.size.width, height: frame.size.height))
        border.borderWidth = borderWidth
        layer.addSublayer(border)
        layer.masksToBounds = true
    }
    
    func makeUnderLineRed() {
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor.red.cgColor
        border.frame = CGRect(origin: CGPoint(x: 0, y: frame.size.height - borderWidth), size: CGSize(width: frame.size.width, height: frame.size.height))
        border.borderWidth = borderWidth
        layer.addSublayer(border)
        layer.masksToBounds = true
    }
}

extension UIButton {
    func underlineButton(text: String) {
        let titleString = NSMutableAttributedString(string: text)
        titleString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, text.count))
        setAttributedTitle(titleString, for: .normal)
    }
}

extension UIApplication {
    var statusBarView: UIView? {
        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
        return nil
    }
}

func getCurrentController(_ vc: UIViewController) -> UIViewController {
    if let pc = vc.presentedViewController {
        return getCurrentController(pc)
    } else if let nc = vc as? UINavigationController {
        if nc.viewControllers.count > 0 {
            return getCurrentController(nc.viewControllers.last!)
        } else {
            return nc
        }
    } else {
        return vc
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}
