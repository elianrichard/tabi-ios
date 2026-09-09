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
    @Environment(Router.self) var router
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
                        Icon(systemName: "square.and.pencil", color: .textBlack, size: 16) {
                            router.push(.editProfile)
                        }
                    }
                }
                
                // TEMPORARILY DISABLED: EXPORT / IMPORT DATA
                if false {
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
                }

                
                // Guests get the full profile like a signed-in user, plus an
                // upgrade prompt: signing in with Google/Apple links a real account
                // and (Phase 5) merges the guest's data into it.
                if profileViewModel.isGuest {
                    VStack (spacing: .spacingMedium) {
                        Image(.initialOnboarding)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)
                        Text("Sign in to keep your events and expenses safe across devices.")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        CustomButton(text: "Sign In", type: .tertiary, iconResource: .logout) {
                            router.push(.login)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: .spacingTight) {
                        //                    TEMPORARILY DISABLED: PAYMENT METHOD
                        if (false) {
                            Text("Settings")
                                .font(.tabiBody)
                            Button {
                                router.push(.paymentMethods)
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
                        // Guests have no way back into their account, so Log Out
                        // would silently destroy their data. They upgrade via the
                        // "Sign In" prompt above instead; only real accounts log out.
                        if !profileViewModel.isGuest {
                            Button {
                                Task {
                                    let isSuccess = await profileViewModel.logout()

                                    if isSuccess {
                                        // Swap the stack root back to LoginView and
                                        // clear the path so Home is gone and Back
                                        // cannot return into the authed area.
                                        SessionState.shared.isAuthenticated = false
                                        router.popToRoot()
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
            ShareSheet(items: [url]) {
                // Dismiss the hosting sheet too — a cancel inside the activity
                // controller does not clear `exportURL` on its own.
                exportURL = nil
            }
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    ProfileView()
        .environment(Router())
        .environment(ProfileViewModel())
}
