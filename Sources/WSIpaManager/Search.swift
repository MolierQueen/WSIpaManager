//
//  Search.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser


 

class Search: ParsableCommand {
    required init() {
    }
    
    static var configuration = CommandConfiguration(abstract: "搜索appstore上的App")

    //    这是一个参数列表
    @OptionGroup
    var options: CommonMethod
    
    @Option(name: [.short, .customLong("trackid")], help: "输入app在applestore上的id（网址后面的id 必传）")
    var trackID: String = ""
    
    @Option(name: [.short, .customLong("country")], help: "输入app在applestore上的国家")
    var country: String = ""

     func run() {
         searchAppWith(trackID: trackID, country:country )
         print("搜索")
    }
    
    func searchAppWith(trackID:String, country:String) {
        print("搜索 \(trackID)  国家\(country)")
    }
}
