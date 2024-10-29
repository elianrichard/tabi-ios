//
//  ProfileView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 29/10/24.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @Environment(Routes.self) var routes
    
    var body: some View {
        VStack{
            TopNavigation(title: "Profile")
            
            VStack(spacing: UIConfig.Spacing.Large){
                HStack{
                    HStack(alignment: .center, spacing: UIConfig.Spacing.Small){
                        Circle()
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading){
                            Text("User Name")
                                .font(.tabiSubtitle)
                            Text("0821212121")
                                .font(.tabiBody)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                            .frame(width: 22)
                    }
                }
                
                VStack(spacing: UIConfig.Spacing.Small){
                    HStack(spacing: UIConfig.Spacing.Small){
                        Image(systemName: "creditcard")
                            .frame(width: 28, height: 28)
                        Text("Payment methods")
                            .font(.tabiHeadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .frame(width: 24, height: 24)
                    }
                    Divider()
                    HStack(spacing: UIConfig.Spacing.Small){
                        Image(systemName: "creditcard")
                            .frame(width: 28, height: 28)
                        Text("Payment methods")
                            .font(.tabiHeadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .frame(width: 24, height: 24)
                    }
                    Divider()
                    HStack(spacing: UIConfig.Spacing.Small){
                        Image(systemName: "creditcard")
                            .frame(width: 28, height: 28)
                        Text("Payment methods")
                            .font(.tabiHeadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .frame(width: 24, height: 24)
                    }
                    Divider()
                }
            }
        }
        .padding(UIConfig.Spacing.Medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ProfileView()
        .environment(Routes())
}
