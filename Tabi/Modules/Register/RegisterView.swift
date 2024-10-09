//
//  LoginView.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var routes: Routes
    @State private var vm = RegisterViewModel()
    
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Register")
                    .font(.system(size: 22, weight: .medium))
                    .padding()
                
                InputWithLabel(label: "Name",
                               placeholder: "Name",
                               text: $vm.name)
                .onSubmit(vm.validateName)
                if vm.hasAttemptedValidation, let error = vm.nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Phone Number",
                               placeholder: "(+62)",
                               text: $vm.phoneNumber)
                .onSubmit(vm.validatePhoneNumber)
                if vm.hasAttemptedValidation, let error = vm.phoneNumberError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Password",
                               placeholder: "Password",
                               isSecure: true,
                               text: $vm.password)
                .onSubmit(vm.validatePassword)
                if vm.hasAttemptedValidation, let error = vm.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                InputWithLabel(label: "Confirm Password",
                               placeholder: "Confirm Password",
                               isSecure: true,
                               text: $vm.confirmPassword)
                if !vm.confirmPassword.isEmpty, let error = vm.confirmPasswordError {
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
                vm.validateAllFields()
                if vm.isFormValid() {
                    vm.register()
                }
            }) {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(vm.hasAttemptedValidation && vm.isFormValid() ? Color.blue : Color.gray)
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
