//
//  Generateproj.swift
//  WSIpaManager
//
//  Created by Molier on 2023/3/8.
//

import Foundation
import ArgumentParser
class Generateproj: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "生成二次开发工程")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "已经被砸壳的ipa路径，可以为空")
    var iPAPath: String = ""
    
    
    func run() -> Void {
        if iPAPath.count == 0 {
            CommonMethod().showErrorMessage(text: "ipa路径不能为空")
            return
        }
        
        CommonMethod().showCommonMessage(text: "会在当前目录下生成WSIpaHookTool工程，是否继续 Y/n")
        let mark = readLine();
        if mark == "n" {
            return
        }
        
        copyDepencyFile()
        
        let gitUrl = "https://github.com/MolierQueen/WSIpaHookTool.git"
        CommonMethod().showCommonMessage(text: "开始生成工程...")
        CommonMethod().runShell(shellPath: "/bin/bash", command: "git clone \(gitUrl)") { code, desc in
            if code == 0 {
                let tar = "\(FileManager.default.currentDirectoryPath)/WSIpaHookTool/WSIpaHookTool/TargetApp/target.ipa"
                do {
                    CommonMethod().showCommonMessage(text: "开始拷贝ipa...")
                    try FileManager.default.copyItem(atPath:iPAPath, toPath: "\(tar)")
                } catch let err {
                    CommonMethod().showErrorMessage(text: "拷贝ipa失败 = \(err)")
                }
            }
        }
    
        
        CommonMethod().runShell(shellPath:  "/bin/bash", command: "open WSIpaHookTool/WSIpaHookTool.xcworkspace") { code2, desc2 in
            if code2 == 0 {
                CommonMethod().showSuccessMessage(text: "任务完成")
            }
        }
    }
    
    func copyDepencyFile() -> Void {
        let runtime_1 = CommonMethod().myBundlePathCustomPath(path: "libstdc++.6.0.9",extName: ".dylib")
        let runtime_2 = CommonMethod().myBundlePathCustomPath(path: "libstdc++.6",extName: ".dylib")
        let runtime_3 = CommonMethod().myBundlePathCustomPath(path: "libstdc++",extName: ".dylib")
        let runtimeTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/"
        
        
        let SDK_1 = CommonMethod().myBundlePathCustomPath(path: "libstdc++.6.0.9",extName: ".tbd")
        let SDK_2 = CommonMethod().myBundlePathCustomPath(path: "libstdc++.6",extName: ".tbd")
        let SDK_3 = CommonMethod().myBundlePathCustomPath(path: "libstdc++",extName: ".tbd")
        let MACTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/"
        let iphoneTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/"
        let simulatorTarget = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib/"
        CommonMethod().showCommonMessage(text: "开始配置依赖...")
        
        
        fileCopyIfNeed(filePath: runtime_3, targetPath: runtimeTarget)
        fileCopyIfNeed(filePath: runtime_2, targetPath: runtimeTarget)
        fileCopyIfNeed(filePath: runtime_1, targetPath: runtimeTarget)
        
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
            if !FileManager.default.fileExists(atPath: "\(targetPath)/\(fileName)") {
                try FileManager.default.copyItem(atPath:filePath, toPath: targetPath)
            } else {
                CommonMethod().showWarningMessage(text: "文件已存在 = \(targetPath)/\(fileName)")
            }
        } catch let err {
            CommonMethod().showErrorMessage(text: "配置依赖失败 = \(targetPath)/\(fileName) error = \(err)")
            Generateproj.exit()
        }
    }
}
