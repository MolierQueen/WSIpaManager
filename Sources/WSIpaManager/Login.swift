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
        loginRequest(authCodd: "")
    }
    
    func loginRequest(authCodd:String) -> Void {
        var urlStr = "https://"+appstoreDomainForDownloadAndLogin+"/"+loginApi+"?"+"guid=\(String(describing: CommonMethod().guid()))"
        urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let finaURL = URL(string: urlStr)
        print("开始登录 url == \(urlStr)")
        var paraDic = [String:String]()
        paraDic["appleId"] = userName
        paraDic["password"] = passWord+authCodd
        paraDic["attempt"] = "4"
        paraDic["createSession"] = "true"
        paraDic["guid"] = CommonMethod().guid()
        paraDic["rmp"] = "0"
        paraDic["why"] = "signIn"
        
        var paraData:Data = Data()
        do {
            paraData = try JSONSerialization.data(withJSONObject: paraDic)
        } catch {
            print(error)
        }
            
        let session: URLSession = URLSession.shared
        var request: URLRequest = URLRequest(url: finaURL!)
        request.httpMethod = "POST"
        request.httpBody = paraData
         
        request.setValue("Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = session.dataTask(with: request as URLRequest) { data, rsp, err in
            if err != nil {
                CommonMethod().showErrorMessage(text: "请求失败\(String(describing: err))")
            } else {

                let string:String! = String.init(data: data!, encoding: .utf8)
                
                if string.components(separatedBy: need2authCode).count > 1 {
                    print("请输入双重认证的Code：")
                    let authCode = readLine();
                    self.loginRequest(authCodd: authCode!)
                } else {
                    CommonMethod().showSuccessMessage(text: "登录成功元数据----  \(String(describing: string))")
                }
                
                
                CommonMethod().showSuccessMessage(text: "请求成功 ✅元数据----  \(String(describing: string))")
            }
    
            semaphore_login.signal()
        }
        task.resume()
        semaphore_login.wait()
        print("登录")
    }
}
