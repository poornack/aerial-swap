import Foundation
// Aerial Swap: runs the bundled reapply.sh. A real Mach-O executable is needed so that
// Login Items shows the bundle's icon instead of the generic "exec" script icon.
let script = Bundle.main.url(forResource: "reapply", withExtension: "sh")!.path
let p = Process()
p.executableURL = URL(fileURLWithPath: "/bin/zsh")
p.arguments = [script]
try p.run(); p.waitUntilExit()
exit(p.terminationStatus)
