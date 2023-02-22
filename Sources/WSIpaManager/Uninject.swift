//
//  Uninject.swift
//  WSIpaManager
//
//  Created by Molier on 2023/2/22.
//

import Foundation
import ArgumentParser


class Uninject: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "针对Maco-o的反注入工具")
    
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .long], help: "将要反注入的动态库路径")
    var dylibName: String = ""
    
    @Option(name: [.short, .long], help: "将要被反注入的ipa文件路径,注意是ipa文件，不是mach-o文件")
    var targetPath: String = ""

    func run() {
        
        if FileManager.default.fileExists(atPath: targetPath) == false ||
            dylibName.count == 0 {
            CommonMethod().showErrorMessage(text: "路径错误dylibName = \(dylibName) target = \(targetPath)")
            return
        }
        let ipaName = targetPath.components(separatedBy: "/").last!
        if ipaName.contain(str: ".ipa") == false {
            CommonMethod().showErrorMessage(text: "不是ipa文件target = \(targetPath)")
        }
        let operationPath:String = String(targetPath.dropLast(ipaName.count))
        CommonMethod().showCommonMessage(text: "操作路径为\(operationPath)")
        
        print("dylibName = \(dylibName) target = \(targetPath)")
        unInjectMacho(ipaPath: targetPath, dylibNmae: dylibName, operationPath:operationPath) { success in
            CommonMethod().showCommonMessage(text: "操作结束")
        }
        
    }
    
    func unInjectMacho(ipaPath: String, dylibNmae: String, operationPath:String, finishHandle:(Bool)->()) {
        var result = false

        CommonMethod().runShell("unzip -o \(ipaPath) -d \(operationPath)") { code, desc in
            if code == 0 {
                
                let payload = operationPath+"/Payload"
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
                    removeMachO(machoPath: machoPath, backup: false, dylibName: dylibName) { success in
                        if success {
                            CommonMethod().runShell("zip -r \(ipaPath) \(payload)") { code, desc in
                                if code == 0 {
                                    CommonMethod().showSuccessMessage(text: "反注入成功，已经覆盖了原ipa")
                                    result = true
                                } else {
                                    CommonMethod().showErrorMessage(text: "删除成功，但最后打包失败\(desc)")
                                }
                            }
                        }
                    }
                    try FileManager.default.removeItem(atPath: payload)
                } catch let err {
                    CommonMethod().showErrorMessage(text: "解压成功但是文件操作错误\(err)")
                }
            } else {
                CommonMethod().showErrorMessage(text: "解压失败\(desc)")
            }
        }
        finishHandle(result)
    }
    
    
    func removeMachO(machoPath: String, backup: Bool, dylibName: String, finishHandle:(Bool)->()) {
        var result = false
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
                doRealRemove(binary: binary, dylibName: dylibName) { newBinary in
                    result = CommonMethod().writeFile(newBinary: newBinary, machoPath: machoPath, isRemove: true)
                }
                
            }
        }
        finishHandle(result)
    }
    
    func doRealRemove(binary: Data, dylibName: String, handle: (Data?)->()) {
        var newbinary = binary
        var newHeaderData: Data?
        var machoRange: Range<Data.Index>?
        var start: Int?
        var size: Int?
        var end: Int?
        
        var newheader: mach_header_64
        let header = newbinary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)
        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch UInt32(loadCommand.cmd) {
            case LC_REEXPORT_DYLIB, LC_LOAD_WEAK_DYLIB, LC_LOAD_UPWARD_DYLIB, UInt32(LC_LOAD_DYLIB):
                let dylib_command = newbinary.extract(dylib_command.self, offset: offset)
                let path = String.init(data: newbinary, offset: offset, commandSize: Int(dylib_command.cmdsize), loadCommandString: dylib_command.dylib.name)
                print("我算出来的path = \(path)++++传入的path\(dylibName)")
                if path.contain(str: dylibName) {
                    //                        if path == dylibPath {
                    start = offset
                    size = Int(dylib_command.cmdsize)
                    newheader = mach_header_64(magic: header.magic, cputype: header.cputype, cpusubtype: header.cpusubtype, filetype: header.filetype, ncmds: header.ncmds-1, sizeofcmds: header.sizeofcmds-UInt32(dylib_command.cmdsize), flags: header.flags, reserved: header.reserved)
                    newHeaderData = Data(bytes: &newheader, count: MemoryLayout<mach_header_64>.size)
                    machoRange = Range(NSRange(location: 0, length: MemoryLayout<mach_header_64>.size))!
                }
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }
        end = offset
        
        if let s = start, let e = end, let si = size, let mr = machoRange, let nh = newHeaderData {
            let subrangeNew = Range(NSRange(location: s+si, length: e-s-si))!
            let subrangeOld = Range(NSRange(location: s, length: e-s))!
            var zero: UInt = 0
            var commandData = Data()
            commandData.append(newbinary.subdata(in: subrangeNew))
            commandData.append(Data(bytes: &zero, count: si))
            
            newbinary.replaceSubrange(subrangeOld, with: commandData)
            newbinary.replaceSubrange(mr, with: nh)
        }
        
        handle(newbinary)
    }
    
    
}
