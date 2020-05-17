//
//  SignInViewController.swift
//  SwiftUIAmplifyDemo
//
//  Created by Victor Rolando Sanchez Jara on 3/19/20.
//  Copyright © 2020 Victor Rolando Sanchez Jara. All rights reserved.
//

import SwiftUI
import AWSMobileClient

struct SignInViewController: UIViewControllerRepresentable {
    @ObservedObject var settings: AppSettings
    
    let navController =  UINavigationController()
    
    func makeUIViewController(context: Context) -> UINavigationController {
        navController.setNavigationBarHidden(true, animated: false)
        let viewController = UIViewController()
        navController.addChild(viewController)
        return navController
    }
    
    func updateUIViewController(_ pageViewController: UINavigationController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SignInViewController
        
        init(_ loginViewController: SignInViewController) {
            self.parent = loginViewController
        }
    }
    
    
}

// MARK: Sign In With Social Providers Extension
extension SignInViewController {
    func signInWithGoogle() {
        signInWithIdentityProvider(with: "Google")
    }
    
    func signInWithFacebook() {
        signInWithIdentityProvider(with: "Facebook")
    }
    
    func signInWithApple() {
        signInWithIdentityProvider(with: "SignInWithApple")
    }
    
    func signInWithIdentityProvider(with provider: String) {
        let hostedUIOptions = HostedUIOptions(scopes: ["openid", "email", "profile"], identityProvider: provider)

        AWSMobileClient.default().showSignIn(navigationController: navController, hostedUIOptions: hostedUIOptions) { (userState, error) in
            if let error = error as? AWSMobileClientError {
                print(error)
                print(error.localizedDescription)
            }
            if let userState = userState {
                print("Status: \(userState.rawValue)")
                
                self.getTokens { claims in
                    if let username = claims?["email"] as? String {
                        DispatchQueue.main.async {
                            self.settings.username = username
                        }
                    }
                    
                    if provider == "Facebook", let picture = claims?["picture"], let pictureJsonStr = picture as? String, let fbPictureURL = self.parseFBImage(from: pictureJsonStr) {
                        print("Do something with fbPictureURL: ", fbPictureURL)
                    } else if provider == "SignInWithApple" {
                        print("Ignore Apple's Picture")
                    }
                }
                
            }
            
        }
    }
    
    func getTokens(closure: @escaping ([String : AnyObject]?) -> ()) {
        AWSMobileClient.default().getTokens { (tokens, error) in
            if let error = error {
                print("error \(error)")
            } else if let tokens = tokens {
                let claims = tokens.idToken?.claims
                print("username? \(claims?["username"] as? String ?? "No username")")
                print("cognito:username? \(claims?["cognito:username"] as? String ?? "No cognito:username")")
                print("email? \(claims?["email"] as? String ?? "No email")")
                print("name? \(claims?["name"] as? String ?? "No name")")
                print("picture? \(claims?["picture"] as? String ?? "No picture")")
                
                closure(claims)
                
            }
        }
    }
    
    func parseFBImage(from jsonStr: String) -> String? {
        let decoder = JSONDecoder()
        guard let jsonData = jsonStr.data(using: .utf8) else {
            print("Could not get data")
            return nil
        }
        if let fbImage = try? decoder.decode(FBImage.self, from: jsonData) {
            let fbImageData = fbImage.data
            let urlString = fbImageData.url
            print("urlString \(urlString)")
            return urlString
            
        } else {
            print("error decoding")
            return nil
        }
    }
    
    struct FBImage: Codable {
        var data: FBImageData
    }
    
    struct FBImageData: Codable {
        var height: Int
        var width: Int
        var is_silhouette: Bool
        var url: String
    }

}

// MARK: Sign In WithEmail Extension
extension SignInViewController {
    func signUpWithEmail(name: String, email: String, password: String) {
        // Since we don't have a username when signing up with Email, use the email as a username
        let username = email
        AWSMobileClient.default().signUp(username: username, password: password, userAttributes: ["email":email, "name": name, "picture": ""]) { (signUpResult, error) in
            if let error = error as? AWSMobileClientError {
                print("error : \(error)")
                print("error localizedDescription : \(error.localizedDescription)")
            } else if let signUpResult = signUpResult {
                switch(signUpResult.signUpConfirmationState) {
                    case .confirmed:
                        print("User is signed up and confirmed.")
                    case .unconfirmed:
                        print("User is not confirmed and needs verification via \(signUpResult.codeDeliveryDetails!.deliveryMedium) sent at \(signUpResult.codeDeliveryDetails!.destination!)")
                        DispatchQueue.main.async {
                            self.settings.emailNeedsConfirmation = username
                        }
                    case .unknown:
                        print("Unexpected case")
                }
            }
        }
    }
    
    func confirmSignUpEmail(email: String, code: String) {
        let username = email
        AWSMobileClient.default().confirmSignUp(username: username, confirmationCode: code) { (confirmationResult, error) in
            if let error = error  as? AWSMobileClientError {
                print("error : \(error)")
                print("error localizedDescription: \(error.localizedDescription)")
            } else if let confirmationResult = confirmationResult {
                switch(confirmationResult.signUpConfirmationState) {
                    case .confirmed:
                        print("User is signed up and confirmed.")
                        DispatchQueue.main.async {
                            self.settings.emailNeedsConfirmation = ""
                        }
                    case .unconfirmed:
                        print("User is not confirmed and needs verification via \(confirmationResult.codeDeliveryDetails!.deliveryMedium) sent at \(confirmationResult.codeDeliveryDetails!.destination!)")
                    case .unknown:
                        print("Unexpected case")
                }
            }
        }
    }
    
    func signInWithEmail(email: String, password: String){
        let username = email
        print("Sign in with Email")
        
        AWSMobileClient.default().signIn(username: username, password: password) { (signInResult, error) in
            if let error = error as? AWSMobileClientError {
                print("error : \(error)")
                print("error localizedDescription: \(error.localizedDescription)")
            } else if let signInResult = signInResult {
                switch (signInResult.signInState) {
                    case .signedIn:
                        print("User is signed in.")
                        
                        self.getTokens { claims in
                            if let username = claims?["email"] as? String {
                                DispatchQueue.main.async {
                                    self.settings.username = username
                                }
                            }
                        }
                    case .smsMFA:
                        print("SMS message sent to \(signInResult.codeDetails!.destination!)")
                    default:
                        print("Sign In needs info which is not yet supported.")
                }
            }
        }
    }

}
