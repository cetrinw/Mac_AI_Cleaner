import Foundation
import CleanerCore

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.contains("--help") {
    print("cleaner-scan [--home /absolute/path] [--redact] [--memory]\nRead-only metadata scan. No contents are read or deleted. --redact removes paths from JSON. --memory prints VM and process memory.")
} else if arguments.contains("--memory") {
    let snapshot = MemoryMonitor.snapshot()
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
    print(String(decoding: try! encoder.encode(snapshot), as: UTF8.self))
} else {
    var home = FileManager.default.homeDirectoryForCurrentUser
    if let index = arguments.firstIndex(of: "--home") {
        guard arguments.indices.contains(index + 1), arguments[index + 1].hasPrefix("/") else { fputs("--home requires an absolute path\n", stderr); exit(2) }
        home = URL(fileURLWithPath: arguments[index + 1])
    }
    // Custom homes do not inherit the current user's private tool directories.
    let scanner = Scanner(home: home, environment: arguments.contains("--home") ? [:] : ProcessInfo.processInfo.environment)
    let report = scanner.scan()
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
    var data = try encoder.encode(report)
    if arguments.contains("--redact") {
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        object["findings"] = report.findings.map { ["tool": $0.tool, "bytes": $0.bytes, "files": $0.files, "risk": $0.risk.rawValue, "incomplete": $0.incomplete] as [String: Any] }
        object["issues"] = report.issues.isEmpty ? [] : ["Some paths were inaccessible or scan limits were reached."]
        data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }
    print(String(decoding: data, as: UTF8.self))
}
