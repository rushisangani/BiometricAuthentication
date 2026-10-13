//
//  LoginView.swift
//  SwiftUI
//
//  Copyright © 2026 Rushi Sangani. All rights reserved.
//

import SwiftUI

struct LoginView: View {

    private enum Field {
        case username, password
    }

    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 16) {
            Text("BiometricAuthentication")
                .font(.title2.bold())
                .padding(.bottom, 24)

            TextField("Username", text: $viewModel.username)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .textFieldStyle(.roundedBorder)

            Button {
                focusedField = nil
                viewModel.login()
            } label: {
                Text("Login")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                focusedField = nil
                Task { await viewModel.authenticateWithBiometrics() }
            } label: {
                Label(viewModel.biometricButtonTitle, systemImage: viewModel.biometricButtonImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 480)
        .onChange(of: viewModel.focusUsername) { _, focus in
            guard focus else { return }
            focusedField = .username
            viewModel.focusUsername = false
        }
        .alert(viewModel.alert?.title ?? "", isPresented: isPresentingAlert, presenting: viewModel.alert) { alert in
            if alert.showsSettings {
                Button("Go to settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK") {}
            }
        } message: { alert in
            Text(alert.message)
        }
    }

    private var isPresentingAlert: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { if !$0 { viewModel.alert = nil } }
        )
    }
}

#Preview {
    LoginView()
}
