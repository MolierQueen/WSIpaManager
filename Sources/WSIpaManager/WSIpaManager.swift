import ArgumentParser

@main
class wsipamanager: ParsableCommand {

    required init() {
    }

    
    static var configuration = CommandConfiguration(
            abstract: "download from appstore",
            subcommands: [Search.self, Login.self, Download.self])
    
     public func run() {
         if CommandLine.arguments.count <= 1 {
             CommonMethod().showErrorMessage(text: "缺少命令")
             return
         }
    }
}


