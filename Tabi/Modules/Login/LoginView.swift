//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct LoginView: View {
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
                               placeholder: "(+62)")
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Password",
                               placeholder: "Password")
                
                Text("Forgot Password?")
                    .font(.system(size: 10))
                    .padding(.horizontal)
                    .padding(.top, 10)
            }
            
            Spacer()
                .frame(height: 60)
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: .infinity,height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal)
                .overlay(
                    Text("Login")
                )
            
            Text("Or")
                .padding(.vertical, 12)
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: .infinity,height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal)
                .overlay(
                    Text("Apple")
                )
            
            Text("Don't have an account? Register")
                .font(.system(size: 12))
                .padding(.top, 20)
            
            Spacer()
            Spacer()
            
        }
    }
}

#Preview {
    LoginView()
}
