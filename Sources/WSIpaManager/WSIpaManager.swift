import ArgumentParser

@main
class wsipamanager: ParsableCommand {

    required init() {
    }

    
    static var configuration = CommandConfiguration(
            abstract: "download from appstore",
            subcommands: [Search.self, Login.self, Download.self])
    
     public func run() {
         print("主命令执行完毕...")
         if CommandLine.arguments.count <= 1 {
             print("❌ 缺少命令")
             return
         }
    }
}


