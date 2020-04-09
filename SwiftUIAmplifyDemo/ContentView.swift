//
//  ContentView.swift
//  SwiftUIAmplifyDemo
//
//  Created by Victor Rolando Sanchez Jara on 3/18/20.
//  Copyright © 2020 Victor Rolando Sanchez Jara. All rights reserved.
//

import SwiftUI
import AWSMobileClient

struct ContentView: View {
    @ObservedObject var settings = AppSettings()
    
    var body: some View {
        let signInVC = SignInViewController(settings: settings)
        
        return ZStack {
            if settings.username != "" {
                VStack {
                    Text("You are signed in! Welcome!")
                    Divider()
                    Button(action: {
                        AWSMobileClient.default().signOut()
                        self.settings.username = ""
                    }) {
                        Text("Sign Out")
                    }
                }
            } else {
                signInVC
                VStack {
                    Button(action: {
                        signInVC.signInWithGoogle()
                    }) {
                        Text("Sign In with Google")
                    }
                    Divider()
                    Button(action: {
                        signInVC.signInWithFacebook()
                    }) {
                        Text("Sign In with Facebook")
                    }
                    Divider()
                    Button(action: {
                        AWSMobileClient.default().signOut()
                        self.settings.username = ""
                    }) {
                        Text("Sign Out")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
