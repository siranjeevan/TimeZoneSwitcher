import Foundation
import Combine

@Observable
public final class ClockManager {
    public static let shared = ClockManager()
    
    public var currentDate = Date()
    public var onTick: ((Date) -> Void)?
    private var timer: AnyCancellable?
    
    private init() {
        startTimer()
    }
    
    public func startTimer() {
        timer?.cancel()
        let interval = SettingsManager.shared.refreshInterval
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] newDate in
                self?.currentDate = newDate
                self?.onTick?(newDate)
            }
    }
    
    public func stopTimer() {
        timer?.cancel()
    }
}
