import Foundation

/// Default values for use with Pendable.
public final class PendableDefaults: @unchecked Sendable {
    public static let shared = PendableDefaults()
    private let lock = NSLock()

    public init() {}

    /// The amount of time to delay before resolving a pending Pendable with the fallback value.
    /// By default this is 2 seconds. Conveniently, just long enough to be twice Nimble's default polling timeout.
    /// In general, you should keep this set to some number greater than Nimble's default polling timeout,
    /// in order to allow polling matchers to work correctly.
    public static var delay: TimeInterval {
        get {
            PendableDefaults.shared.delay
        }
        set {
            PendableDefaults.shared.delay = newValue
        }
    }

    private var _delay: TimeInterval = 2
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
