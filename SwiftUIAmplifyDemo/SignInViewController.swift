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

// MARK: Sign In With Google Extension
extension SignInViewController {
    func signInWithGoogle() {
        signInWithIdentityProvider(with: "Google")
    }
    
    func signInWithFacebook() {
        signInWithIdentityProvider(with: "Facebook")
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
                        
                        if let username = claims?["email"] as? String {
                            DispatchQueue.main.async {
                                self.settings.username = username
                            }
                        }
                        
                        if provider == "Facebook", let picture = claims?["picture"], let pictureJsonStr = picture as? String, let fbPictureURL = self.parseFBImage(from: pictureJsonStr) {
                            print("Do something with fbPictureURL: ", fbPictureURL)
                        }
                    }
                }
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
