import Cocoa

class ProcessUtils {
  static func findProcesses(path target: String) -> [pid_t] {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
    var size = 0

    if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
      return []
    }

    let count = size / MemoryLayout<kinfo_proc>.stride
    let buffer = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)

    defer { buffer.deallocate() }

    if sysctl(&mib, u_int(mib.count), buffer, &size, nil, 0) != 0 {
      return []
    }

    var result: [pid_t] = []

    for i in 0..<count {
      let proc = buffer[i].kp_proc
      let path = getPath(pid: proc.p_pid)

      if path == target {
        result.append(proc.p_pid)
      }
    }

    return result
  }

  static func getPath(pid: pid_t) -> String? {
    var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
    let ret = proc_pidpath(pid, &buf, UInt32(buf.count))
    if ret > 0 {
      return String(utf8String: buf)
    }
    return nil
  }

}
