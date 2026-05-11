//
//  ProfileView.swift
//  Tabi Split
//
//  Created by Dharmawan Ruslan on 29/10/24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(Routes.self) var routes
    @Environment(ProfileViewModel.self) private var profileViewModel

    @State private var isImporterPresented: Bool = false
    @State private var exportURL: URL?
    @State private var backupAlert: BackupAlert?

    var body: some View {
        VStack{
            TopNavigation(title: "Profile")
            VStack(spacing: .spacingLarge){
                HStack{
                    HStack(alignment: .center, spacing: .spacingTight) {
                        UserCard(user: profileViewModel.user)
                        Spacer()
                        if !profileViewModel.isGuest {
                            Icon(systemName: "pencil", color: .textBlack, size: 16) {
                                routes.navigate(to: .EditProfile)
                            }
                        }
                    }
                }
                
                VStack (spacing: .spacingSmall) {
                    Button {
                        handleExport()
                    } label: {
                        HStack(spacing: .spacingTight){
                            Icon(systemName: "square.and.arrow.up")
                            Text("Export Data")
                                .font(.tabiHeadline)
                                .foregroundStyle(.textBlack)
                            Spacer()
                            Icon(systemName: "chevron.right", size: 16)
                        }
                        .padding(.vertical, .spacingSmall)
                        .contentShape(Rectangle())
                    }
                    Button {
                        isImporterPresented = true
                    } label: {
                        HStack(spacing: .spacingTight){
                            Icon(systemName: "square.and.arrow.down")
                            Text("Import Data")
                                .font(.tabiHeadline)
                                .foregroundStyle(.textBlack)
                            Spacer()
                            Icon(systemName: "chevron.right", size: 16)
                        }
                        .padding(.vertical, .spacingSmall)
                        .contentShape(Rectangle())
                    }
                    Divider()

                }

                
                if profileViewModel.isGuest {
                    VStack (spacing: .spacingLarge) {
                        Image(.initialOnboarding)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                        Text("Let’s register to keep all your events and expenses saved!")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        CustomButton(text: "Sign In", type: .tertiary, iconResource: .logout) {
                            routes.navigate(to: .LoginView)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                                
                if !profileViewModel.isGuest {
                    VStack(alignment: .leading, spacing: .spacingTight) {
                        //                    TEMPORARILY DISABLED: PAYMENT METHOD
                        if (false) {
                            Text("Settings")
                                .font(.tabiBody)
                            Button {
                                routes.navigate(to: .PaymentMethods)
                            } label: {
                                HStack(spacing: .spacingTight){
                                    Icon(systemName: "wallet.bifold")
                                    Text("Payment methods")
                                        .font(.tabiHeadline)
                                        .foregroundStyle(.textBlack)
                                    Spacer()
                                    Icon(systemName: "chevron.right", size: 16)
                                }
                                .padding(.vertical, .spacingSmall)
                                .contentShape(Rectangle())
                            }
                            Divider()
                        }
                        Button {
                            Task {
                                let isSuccess = await profileViewModel.logout()
                                
                                if isSuccess {
                                    routes.navigate(to: .LoginView)
                                }
                            }
                        } label: {
                            HStack(spacing: .spacingTight){
                                Icon(.logout, color: .buttonRed, size: 20)
                                Text("Log Out")
                                    .font(.tabiHeadline)
                                    .foregroundStyle(.buttonRed)
                                Spacer()
                            }
                            .padding(.vertical, .spacingSmall)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding(.spacingMedium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .sheet(item: $exportURL) { url in
            ShareSheet(items: [url])
        }
        .alert(item: $backupAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    private func handleExport() {
        do {
            let url = try BackupService.shared.exportToTemporaryFile()
            exportURL = url
        } catch {
            backupAlert = BackupAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try BackupService.shared.importFromFile(url: url)
                backupAlert = BackupAlert(title: "Import Complete", message: "Data restored from backup.")
            } catch {
                backupAlert = BackupAlert(title: "Import Failed", message: error.localizedDescription)
            }
        case .failure(let error):
            backupAlert = BackupAlert(title: "Import Failed", message: error.localizedDescription)
        }
    }
}

private struct BackupAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
        .environment(Routes())
        .environment(ProfileViewModel())
}
