//
//  Login.swift
//  WSIpaManager
//
//  Created by 柴犬的Mini on 2023/2/12.
//
import ArgumentParser
import Foundation
import Alamofire
class Login: NSObject, ParsableCommand, XMLParserDelegate {
    required override init() {
    }
    static var configuration = CommandConfiguration(abstract: "登录到AppleStore")

    @OptionGroup
    var commonParas: CommonMethod

    @Option(name: [.short, .customLong("username")], help: "输入appstore的用户名（login、download命令必传）")
    var userName: String = ""
    
    @Option(name: [.short, .customLong("password")], help: "输入appstore的密码（login、download命令必传）")
    var passWord: String = ""
    
    
    var needSaveID = false
    
    func run() {
        loginRequest(authCod: "")
//        Thread.sleep(forTimeInterval: 5000)
    }
    
    func loginRequest(authCod:String) -> Void {
        var urlStr = "https://"+appstoreDomainForLogin+"/"+loginApi+"?"+"guid=\(String(describing: CommonMethod().guid()))"
        urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let finaURL = URL(string: urlStr)
        
//        print("开始登录进行登录... url == \(urlStr)")
        print("开始进行登录...")
        var paraDic = [String:String]()
        
        
        paraDic["appleId"] = "molierzhang@tencent.com"
        paraDic["password"] = "736430880@QQ.com"+authCod
        
//        paraDic["appleId"] = userName
//        paraDic["password"] = passWord+authCod
        if authCod.count > 0 {
            paraDic["attempt"] = "2"
        } else {
            paraDic["attempt"] = "4"
        }
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
        

//        let header1 = HTTPHeader.init(name: "Content-Type", value: "application/x-www-form-urlencoded")
//        let header2 = HTTPHeader.init(name: "User-Agent", value: "Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8")
//
//        AF.request(urlStr,method: .post,parameters: paraDic,encoder: URLEncodedFormParameterEncoder.default,headers: [header1, header2]).response { response in
//            debugPrint(response)
//        }
        

        let session: URLSession = URLSession.shared
        var request: URLRequest = URLRequest(url: finaURL!)
        request.httpMethod = POST_REQUEST
        request.httpBody = paraData

        //        设置Header
        request.setValue("Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")


        //        设置Cookie
        let cookie:String? = UserDefaults.standard.string(forKey: "cookie")
        if cookie != nil {
            let cookieArr = cookie!.components(separatedBy: ";")
            for str in cookieArr {
                let strArr = str.components(separatedBy: "=")
                if strArr.count == 2 {
                    let key = str.components(separatedBy: "=").first
                    let value = str.components(separatedBy: "=").last
                    var cookieProperties = [HTTPCookiePropertyKey: Any]()
                    cookieProperties[HTTPCookiePropertyKey.name]    = key
                    cookieProperties[HTTPCookiePropertyKey.value]   = value
                    cookieProperties[HTTPCookiePropertyKey.domain]  = appstoreDomainForLogin
                    cookieProperties[HTTPCookiePropertyKey.path]    = "/"
                    cookieProperties[HTTPCookiePropertyKey.originURL] = finaURL
                    let newCookie = HTTPCookie(properties: cookieProperties)
                    HTTPCookieStorage.shared.setCookie(newCookie!)
                }
            }
        }

        let semaphore_MyLogin = DispatchSemaphore(value: 0)

        let task = session.dataTask(with: request as URLRequest) { data, rsp, err in
            if err != nil {
                CommonMethod().showErrorMessage(text: "请求失败\(String(describing: err))")
            } else {

                let string:String! = String.init(data: data!, encoding: .utf8)

                let parser = XMLParser(data: data!)
                //设置delegate
                parser.delegate = self
                //开始解析
                parser.parse()
//                print("++我的解析字典==\(CommonMethod().getXmlDic())")


                if string.components(separatedBy: need2authCode).count > 1 {
                    print("请输入双重认证的Code：")
                    let authCode = readLine();
                    self.loginRequest(authCod: authCode!)
                } else {
                    guard let response = rsp as? HTTPURLResponse, response.statusCode == 200 else {
                        return
                    }
                    let cookie:String? = response.headers["Set-Cookie"]
                    UserDefaults.standard.set(cookie, forKey: "cookie")
                    UserDefaults.standard.synchronize()
                    let dsid = CommonMethod().getXmlDic()["dsid"] ?? "placeholder"
                    if dsid as! String == "placeholder" {
                        CommonMethod().showErrorMessage(text: "登录失败 没有获取到 dsid")
                    } else {
                        UserDefaults.standard.set(dsid, forKey: "dsid")
                        UserDefaults.standard.synchronize()
                        let dsid = CommonMethod().getXmlDic()["dsid"] ?? "placeholder"

                        
                        let firstName = CommonMethod().getXmlDic()["firstName"] ?? ""
                        let lastName = CommonMethod().getXmlDic()["lastName"] ?? ""
                        let appleId = CommonMethod().getXmlDic()["appleId"] ?? ""
                        CommonMethod().showSuccessMessage(text: "登录成功\n授权ID = \(dsid)\nappleid = \(appleId)\nfirstName = \(firstName)\nlastName = \(lastName)")

//                        CommonMethod().showSuccessMessage(text: "登录成功元数据----  \(String(describing: string))  dsid = \(dsid)")
                    }
                }
            }
            semaphore_MyLogin.signal()
        }
        task.resume()
        _ = semaphore_MyLogin.wait(timeout: .distantFuture)
        print("登录结束")
    }
    

    
    // 遇到字符串时调用
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        CommonMethod().needSave(elements: data, needSave: "dsid")
        CommonMethod().needSave(elements: data, needSave: "failureType")
        CommonMethod().needSave(elements: data, needSave: "message")
        CommonMethod().needSave(elements: data, needSave: "firstName")
        CommonMethod().needSave(elements: data, needSave: "lastName")
        CommonMethod().needSave(elements: data, needSave: "appleId")

//        if self.needSaveID {
//            UserDefaults.standard.set(string, forKey: "dsid")
//            UserDefaults.standard.synchronize()
//            self.needSaveID = false
//        }
//        if string == "dsid" {
//            self.needSaveID = true
//        }
    }
    
    
}
