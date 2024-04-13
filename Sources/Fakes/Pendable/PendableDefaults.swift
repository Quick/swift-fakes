import Foundation

/// Default values for use with Pendable.
public final class PendableDefaults: @unchecked Sendable {
    public static let shared = PendableDefaults()
    private let lock = NSLock()

    public init() {}

    public static var delay: TimeInterval {
        get {
            PendableDefaults.shared.delay
        }
        set {
            PendableDefaults.shared.delay = newValue
        }
    }

    private var _delay: TimeInterval = 1
    public var delay: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _delay
        }
        set {
            lock.lock()
            _delay = newValue
            lock.unlock()
        }
    }
}
