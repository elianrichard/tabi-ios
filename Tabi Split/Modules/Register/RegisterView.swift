//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct RegisterView: View {
    @Environment(Routes.self) private var routes
    @State private var registerViewModel = RegisterViewModel()
    
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Register")
                    .font(.system(size: 22, weight: .medium))
                    .padding()
                
                InputWithLabel(label: "Name",
                               placeholder: "Name",
                               text: $registerViewModel.name)
                .onSubmit(registerViewModel.validateName)
                if registerViewModel.hasAttemptedValidation, let error = registerViewModel.nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Phone Number",
                               placeholder: "(+62)",
                               text: $registerViewModel.phoneNumber)
                .onSubmit(registerViewModel.validatePhoneNumber)
                if registerViewModel.hasAttemptedValidation, let error = registerViewModel.phoneNumberError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Password",
                               placeholder: "Password",
                               isSecure: true,
                               text: $registerViewModel.password)
                .onSubmit(registerViewModel.validatePassword)
                if registerViewModel.hasAttemptedValidation, let error = registerViewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Confirm Password",
                               placeholder: "Confirm Password",
                               isSecure: true,
                               text: $registerViewModel.confirmPassword)
                if !registerViewModel.confirmPassword.isEmpty, let error = registerViewModel.confirmPasswordError {
                    HStack {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
                        
                        Text(error)
                            .foregroundColor(.red)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
                .frame(height: 60)
            
            Button(action: {
                registerViewModel.validateAllFields()
                if registerViewModel.isFormValid() {
                    registerViewModel.register()
                }
            }) {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(registerViewModel.hasAttemptedValidation && registerViewModel.isFormValid() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal)
            
            Button(action: {
                routes.navigate(to: .LoginView)
            }) {
                Text("Already have an account? Login")
                    .font(.system(size: 12))
                    .padding(.top, 20)
                    .foregroundStyle(.black)
                    .underline()
            }
            
            Spacer()
            Spacer()
            
        }
    }
}

#Preview {
    RegisterView()
}
