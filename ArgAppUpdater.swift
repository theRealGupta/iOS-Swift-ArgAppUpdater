//
//  ArgAppUpdater.swift
//  Sorion
//
//  Created by Anup Gupta on 04/04/18.
//  Copyright © 2018 GeekGuns. All rights reserved.
//

import UIKit

enum VersionError: Error {
    case invalidBundleInfo, invalidResponse
}

class LookupResult: Decodable {
    var results: [AppInfo]
}

class AppInfo: Decodable {
    var version: String
    var trackViewUrl: String
    //let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String,
    // You can add many thing based on "http://itunes.apple.com/lookup?bundleId=\(identifier)"  response
    // here version and trackViewUrl are key of URL response
    // so you can add all key beased on your requirement.
    
}

class ArgAppUpdater: NSObject {
    private static var _instance: ArgAppUpdater?;
    
    private override init() {
        
    }
    
    public static func getSingleton() -> ArgAppUpdater {
        if (ArgAppUpdater._instance == nil) {
            ArgAppUpdater._instance = ArgAppUpdater.init();
        }
        return ArgAppUpdater._instance!;
    }
    
    private func getAppInfo(completion: @escaping (AppInfo?, Error?) -> Void) -> URLSessionDataTask? {
        guard let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                DispatchQueue.main.async {
                    completion(nil, VersionError.invalidBundleInfo)
                }
                return nil
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error }
                guard let data = data else { throw VersionError.invalidResponse }
                
                print("Data:::",data)
                print("response###",response!)
                
                let result = try JSONDecoder().decode(LookupResult.self, from: data)
                
                let dictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                print("dictionary",dictionary!)
                
                
                guard let info = result.results.first else { throw VersionError.invalidResponse }
                print("result:::",result)
                completion(info, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        
        print("task ******", task)
        return task
    }
    
    func checkVersion() {
        let info = Bundle.main.infoDictionary
        let currentVersion = info?["CFBundleShortVersionString"] as? String
        _ = getAppInfo { (info, error) in
            
            print("info:::",info as Any)
            
            print("App link :::" , info?.trackViewUrl as Any)
            if let error = error {
                print(error)
            } else if info?.version == currentVersion {
                print("updated")
            } else {
                print("needs update")
                
                //                let vc = UIViewController()
                //                vc.showAppUpdateAlert(Version : (info?.version)! , Force: false)
                
                
                
                DispatchQueue.main.async {
                    UIApplication.shared.keyWindow?.rootViewController?.parent?.showAppUpdateAlert(Version: (info?.version)!, Force: false, AppURL: (info?.trackViewUrl)!)
                }
            }
        }
        
        
    }
}

extension UIViewController {
    func showAppUpdateAlert( Version : String, Force: Bool, AppURL: String) {
        
        let bundleName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as! String;
        let alertMessage = "\(bundleName) Version \(Version) is available on AppStore."
        let alertTitle = "New Version"
        
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        
        if !Force {
            let notNowButton = UIAlertAction(title: "Not Now", style: .default) { (action:UIAlertAction) in
                print("Don't Call API");
                
                guard let url = URL(string: AppURL) else {
                    return
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            alertController.addAction(notNowButton)
        }
        
        let updateButton = UIAlertAction(title: "Update", style: .default) { (action:UIAlertAction) in
            print("Call API");
            print("No update")
            
        }
        
        alertController.addAction(updateButton)
        self.present(alertController, animated: true, completion: nil)
    }
}
