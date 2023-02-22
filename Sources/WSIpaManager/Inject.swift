//
//  Inject.swift
//  WSIpaManager
//
//  Created by Molier on 2023/2/22.
//
import ArgumentParser
import Foundation
import MachO
class Inject: ParsableCommand {
    required init() {
    }
    
    static var configuration = CommandConfiguration(abstract: "针对Maco-o的注入工具")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "将要注入的动态库路径")
    var sourcePath: String = ""
    
    @Option(name: [.short, .long], help: "将要被注入的ipa文件路径,注意是ipa文件，不是mach-o文件")
    var targetPath: String = ""

     func run() {
         if FileManager.default.fileExists(atPath: sourcePath) == false ||
                FileManager.default.fileExists(atPath: targetPath) == false {
             CommonMethod().showErrorMessage(text: "路径错误source = \(sourcePath) target = \(targetPath)")
             return
         }
         let ipaName = targetPath.components(separatedBy: "/").last!
         if ipaName.contain(str: ".ipa") == false {
             CommonMethod().showErrorMessage(text: "不是ipa文件target = \(targetPath)")
         }
         let operationPath:String = String(targetPath.dropLast(ipaName.count))
         CommonMethod().showCommonMessage(text: "操作路径为\(operationPath)")
         injectIPA(ipaPath: targetPath, ipaName: ipaName, injectPath: sourcePath, operationPath: operationPath) { success in
         }
         
         
         
         print("source = \(sourcePath) target = \(targetPath)")
    }
    
    
    func injectIPA(ipaPath: String, ipaName:String, injectPath: String, operationPath:String, finishHandle:(Bool)->()) {
        var result = false
        var frameworkNameWithExt = ""
        var injectPathName = ""
        if injectPath.hasSuffix(".framework") {
            
            //            取到动态库名字和扩展名 xxx.framework
            frameworkNameWithExt = injectPath.components(separatedBy: "/").last!
            //            即将被注入的动态库的扩展名分开（取出名字）
            let frameworkName = frameworkNameWithExt.components(separatedBy: ".").first!
            
            injectPathName = "\(DYLIB_EXECUTABLE_PATH)/\(frameworkNameWithExt)/\(frameworkName)"
            
            
        } else if injectPath.hasSuffix(".dylib") {
            frameworkNameWithExt = injectPath.components(separatedBy: "/").last!
            injectPathName = "\(DYLIB_EXECUTABLE_PATH)+\(frameworkNameWithExt)"
        } else {
            CommonMethod().showErrorMessage(text: "动态库不合法")
            finishHandle(false)
        }
        CommonMethod().runShell("unzip -o \(ipaPath) -d \(operationPath)") { code, des in
            //            解压后取出app文件和macho文件的路径
            if code == 0 {
                let payload = operationPath+"Payload"
                do {
                    let fileList = try FileManager.default.contentsOfDirectory(atPath: payload)
                    var machoPath = ""
                    var appPath = ""
                    for item in fileList {
                        if item.hasSuffix(".app") {
                            appPath = payload + "/\(item)"
                            machoPath = appPath+"/\(item.components(separatedBy: ".")[0])"
                            break
                        }
                    }
                    
                    //                    创建一个文件夹
                    try FileManager.default.createDirectory(atPath: "\(appPath)/\(DYLIB_PATH)/", withIntermediateDirectories: true, attributes: nil)
                    //                    把要注入的动态库放进去
                    try FileManager.default.moveItem(atPath: injectPath, toPath: "\(appPath)/\(DYLIB_PATH)/\(frameworkNameWithExt)")
                    
                    //                    开始注入
                    injectMachO(machoPath: machoPath, backup: false, injectPath: injectPathName) { success in
                        if success {
                            //                            注入完成后压缩打包成ipa
                            CommonMethod().runShell("zip -r \(ipaPath) \(payload)") { code, desc in
                                if code == 0 {
                                    CommonMethod().showSuccessMessage(text: "注入成功，已经覆盖了原ipa")
                                    result = true
                                } else {
                                    CommonMethod().showErrorMessage(text: "压缩失败\(des)")
                                }
                            }
                        }
                    }
                    try FileManager.default.removeItem(atPath: payload)
                } catch let err {
                    CommonMethod().showErrorMessage(text: "解压成功但是文件操作错误\(err)")
                }
            } else {
                CommonMethod().showErrorMessage(text: "解压失败\(des)")
            }
        }
        finishHandle(result)
    }
    
    
    func injectMachO(machoPath: String, backup: Bool, injectPath: String, finishHandle:(Bool)->()) {
        var result = false
        //        打开mach-o文件（将mach-o打开以data形式读取出来）
        FileManager.open(machoPath: machoPath, backup: backup) { data in
            if let binary = data {
                let fatHeader = binary.extract(fat_header.self)
                let type = fatHeader.magic
                //                判断macho是什么类型
                if type != MH_MAGIC_64
                    && type != MH_CIGAM_64 {
                    CommonMethod().showErrorMessage(text: "mach_o文件类型不符合")
                    finishHandle(false)
                    return
                }
                if injectPath.count > 0 {
                    
                    //                            先判断能否注入
                    canInject(binary: binary, dylibPath: injectPath) { canInject in
                        if canInject {
                            //                                可以注入，开始注入
                            doRealInject(binary: binary, dylibPath: injectPath ) { newBinary in
                                result = CommonMethod().writeFile(newBinary: newBinary, machoPath: machoPath, isRemove: false)
                            }
                        }
                    }
                }
            }
        }
        finishHandle(result)
    }
    
    
    func canInject(binary: Data, dylibPath: String, handle: (Bool)->()) {
        
        //            先取出Mach64Header
        let header = binary.extract(mach_header_64.self)
        //            先取出Mach64Header
        var offset = MemoryLayout.size(ofValue: header)
        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch loadCommand.cmd {
            case LC_REEXPORT_DYLIB, LC_LOAD_UPWARD_DYLIB, LC_LOAD_WEAK_DYLIB, UInt32(LC_LOAD_DYLIB):
                let command = binary.extract(dylib_command.self, offset: offset)
                let curPath = String(data: binary, offset: offset, commandSize: Int(command.cmdsize), loadCommandString: command.dylib.name)
                let curName = curPath.components(separatedBy: "/").last
                if curName == dylibPath || curPath == dylibPath {
                    CommonMethod().showErrorMessage(text: "该动态库已经存在\(curPath)")
                    handle(false)
                    return
                }
                break
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }
        handle(true)
    }
    
    func doRealInject(binary: Data, dylibPath: String, handle: (Data?)->()) {
        var newbinary = binary
        let length = MemoryLayout<dylib_command>.size + dylibPath.lengthOfBytes(using: String.Encoding.utf8)
        let padding = (8 - (length % 8))
        let cmdsize = length+padding
        
        var start = 0
        var end = cmdsize
        var subData: Data
        var newHeaderData: Data
        var machoRange: Range<Data.Index>
        let header = binary.extract(mach_header_64.self)
        start = Int(header.sizeofcmds)+Int(MemoryLayout<mach_header_64>.size)
        end += start
        subData = newbinary[start..<end]
        
        var newheader = mach_header_64(magic: header.magic, cputype: header.cputype, cpusubtype: header.cpusubtype, filetype: header.filetype, ncmds: header.ncmds+1, sizeofcmds: header.sizeofcmds+UInt32(cmdsize), flags: header.flags, reserved: header.reserved)
        newHeaderData = Data(bytes: &newheader, count: MemoryLayout<mach_header_64>.size)
        machoRange = Range(NSRange(location: 0, length: MemoryLayout<mach_header_64>.size))!
        
        let d = String(data: subData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        if d != "" && d != nil {
            CommonMethod().showErrorMessage(text: "不能插入\(dylibPath)了没有空间了")
            handle(nil)
            return
        }
        
        let dy = dylib(name: lc_str(offset: UInt32(MemoryLayout<dylib_command>.size)), timestamp: 2, current_version: 0, compatibility_version: 0)
        var command = dylib_command(cmd: UInt32(LC_LOAD_DYLIB), cmdsize: UInt32(cmdsize), dylib: dy)
        
        var zero: UInt = 0
        var commandData = Data()
        commandData.append(Data(bytes: &command, count: MemoryLayout<dylib_command>.size))
        commandData.append(dylibPath.data(using: String.Encoding.ascii) ?? Data())
        commandData.append(Data(bytes: &zero, count: padding))
        
        let subrange = Range(NSRange(location: start, length: commandData.count))!
        newbinary.replaceSubrange(subrange, with: commandData)
        
        newbinary.replaceSubrange(machoRange, with: newHeaderData)
        
        handle(newbinary)
    }

}
