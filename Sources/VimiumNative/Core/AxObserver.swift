import Cocoa
import Darwin
import Foundation

private func internalCallback(
  _ axObserver: AXObserver,
  axElement: AXUIElement,
  notification: CFString,
  userData: UnsafeMutableRawPointer?
) {
  print("Got update", axElement)
  // guard let userData = userData else { fatalError("userData should be an AXSwift.Observer") }
  // let observer = Unmanaged<AXUIObserver>.fromOpaque(userData).takeUnretainedValue()
  // let element = UIElement(axElement)
  // guard let notif = AXNotification(rawValue: notification as String) else {
  //   NSLog("Unknown AX notification %s received", notification as String)
  //   return
  // }
  // observer.callback!(observer, element, notif)
}

enum AppError: Error {
  case runtimeError(String)
}

class AxObserver {
  var axObserver: AXObserver?

  public init(pid: pid_t) {
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
