//
//  CommonMethod.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
//公共参数
class CommonMethod: ParsableArguments {
    required init() {
    }
    @Option(name: [.customShort("x")], help: "这是一个公共参数")
    var common = false
}
