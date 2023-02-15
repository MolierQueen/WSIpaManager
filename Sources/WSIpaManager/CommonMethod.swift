//
//  CommonMethod.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
let GET_REQUEST = "GET"
let POST_REQUEST = "POST"

let appstoreDomain = "itunes.apple.com"
let appstoreDomainForLogin = "p71-buy.itunes.apple.com"
let appstoreDomainForDownload = "p25-buy.itunes.apple.com"

let searchApi = "search"
let loginApi = "WebObjects/MZFinance.woa/wa/authenticate"
let downloadApi = "WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct"

let semaphore_search = DispatchSemaphore(value: 0)
let semaphore_login = DispatchSemaphore(value: 0)
let semaphore_loginAuthCode = DispatchSemaphore(value: 0)
let semaphore_download = DispatchSemaphore(value: 0)

let need2authCode = "MZFinance.BadLogin.Configurator_message"
var xmlDic = [String:Any]()


//公共参数
class CommonMethod: ParsableArguments {
    
    required init() {
    }
    @Option(name: [.customShort("x")], help: "这是一个公共参数")
    var common = false
    
    //    获取UID
    public func guid() -> String {
        
        let MAC_ADDRESS_LENGTH = 6
        
        let bsds: [String] = ["en0", "en1"]
        
        var bsd: String = bsds[0]
        
        var length : size_t = 0
        
        var buffer : [CChar]
        
        var bsdIndex = Int32(if_nametoindex(bsd))
        
        if bsdIndex == 0 {
            
            bsd = bsds[1]
            
            bsdIndex = Int32(if_nametoindex(bsd))
            
            guard bsdIndex != 0 else { fatalError("Could not read MAC address") }
            
        }
        let bsdData = Data(bsd.utf8)
        
        var managementInfoBase = [CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, bsdIndex]
        
        guard sysctl(&managementInfoBase, 6, nil, &length, nil, 0) >= 0 else { fatalError("Could not read MAC address") }
        
        buffer = [CChar](unsafeUninitializedCapacity: length, initializingWith: {buffer, initializedCount in
            
            for x in 0..<length { buffer[x] = 0 }
            
            initializedCount = length
            
        })
        guard sysctl(&managementInfoBase, 6, &buffer, &length, nil, 0) >= 0 else { fatalError("Could not read MAC address") }
        
        let infoData = Data(bytes: buffer, count: length)
        
        let indexAfterMsghdr = MemoryLayout<if_msghdr>.stride + 1
        
        let rangeOfToken = infoData[indexAfterMsghdr...].range(of: bsdData)!
        
        let lower = rangeOfToken.upperBound
        
        let upper = lower + MAC_ADDRESS_LENGTH
        
        let macAddressData = infoData[lower..<upper]
        
        let addressBytes = macAddressData.map{ String(format:"%02x", $0) }
        
        return addressBytes.joined().uppercased()
    }
    
    
    func paraData(data:Data) -> Dictionary<String, Any> {
        let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        if dict == nil {
            showErrorMessage(text: "解析失败")
            return [:]
          }
        return dict as! Dictionary<String, Any>
    }
    
    func needSave(elements:String, needSave:String) -> Void {
        if xmlDic[needSave] as? String == "placeholder" {
            xmlDic[needSave] = elements
        }
        if elements == needSave {
            xmlDic[needSave] = "placeholder"
        }
    }
    
    func getXmlDic() -> [String:Any] {
        return xmlDic
    }
    
    //    展示错误信息
    public func showErrorMessage(text:String) -> Void {
        print("❌ \(String(describing: text))")
    }
    
    public func showWarningMessage(text:String) -> Void {
        print("⚠️ \(text)")
    }
    
    public func showSuccessMessage(text:String) -> Void {
        print("🎉 \(text)")
    }
}
