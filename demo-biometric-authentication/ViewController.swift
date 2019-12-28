//
//  ViewController.swift
//  demo-biometric-authentication
//
//  Created by NishiokaKohei on 28/12/2019.
//  Copyright © 2019 Takumi. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func onDeviceOwnerAuthenticationWithBiometrics(_ sender: UIButton) {
        autheticate { isSccess, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "失敗", message: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onDeviceOwnerAuthentication(_ sender: UIButton) {
        passcode { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "失敗", message: error.localizedDescription)
                }
            }
        }
    }

    /// The Authenticattion using a biometric method (Touch ID or Face ID).
    func autheticate(_ completion: ((Bool, Error?) -> Void)? = nil) {
        let context: LAContext = {
            let context = LAContext()
            context.localizedCancelTitle = "キャンセル"
            context.localizedFallbackTitle = "パスコード入力"
            return context
        }()
        var error: NSError?
        let reason = "Local Authentication"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {

            if shouldHandle(error) {
                showAlert(title: "失敗", message: error?.localizedDescription ?? "エラーが発生しました。")
                return
            }

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { isGranted, error in
                if isGranted {
                    print("success")
                    if #available(iOS 11.0, *) {
                        switch context.biometryType {
                        case .faceID:
                            print("faceID")
                        case .touchID:
                            print("touchID")
                        case .none:
                            print("生体認証をサポートしてません。")
                        default:
                            break
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                    completion?(true, nil)
                } else {
                    // Fallback on earlier versions
                    if let error = error as? LAError {
                        switch error.code {
                        case .userFallback:
                            self.passcode { isSuccess, error in
                                if isSuccess {
                                    print("success")
                                    completion?(true, nil)
                                } else {
                                    print("failure: \(error?.localizedDescription ?? "")")
                                    completion?(false, error)

                                }
                            }
                            
                        default:
                            break
                        }
                    } else {
                        // Unknown
                        print("failure")
                        completion?(false, error)
                    }
                }
            }
        } else {
            // A fingerprint enrolled with Touch ID or a face set up with Face ID
            // are not satisfied with certain requirements
            let description = error?.localizedDescription ?? ""
            print(description)
            completion?(false, error)
        }
    }

    /// The Authenticatation by biometry or device passcode.
    func passcode(_ completion: ((Bool, Error?) -> Void)? = nil) {
        let context: LAContext = {
            let context = LAContext()
            context.localizedCancelTitle = "キャンセル"
            context.localizedFallbackTitle = "パスコード入力"
            return context
        }()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "パスコード入力") { isSuccess, _ in
                if isSuccess {
                    print("success")
                    completion?(true, nil)
                } else {
                    print("failure")
                    completion?(false, error)
                }
            }
        } else {
            // A fingerprint enrolled with Touch ID or a face set up with Face ID
            // are not satisfied with certain requirements
            let description = error?.localizedDescription ?? ""

            print(description)
            completion?(false, error)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            // do something
        }))
        present(alert, animated: true)
    }

    func shouldHandle(_ error: NSError?) -> Bool {
        if let error = error as? LAError {
            switch error.code {
            case .authenticationFailed: // 認証が失敗した
                return true
            case .userCancel:           // 「キャンセル」ボタンが押された
                return true
            case .userFallback:         // 「フォールバック (パスワードを入力)」ボタンが押された
                return true
            case .systemCancel:         // システムによってキャンセルされた
                return true
            default:
                return false
            }
        }
        return false
    }



}

