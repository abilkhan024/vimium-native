import CoreGraphics
import SwiftUI

// let q = DispatchQueue(label: "q")

// if el == query_el_at(el.point) or relates to el then visible

@MainActor
class FzFindFastListener: Listener {
  private let hintsWindow = FzFindFastWindowManager.get(.hints)
  private var appListener: AppListener?
  private let state = FzFindFastState.shared

  private let runner = DispatchQueue.init(label: "fz_runner", qos: .userInteractive)
  private let poller = DispatchQueue.init(label: "fz_poller", qos: .userInteractive)

  private var visibleEls: [HintElement] = []
  private var input = ""

  var count = 0
  var good = 0
  var bad = 0
  var els: [AXUIElement] = []
  var elsPointer = UnsafeMutablePointer<[AXUIElement]>.allocate(capacity: 1)

  init() {

    // print(NSScreen.screens.first?.frame.maxX, NSScreen.screens.first?.frame.maxY)

    // 90 * 20

    hintsWindow.render(AnyView(FzFindFastHintsView())).front().call()
    // hintsWindow.render(AnyView(Text("Here").foregroundColor(.red).position(x: 777, y: 121))).front()
    //   .call()
    // hintsWindow.render(AnyView(Text("Here").position(x: 830, y: 186))).front().call()
    // hintsWindow.render(AnyView(Text("Here").position(x: 780, y: 186))).front().call()

    // test5()
    // test4()

    // Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true) { _ in
    //   DispatchQueue.main.async {
    //     self.els = self.testRawBFS()
    //   }
    // }
  }

  func test5() {
    // if let app = NSWorkspace.shared.frontmostApplication {
    //   let pid = app.processIdentifier
    //   let appEl = AXUIElementCreateApplication(pid)
    //   func dfs(el: AXUIElement) {
    //     if let point = AxElementUtils.getPoint(el) {
    //       var value: AXUIElement?
    //       var ptr = unsafe(&value)
    //       let error = AXUIElementCopyElementAtPosition(appEl, Float(point.x), Float(point.y), ptr)
    //       if error == .success, let ptrEl = ptr.pointee {
    //         if ptrEl != el {
    //           print("Not same \(AxElementUtils.toString(el)) \(AxElementUtils.toString(ptrEl))")
    //           return
    //         } else {
    //           print("Same \(AxElementUtils.toString(el)) \(AxElementUtils.toString(ptrEl))")
    //         }
    //       } else {
    //         print("Failed \(error)")
    //       }
    //     } else {
    //       print("No point")
    //     }
    //
    //     var children: CFTypeRef?
    //     let childResult = AXUIElementCopyAttributeValue(
    //       el, kAXChildrenAttribute as CFString, &children)
    //
    //     if childResult == .success, let childrenEls = children as? [AXUIElement] {
    //       for child in childrenEls {
    //         dfs(el: child)
    //       }
    //     } else {
    //       print("No children")
    //     }
    //   }
    //   dfs(el: appEl)
    // }
  }

  func unsafe<T>(_ p: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    return p
  }
  var test4set: Set<AXUIElement> = []
  func asdf(x: Float, y: Float) {
    var value: AXUIElement?
    var ptr = unsafe(&value)
    // defer { ptr.deallocate() }
    let error = AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), x, y, ptr)
    if error == .success, let element = ptr.pointee {
      good += 1
      // dfs(from: element)
      test4set.insert(element)
      // print("\(AxElementUtils.toString(element) ?? "NO_STR")")
    } else {
      bad += 1
      // print("Error getting element at position: \(error)")
    }

  }

  func test4() {
    guard let maxX = NSScreen.screens.first?.frame.maxX,
      let maxY = NSScreen.screens.first?.frame.maxY
    else { return }

    let start = DispatchTime.now().uptimeNanoseconds
    let rows = maxY / 20
    let cols = maxX / 90

    for i in 1...Int(rows) {
      for j in 1...Int(cols) {
        asdf(x: Float(90 * j), y: Float(20 * i))
      }
    }

    print("Took \(DispatchTime.now().uptimeNanoseconds - start)")
    print("Good \(good), bad \(bad), uniq \(test4set.count), count \(count)")
    for el in test4set {
      state.hints.append(AxElement(el))
    }
    state.texts = HintUtils.getLabels(from: state.hints.count)
    good = 0
    bad = 0
    count = 0
    hintsWindow.front().call()
    state.visible = true
  }

  // build a tree of axuielement wrappers
  // starting an application as root
  //
  // axui_app => Root { children: [axui_wrap] }
  //
  // traverse from root check if is alive by role, if not remove the tree node -> implicitly all it's children
  // and only trigger an issue for the front
  func test3() {

  }
  func test1() {
    // TR -> (while 1)
    // Main                                         -> Set els
    // T1              -> Poll (Find app, find els)            -> sleep until next tick
    runner.async {

      var count = 0
      while true {
        // if self.appListener != nil { https://gemini.google.com/app/3ec0c09fba49ee5d?utm_source=chrome_omnibox&utm_medium=owned&utm_campaign=gemini_shortcut
        // }
        let start = DispatchTime.now().uptimeNanoseconds
        var els: [AXUIElement] = []
        self.poller.sync {
          // if let app = NSWorkspace.shared.frontmostApplication {
          //   // print("Polling \(app.bundleIdentifier ?? "Fallback")")
          //
          //   let pid = app.processIdentifier
          //
          //   let el = AXUIElementCreateApplication(pid)
          //
          //   var stack = [el]
          //   while !stack.isEmpty {
          //     let sub = stack.popLast()!
          //     if isHintable(sub) {
          //       els.append(el)
          //     }
          //
          //     var children: CFTypeRef?
          //     let childResult = AXUIElementCopyAttributeValue(
          //       sub, kAXChildrenAttribute as CFString, &children)
          //
          //     if childResult == .success, let childrenEls = children as? [AXUIElement] {
          //       stack.append(contentsOf: childrenEls)
          //     }
          //   }
          //
          //   // func dfs(from element: AXUIElement) {
          //   //   els.append(element)
          //   //   // if els.count > 20 {
          //   //   //   return
          //   //   // }
          //   //
          //   //   var children: CFTypeRef?
          //   //   let childResult = AXUIElementCopyAttributeValue(
          //   //     element, kAXChildrenAttribute as CFString, &children)
          //   //
          //   //   if childResult == .success, let childrenEls = children as? [AXUIElement] {
          //   //     for child in childrenEls {
          //   //       dfs(from: child)
          //   //     }
          //   //   }
          //   // }
          //   // dfs(from: el)
          // }
          //
        }
        count += 1

        DispatchQueue.main.sync {
          let hints = els.map { e in AxElement(e) }.filter { e in
            if e.point != nil {
              return true
            }
            return false
          }
          self.state.hints = hints
          self.state.texts = HintUtils.getLabels(from: hints.count)
          // print(self.state.hints.count, self.state.texts.count)
          print(
            "Have been called \(count) got \(els.count), took \(DispatchTime.now().uptimeNanoseconds - start)"
          )
        }

        usleep(10_000)
      }
    }

  }

  func match(_ event: CGEvent) -> Bool {
    let flags = event.flags
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    return flags.contains(.maskCommand) && flags.contains(.maskShift)
      && keyCode == Keys.dot.rawValue
  }

  func callback(_ event: CGEvent) {
    // DispatchQueue.global(qos: .userInteractive).async {
    DispatchQueue.main.async {
      let ignoredActions = [
        "AXShowMenu",
        "AXScrollToVisible",
        "AXShowDefaultUI",
        "AXShowAlternateUI",
      ]

      @MainActor
      func testRawBFS() -> [AXUIElement] {
        func isHintable(_ el: AXUIElement) -> Bool {
          guard let role = AxElementUtils.getAttributeString(el, kAXRoleAttribute) else {
            return false
          }
          if role == "AXRow" {
            print("Wow")
          }
          if role == "AXWindow" || role == "AXScrollArea" {
            return false
          }

          return isActionable(el) || isRowWithoutHintableChildren(el)
        }
        func isActionable(_ el: AXUIElement) -> Bool {
          var names: CFArray?
          let error = AXUIElementCopyActionNames(el, &names)

          if error == .noValue || error == .attributeUnsupported {
            return false
          }

          if error != .success {
            return false
          }
          let actions = names! as [AnyObject] as! [String]
          var count = 0
          for ignored in ignoredActions {
            for action in actions {
              if action == ignored {
                count += 1
              }
            }
          }
          if AxElementUtils.getPoint(el)?.y == 121.0, AxElementUtils.isInViewport(el) == true,
            let rect = AxElementUtils.getBoundingRect(el), let str = AxElementUtils.toString(el),
            actions.count > count
          {
            // print("--- \(str) | \(actions), \(rect.minX) \(rect.minY) \(rect.maxX) \(rect.maxY)")
          }

          return actions.count > count
        }
        func isRowWithoutHintableChildren(_ el: AXUIElement) -> Bool {
          return false
        }

        let app = NSWorkspace.shared.frontmostApplication!
        let start = DispatchTime.now().uptimeNanoseconds

        let pid = app.processIdentifier

        let appEl = AXUIElementCreateApplication(pid)
        var els: [AXUIElement] = []
        let h = self.hintsWindow.native().frame.height
        let w = self.hintsWindow.native().frame.width

        var stack = [appEl]
        while !stack.isEmpty {
          let sub = stack.popLast()!
          // if let point = AxElementUtils.getPoint(sub) {
          //   print(point)  // if child is not in viewport then ignore?
          // }
          let visible = AxElementUtils.isInViewport(sub, w, h)
          if isHintable(sub) && visible == true {
            els.append(sub)
            // if let point = AxElementUtils.getPoint(sub), point.y == 121.0,
            //   let rect = AxElementUtils.getBoundingRect(sub), let str = AxElementUtils.toString(sub)
            // {
            // print("\(str)| \(rect.minX) \(rect.minY) \(rect.maxX) \(rect.maxY)")
            // }
          }

          if visible != false {
            var children: CFTypeRef?
            let childResult = AXUIElementCopyAttributeValue(
              sub, kAXChildrenAttribute as CFString, &children)

            if childResult == .success, let childrenEls = children as? [AXUIElement] {
              stack.append(contentsOf: childrenEls)
            }
          } else {
            if AxElementUtils.getAttributeString(sub, kAXRoleAttribute) == "AXGroup" {
              let rect = AxElementUtils.getBoundingRect(sub)
              print(rect?.height, rect?.width)
              print("\(rect?.minX), \(rect?.maxX), \(rect?.minY), \(rect?.maxY)")
            }
            print("\(AxElementUtils.toString(sub) ?? "No str")")
          }
          // if parent rect is visible
        }

        return els
      }
      let start = DispatchTime.now().uptimeNanoseconds
      self.els = testRawBFS()
      self.state.hints = self.els.map { e in AxElement(e) }
      self.state.texts = HintUtils.getLabels(from: self.els.count)
      self.hintsWindow.front().call()
      if let prev = self.appListener {
        AppEventManager.remove(prev)
      }
      self.appListener = AppListener(onEvent: self.onTyping)
      AppEventManager.add(self.appListener!)

      print("Took \(DispatchTime.now().uptimeNanoseconds - start) Got \(self.els.count)")
    }

    // AppState.shared.observer = AxObserver(
    //   pid: pid,
    //   notify: { native, e, notification, observer in
    //   })
    // DispatchQueue.global(qos: .userInteractive).async {
    //   // limiting dfs, on visible solves the problem,
    //   // then we would be able to do repeated calls in sub second mark
    //
    //   // show pulled hosts and revalidate others? keeping the same hint label ->
    //   // point but possibly deleting other and adding more?
    //
    //   var count = 0
    //   let el = AXUIElementCreateApplication(pid)
    //   var els: [AXUIElement] = []
    //
    //   func dfs(from element: AXUIElement) {
    //     els.append(el)
    //
    //     count += 1
    //     var children: CFTypeRef?
    //     let childResult = AXUIElementCopyAttributeValue(
    //       element, kAXChildrenAttribute as CFString, &children)
    //
    //     if childResult == .success, let childrenEls = children as? [AXUIElement] {
    //       for child in childrenEls {
    //         dfs(from: child)
    //       }
    //     }
    //   }
    //   let start = DispatchTime.now().uptimeNanoseconds
    //   dfs(from: el)
    //   print(
    //     "Took \(DispatchTime.now().uptimeNanoseconds - start), Counted \(count)"
    //   )
    //
    //   DispatchQueue.main.sync {
    //     for element in els {
    //       if AppState.shared.observer!.addNotification(
    //         "AXFocusedWindowChanged", forElement: element)
    //       {
    //       }
    //       if AppState.shared.observer!.addNotification("AXWindowMoved", forElement: element) {}
    //       if AppState.shared.observer!.addNotification("AXWindowMiniaturized", forElement: element)
    //       {
    //       }
    //
    //       // if AppState.shared.observer!.addNotification(
    //       //   kAXValueChangedNotification, forElement: element)
    //       // {
    //       // }
    //       if AppState.shared.observer!.addNotification(
    //         kAXUIElementDestroyedNotification, forElement: element)
    //       {
    //       }
    //       if AppState.shared.observer!.addNotification(kAXCreatedNotification, forElement: element)
    //       {
    //       }
    //     }
    //   }
    //
    // }

    // count = 0
    // input = ""

    // appListener = AppListener(onEvent: self.onTyping)
    // AppEventManager.add(appListener!)

    // AxRequester.shared.waitCooldown()
    // if let value = notification as String?, value == "AXUIElementDestroyed" {
    //   AppState.shared.axMap[e] = nil
    //   return
    // }
    //
    // if AppState.shared.axMap[e] == nil {
    //   AppState.shared.axMap[e] = AxElement(e)
    // }
    // AppState.shared.axMap[e]?.revalidate()
    //
    // count += 1
    // print("Revaliation started")
    // // let _ = AppState.shared.axApps[pid]?.revalidateTree()
    // print("Current map size \(AppState.shared.axMap.count), called \(count)")

    // AppState.shared.observer?.addNotification(kAXUIElementDestroyedNotification, forElement: el)
    // AppState.shared.observer?.addNotification(kAXCreatedNotification, forElement: el)

    // Notifing AXUIElementDestroyed

    // if AppState.shared.axApps[pid] == nil {
    //   AppState.shared.axApps[pid] = AxApp(pid: pid)
    // }
    //
    // let els = AppState.shared.axApps[pid]!.getVisibleElements()
    // state.hints = els
    // state.texts = HintUtils.getLabels(from: els.count)
    // hintsWindow.front().call()
  }

  private func dfs(from element: AXUIElement) {
    // els.append(element)
    count += 1
    var children: CFTypeRef?
    let childResult = AXUIElementCopyAttributeValue(
      element, kAXChildrenAttribute as CFString, &children)

    if childResult == .success, let childrenEls = children as? [AXUIElement] {
      for child in childrenEls {
        dfs(from: child)
      }
    }
  }

  private func onClose() {
    hintsWindow.hide().call()
    state.visible = false
    DispatchQueue.main.async {
      if let listener = self.appListener {
        AppEventManager.remove(listener)
        self.appListener = nil
      }
      self.input = ""
    }
  }

  private func selectEl(_ el: AxElement) {
    // guard let point = el.position else { return }
    // SystemUtils.click(point)
    // print("Selecting \(el.id)")  // shortcut for click to current position again?
  }

  private func onTyping(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    switch keyCode {
    case Keys.esc.rawValue:
      return onClose()
    case Keys.enter.rawValue:
      if let first = self.state.hints.count == 1 ? self.state.hints.first : nil {
        self.selectEl(first)
      }
      return onClose()
    case Keys.backspace.rawValue:
      input = String(input.dropLast())
      if input.isEmpty {
        return renderHints(self.visibleEls)
      }
      return renderHints(searchEls(els: self.visibleEls, search: input))
    default:
      guard let char = SystemUtils.getChar(from: event) else { return }
      input.append(char)
      return renderHints(searchEls(els: self.visibleEls, search: input))
    }
  }

  private func searchEls(els: [HintElement], search: String) -> [HintElement] {
    if search.isEmpty {
      return els
    }

    return els.filter { (e) in
      e.id.lowercased().starts(with: search)
    }
  }

  private func renderHints(_ els: [HintElement]) {
    // if els.isEmpty {
    //   hintsWindow.hide().call()
    // }
    // state.hints = els
    // NSCursor.hide()
  }

}
