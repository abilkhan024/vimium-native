import CoreGraphics

class KeyMapping {
  let key: Key
  let modifiers: [Modifier]

  init(key: Key, modifiers: [Modifier] = []) {
    self.key = key
    self.modifiers = modifiers
  }

  public func matches(event: CGEvent) -> Bool {
    for flag in modifiers.map({ mod in mod.cgEventFlag }) {
      if !event.flags.contains(flag) {
        return false
      }
    }

    return key.rawValue == event.getIntegerValueField(.keyboardEventKeycode)
  }

  static func create(from: String) -> KeyMapping? {
    var value = from
    var keyStr = ""
    while mappingToValue[keyStr] == nil {
      if let char = value.popLast() {
        keyStr.insert(char, at: keyStr.startIndex)
      } else {
        return nil
      }
    }

    guard let keyRaw = mappingToValue[keyStr], let key = Key(rawValue: keyRaw) else {
      print("WARNING: parsed key was not found in dict")
      return nil
    }
    var modStr = ""
    var mods: [Modifier] = []
    while !value.isEmpty {
      guard let modValue = mappingToValue[modStr] else {
        modStr.insert(value.popLast()!, at: modStr.startIndex)
        continue
      }
      guard let mod = Modifier(rawValue: modValue) else {
        print("WARNING: Modifier failed to be parsed")
        return nil
      }
      mods.append(mod)
      modStr.removeAll()
    }

    return KeyMapping(key: key, modifiers: mods)
  }

  private static let mappingToValue: [String: Int64] = [
    "a": Key.a.rawValue,
    "s": Key.s.rawValue,
    "d": Key.d.rawValue,
    "f": Key.f.rawValue,
    "g": Key.g.rawValue,
    "h": Key.h.rawValue,
    "j": Key.j.rawValue,
    "k": Key.k.rawValue,
    "l": Key.l.rawValue,
    ";": Key.semicolon.rawValue,
    "'": Key.quote.rawValue,
    "z": Key.z.rawValue,
    "x": Key.x.rawValue,
    "c": Key.c.rawValue,
    "v": Key.v.rawValue,
    "b": Key.b.rawValue,
    "n": Key.n.rawValue,
    "m": Key.m.rawValue,
    ",": Key.comma.rawValue,
    ".": Key.dot.rawValue,
    "/": Key.slash.rawValue,

    "q": Key.q.rawValue,
    "w": Key.w.rawValue,
    "e": Key.e.rawValue,
    "r": Key.r.rawValue,
    "t": Key.t.rawValue,
    "y": Key.y.rawValue,
    "u": Key.u.rawValue,
    "i": Key.i.rawValue,
    "o": Key.o.rawValue,
    "p": Key.p.rawValue,

    "1": Key.one.rawValue,
    "2": Key.two.rawValue,
    "3": Key.three.rawValue,
    "4": Key.four.rawValue,
    "5": Key.five.rawValue,
    "6": Key.six.rawValue,
    "7": Key.seven.rawValue,
    "8": Key.eight.rawValue,
    "9": Key.nine.rawValue,
    "0": Key.zero.rawValue,
    "-": Key.minus.rawValue,
    "=": Key.equals.rawValue,

    "[": Key.leftBracket.rawValue,
    "]": Key.rightBracket.rawValue,
    "\\": Key.backslash.rawValue,
    "`": Key.backTick.rawValue,

    "<Left>": Key.left.rawValue,
    "<Right>": Key.right.rawValue,
    "<Down>": Key.down.rawValue,
    "<Up>": Key.up.rawValue,
    "<Space>": Key.space.rawValue,
    "<Caps>": Key.caps.rawValue,
    "<Tab>": Key.tab.rawValue,
    "<BS>": Key.backspace.rawValue,
    "<Esc>": Key.esc.rawValue,
    "<CR>": Key.enter.rawValue,

    "<Fn>": Modifier.fn.rawValue,
    "<S>": Modifier.shift.rawValue,
    "<C>": Modifier.control.rawValue,
    "<M>": Modifier.option.rawValue,
    "<D>": Modifier.command.rawValue,
  ]
}

enum Modifier: Int64 {
  case shift = 56
  case control = 59
  case option = 58
  case command = 55
  case fn = 63

  var cgEventFlag: CGEventFlags {
    switch self {
    case .shift:
      return .maskShift
    case .control:
      return .maskControl
    case .command:
      return .maskCommand
    case .option:
      return .maskAlternate
    case .fn:
      return .maskSecondaryFn
    }
  }
}

enum Key: Int64 {
  case a = 0
  case s = 1
  case d = 2
  case f = 3
  case g = 5
  case h = 4
  case j = 38
  case k = 40
  case l = 37
  case semicolon = 41
  case quote = 39
  case z = 6
  case x = 7
  case c = 8
  case v = 9
  case b = 11
  case n = 45
  case m = 46
  case comma = 43
  case dot = 47
  case slash = 44
  case space = 49
  case q = 12
  case w = 13
  case e = 14
  case r = 15
  case t = 17
  case y = 16
  case u = 32
  case i = 34
  case o = 31
  case p = 35
  case one = 18
  case two = 19
  case three = 20
  case four = 21
  case five = 23
  case six = 22
  case seven = 26
  case eight = 28
  case nine = 25
  case zero = 29
  case minus = 27
  case equals = 24
  case leftBracket = 33
  case rightBracket = 30
  case backslash = 42
  case backTick = 50

  case caps = 57
  case tab = 48
  case esc = 53
  case backspace = 51
  case left = 123
  case right = 124
  case down = 125
  case up = 126
  case enter = 36
}
