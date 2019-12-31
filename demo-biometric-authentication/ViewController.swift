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

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // MARK: - IBActions

    @IBAction func onDeviceOwnerAuthenticationWithBiometrics(_ sender: UIButton) {
        autheticate(feedback: .main) { isSuccess, error in
            if let error = error {
                self.showAlert(title: "error", message: error.localizedDescription)
            } else if isSuccess {
                self.showAlert(title: "success", message: "認証に成功しました。")
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

}

private extension ViewController {

    // MARK: - Private mathods

    static func createLAContext() -> LAContext {
        {
            let context = LAContext()
            context.localizedCancelTitle = "キャンセル"
            context.localizedFallbackTitle = "パスコード入力"
            return context
        }()
    }

    /// The Authenticattion using a biometric method (Touch ID or Face ID).
    func autheticate(feedback queue: DispatchQueue = .main, _ completion: ((Bool, Error?) -> Void)? = nil) {
        let context = ViewController.createLAContext()
        var error: NSError?
        let reason = "Local Authentication"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] isGranted, e in
                if isGranted {
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
                    queue.async {
                        completion?(true, nil)
                    }
                } else {
                    // Fallback on earlier versions
                    if let error = error as? LAError {
                        self?.logError(error)
                        switch error.code {
                        case .userFallback:
                            self?.passcode { [weak self] isSuccess, e in
                                self?.logError(e)
                                if isSuccess {
                                    queue.async {
                                        completion?(true, nil)
                                    }
                                } else {
                                    queue.async {
                                        completion?(false, error)
                                    }
                                }
                            }
                        default:
                            break
                        }
                    } else {
                        // Unknown
                        self?.logError(e)
                        queue.async {
                            completion?(false, error)
                        }
                    }
                }
            }
        } else {
            // A fingerprint enrolled with Touch ID or a face set up with Face ID
            // are not satisfied with certain requirements
            logError(error)
            queue.async {
                completion?(false, error)
            }
        }
    }

    /// The Authenticatation by biometry or device passcode.
    func passcode(_ completion: ((Bool, Error?) -> Void)? = nil) {
        let context = ViewController.createLAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "パスコード入力") { isSuccess, e in
                self.logError(e)
                if isSuccess {
                    completion?(true, nil)
                } else {
                    completion?(false, error)
                }
            }
        } else {
            // A fingerprint enrolled with Touch ID or a face set up with Face ID
            // are not satisfied with certain requirements
            logError(error)
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

    // MARK: - To handle/display Local Authentication Error

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


    func logError(_ error: Error?) {
        logError(error as NSError?)
    }

    func logError(_ error: NSError?) {
        if error == .none {
            print("認証に成功しました。")
            return
        }
        if let error = error as? LAError {
            switch error.code {
            case .authenticationFailed:
                print("認証が失敗しました。 >> because user failed to provide valid credentials.")
            case .userCancel:
                print("「キャンセル」ボタンが押されました。")
            case .userFallback:
                print("「フォールバック (パスワードを入力)」ボタンが押されました。")
            case .systemCancel:
                print("システムによってキャンセルされました。")
            case .passcodeNotSet:
                print("パスコードが未設定です。")
            case .biometryNotEnrolled:
                print("生体情報が未登録です。")
            case .biometryNotAvailable:
                print("生体センサーが無効です。")
            case .biometryLockout:
                print("現在、生体センサーがロックアウト状態です。")
            default:
                print("その他: \(error.self)")
            }
            print(error.localizedDescription)
        }
    }

}

