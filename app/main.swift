import Foundation
import ServiceManagement
// Wallpaper Aerials Sync launcher.
//   (no args)     run the bundled reapply.sh   (what launchd calls)
//   --register    register the bundled LaunchAgent via SMAppService, so Login Items
//                 shows this app's name and icon instead of a "legacy agent"
//   --unregister  remove it
let plist = "com.poorna.aerialswap.plist"
switch CommandLine.arguments.dropFirst().first {
case "--register":
    let svc = SMAppService.agent(plistName: plist)
    do { try svc.register(); print("registered, status \(svc.status.rawValue)") }
    catch { print("register failed: \(error)"); exit(1) }
case "--unregister":
    let svc = SMAppService.agent(plistName: plist)
    do { try svc.unregister(); print("unregistered") } catch { print("unregister failed: \(error)"); exit(1) }
case "--status":
    print(SMAppService.agent(plistName: plist).status.rawValue)
default:
    let script = Bundle.main.url(forResource: "reapply", withExtension: "sh")!.path
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/bin/zsh"); p.arguments = [script]
    try p.run(); p.waitUntilExit(); exit(p.terminationStatus)
}
