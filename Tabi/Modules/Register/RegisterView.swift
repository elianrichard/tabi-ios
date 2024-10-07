//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct RegisterView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Register")
                    .font(.system(size: 22, weight: .medium))
                    .padding()
                
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Name",
                               placeholder: "Name")
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Phone Number",
                               placeholder: "(+62)")
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Password",
                               placeholder: "Password")
                
                Spacer()
                    .frame(height: 20)
                
                InputWithLabel(label: "Confirm Password",
                               placeholder: "Confirm Password")
                
                HStack{
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 12))
                    
                    Text("Password doesn’t match")
                        .font(.system(size: 12))
                }
                .padding(.horizontal)
                .padding(.top, 4)

            }
            
            Spacer()
                .frame(height: 60)
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: .infinity,height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal)
                .overlay(
                    Text("Register")
                )
            
            Text("Already have an account? Login")
                .font(.system(size: 12))
                .padding(.top, 20)
            
            Spacer()
            Spacer()
            
        }
    }
}

#Preview {
    RegisterView()
}
