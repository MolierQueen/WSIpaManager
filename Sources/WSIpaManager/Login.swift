//
//  Login.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
class Login: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "登录到AppleStore")

    @OptionGroup
    var commonParas: CommonMethod

    @Option(name: [.short, .customLong("username")], help: "输入appstore的用户名（login、download命令必传）")
    var userName: String = ""
    
    @Option(name: [.short, .customLong("password")], help: "输入appstore的密码（login、download命令必传）")
    var passWord: String = ""
    
    func run() {
        print("登录")
    }
}
