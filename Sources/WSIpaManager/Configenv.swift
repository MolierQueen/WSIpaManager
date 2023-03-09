//
//  Configenv.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/3/10.
//

import ArgumentParser
import Foundation

class Configenv: ParsableCommand {

    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "一键配置环境")
    
    public func run() {
        

        let gitUrl = "https://github.com/MolierQueen/TmpDepency.git"
        CommonMethod().showCommonMessage(text: "开始配置...")
        CommonMethod().runShell(shellPath: "/bin/bash", command: "git clone \(gitUrl)") { code, desc in
            if code == 0 {
                let downloadmanagerPath = "/usr/local/bin/"
                let injecttoolPath = "/usr/local/bin/"
                let downloadSource = FileManager.default.currentDirectoryPath+"/TmpDepency/downloadmanager"
                let injectSource = FileManager.default.currentDirectoryPath+"/TmpDepency/injecttool"
                fileCopyIfNeed(filePath: downloadSource, targetPath: downloadmanagerPath)
                fileCopyIfNeed(filePath: injectSource, targetPath: injecttoolPath)
                
                copyDepencyFile()
                
                do {
                    try FileManager.default.removeItem(atPath: "\(FileManager.default.currentDirectoryPath)/TmpDepency")
                } catch let err {
                    CommonMethod().showErrorMessage(text: "删除临时文件失败:\(err)")
                }
                
            }
        }
    }
    
    func copyDepencyFile() -> Void {
        let runtime_1 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.0.9.dylib"
        let runtime_2 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.dylib"
        let runtime_3 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.dylib"
        let runtimeTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/"
        fileCopyIfNeed(filePath: runtime_3, targetPath: runtimeTarget)
        fileCopyIfNeed(filePath: runtime_2, targetPath: runtimeTarget)
        fileCopyIfNeed(filePath: runtime_1, targetPath: runtimeTarget)
        
        let SDK_1 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.0.9.tbd"
        let SDK_2 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.6.tbd"
        let SDK_3 = FileManager.default.currentDirectoryPath+"/TmpDepency/libstdc++.tbd"
        let MACTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/"
        let iphoneTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/"
        let simulatorTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/"
       fileCopyIfNeed(filePath: SDK_1, targetPath: MACTarget)
       fileCopyIfNeed(filePath: SDK_2, targetPath: MACTarget)
       fileCopyIfNeed(filePath: SDK_3, targetPath: MACTarget)
       
       fileCopyIfNeed(filePath: SDK_1, targetPath: iphoneTarget)
       fileCopyIfNeed(filePath: SDK_2, targetPath: iphoneTarget)
       fileCopyIfNeed(filePath: SDK_3, targetPath: iphoneTarget)
       
       fileCopyIfNeed(filePath: SDK_1, targetPath: simulatorTarget)
       fileCopyIfNeed(filePath: SDK_2, targetPath: simulatorTarget)
       fileCopyIfNeed(filePath: SDK_3, targetPath: simulatorTarget)
    }
    
    func fileCopyIfNeed(filePath:String, targetPath:String) -> Void {
        let fileName = filePath.components(separatedBy: "/").last!
        do {
            if !FileManager.default.fileExists(atPath: "\(targetPath)\(fileName)") {
                try FileManager.default.copyItem(atPath:filePath, toPath: targetPath+fileName)
            } else {
                CommonMethod().showWarningMessage(text: "文件已存在 = \(targetPath)/\(fileName)")
            }
        } catch let err {
            CommonMethod().showErrorMessage(text: "配置依赖失败 = \(targetPath)/\(fileName) error = \(err)")
            Generateproj.exit()
        }
    }
    
}
