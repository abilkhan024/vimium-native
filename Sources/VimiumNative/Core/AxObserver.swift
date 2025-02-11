import Cocoa
import Darwin
import Foundation

enum AppError: Error {
  case runtimeError(String)
}

class AxObserver {
  public typealias Notifier = (
    // _ observer: Observer,
    // _ element: UIElement,
    // _ notification: AXNotification
  ) -> Void
  var axObserver: AXObserver?
  let notify: Notifier

  public init(pid: pid_t, notify: @escaping Notifier) {
    self.notify = notify
    var axObserver: AXObserver?
    let error = AXObserverCreate(pid, internalCallback, &axObserver)
    if error == .success {
      assert(axObserver != nil)
      self.axObserver = axObserver
      start()
    }
  }

  public func start() {
    guard let observer = axObserver else { return }
    CFRunLoopAddSource(
      RunLoop.current.getCFRunLoop(),
      AXObserverGetRunLoopSource(observer),
      CFRunLoopMode.defaultMode)
  }

  public func stop() {
    guard let observer = axObserver else { return }
    CFRunLoopRemoveSource(
      RunLoop.current.getCFRunLoop(),
      AXObserverGetRunLoopSource(observer),
      CFRunLoopMode.defaultMode)
  }

  public func addNotification(
    _ notification: CFString,
    forElement element: AXUIElement
  ) {
    guard let observer = axObserver else { return }
    let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    let error = AXObserverAddNotification(
      observer, element, notification, selfPtr
    )
    if error == .success || error == .notificationAlreadyRegistered {
      return
    }
    print("Got error \(error)")
  }
}

private func internalCallback(
  _ axObserver: AXObserver,
  _ axElement: AXUIElement,
  _ notification: CFString,
  _ userData: UnsafeMutableRawPointer?
) {
  guard let userData = userData else { fatalError("userData should be an AXSwift.Observer") }

  let observer = Unmanaged<AxObserver>.fromOpaque(userData).takeUnretainedValue()
  observer.notify()
}
