//
//  Download.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
class Download: ParsableCommand {
    required init() {
    }
    static var configuration = CommandConfiguration(abstract: "从AppleStore下载App")
    
    @OptionGroup
    var commonParas: CommonMethod
    
    func run() {
        print("下载")
    }
}
