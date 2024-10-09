//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct LoginView: View {
    
    @State private var vm = LoginViewModel()
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Login")
                    .font(.system(size: 22, weight: .medium))
                    .padding()
                
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Phone Number",
                               placeholder: "+62",
                               text: $vm.phoneNumber)
                
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Password",
                               placeholder: "Password",
                               isSecure: true,
                               text: $vm.password)
                
                Text("Forgot Password?")
                    .font(.system(size: 10))
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            Spacer()
                .frame(height: 60)
            
            Button(action: vm.login) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal)
            
            Text("Or")
                .padding(.vertical, 12)
            
            Button(action: {}) {
                Text("Apple")
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal)
            
            Text("Don't have an account? Register")
                .font(.system(size: 12))
                .padding(.top, 20)
                .underline()
            
            Spacer()
            Spacer()
            
        }
    }
}

#Preview {
    LoginView()
}
