//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import FirebaseAuth
import SwiftUI

@available(iOS 15.0, *)
struct AuthenticationLoginScreen: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @Environment(\.dismiss) var dismiss
    
    /// A boolean that can be toggled to give focus to the password text field.
    /// This must be manually set back to `false` when the text field finishes editing.
    @State private var isPasswordFocused = false
    @State private var isShowingSheet = false
    var otpViewModel = OTPViewModel()

    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationLoginViewModel.Context
    
    @State var selectedCountry: PhoneNumberCountryDefinition? = PhoneNumberCountryDefinition(iso2: "KZ", name: "Kazakhstan", prefix: "7")

    @State private var searchText = ""
    @State var phoneNumberText = ""
    
    var сountryPicker: some View {
        Picker(selection: $selectedCountry, label: Text("")) {
            ForEach(filteredCountries) { country in
                HStack {
                    Text(getEmojiFlag(countryCode: country.iso2))
                        .font(.system(size: 30))
                    Text(country.name)
                    Spacer()
                    Text("(+\(country.prefix))")
                        .font(.caption)
                        .font(.system(size: 24))
                }
                .tag(country)
            }
        }
        .pickerStyle(WheelPickerStyle())
    }

    private var filteredCountries: [PhoneNumberCountryDefinition] {
        if searchText.isEmpty {
            return COUNTRIES
        } else {
            return COUNTRIES.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.prefix.localizedCaseInsensitiveContains(searchText) }
        }
    }

    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.bottom, 28)
                
//                serverInfo
//                    .padding(.leading, 12)
//                    .padding(.bottom, 16)
                
//                Rectangle()
//                    .fill(theme.colors.quinaryContent)
//                    .frame(height: 1)
//                    .padding(.bottom, 22)
                
                if viewModel.viewState.homeserver.showLoginForm {
                    loginForm
                }
                
//                if viewModel.viewState.homeserver.showLoginForm && viewModel.viewState.showSSOButtons {
//                    Text(VectorL10n.or)
//                        .foregroundColor(theme.colors.secondaryContent)
//                        .padding(.top, 16)
//                }
                
//                if viewModel.viewState.showSSOButtons {
//                    ssoButtons
//                        .padding(.top, 16)
//                }

                if !viewModel.viewState.homeserver.showLoginForm && !viewModel.viewState.showSSOButtons {
                    fallbackButton
                }
                
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
        .fullScreenCover(isPresented: $isShowingSheet) {
            if #available(iOS 15.0, *) {
                OTPView(dismissAction: {
                    isShowingSheet = false
                    guard viewModel.viewState.canSubmit else { return }
                    viewModel.send(viewAction: .next)
                    
                }, getOTPAction: {
                    otpViewModel.requestOtp(phoneNumber: viewModel.username) {
                        (verificationID, error) in
                        if let error = error {
                            DispatchQueue.main.async {
                                let authError = error as NSError?
                                print(authError?.code)
                            }
                            return
                        }
                        if let verificationId = verificationID {
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(verificationId, forKey: "verificationId")
                            }
                        }
                    }
                })
            } else {
               
            }
            }
    }
    
    /// The header containing a Welcome Back title.
    var header: some View {
        Text(VectorL10n.authenticationLoginTitle)
            .font(theme.fonts.title2B)
            .multilineTextAlignment(.center)
            .foregroundColor(theme.colors.primaryContent)
    }
    
    /// The sever information section that includes a button to select a different server.
    var serverInfo: some View {
        AuthenticationServerInfoSection(address: viewModel.viewState.homeserver.address,
                                        flow: .login) {
            viewModel.send(viewAction: .selectServer)
        }
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8){
                HStack(spacing: 8){
                    RoundedBorderTextField(placeHolder: VectorL10n.searchDefaultPlaceholder, text: $searchText)
                        .padding(.bottom, 7)
                        .frame(width: UIScreen.main.bounds.width / 3)
                    
                    RoundedBorderTextField(placeHolder: VectorL10n.settingsPhoneNumber,
                                           text: $phoneNumberText,
                                           isFirstResponder: false,
                                           configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                                      autocapitalizationType: .none,
                                                                                      autocorrectionType: .no),
                                           onTextChanged: { newText in
                        viewModel.username = "+\(selectedCountry?.prefix ?? "")" + newText
                        print(viewModel.username)
                                           },
                                           onEditingChanged: usernameEditingChanged,
                                           onCommit: { isPasswordFocused = true })
                    .accessibilityIdentifier("usernameTextField")
                    .padding(.bottom, 7)
                }
                
                сountryPicker
            }
            
//            RoundedBorderTextField(placeHolder: VectorL10n.authPasswordPlaceholder,
//                                   text: $viewModel.password,
//                                   isFirstResponder: isPasswordFocused,
//                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
//                                                                              isSecureTextEntry: true),
//                                   onEditingChanged: passwordEditingChanged,
//                                   onCommit: submit)
//            .accessibilityIdentifier("passwordTextField")
            
            
            Button(action: submit) {
                Text(VectorL10n.next)
            }
            
            .buttonStyle(PrimaryActionButtonStyle(customColor: .purple))
            .disabled(!viewModel.viewState.canSubmit)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// A list of SSO buttons that can be used for login.
    var ssoButtons: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.viewState.homeserver.ssoIdentityProviders) { provider in
                AuthenticationSSOButton(provider: provider) {
                    viewModel.send(viewAction: .continueWithSSO(provider))
                }
                .accessibilityIdentifier("ssoButton")
            }
        }
    }

    /// A fallback button that can be used for login.
    var fallbackButton: some View {
        Button(action: fallback) {
            Text(VectorL10n.login)
        }
        .buttonStyle(PrimaryActionButtonStyle(customColor: .purple))
        .accessibilityIdentifier("fallbackButton")
    }
    
    /// Parses the username for a homeserver.
    func usernameEditingChanged(isEditing: Bool) {
        guard !isEditing, !viewModel.username.isEmpty else { return }
        
        viewModel.send(viewAction: .parseUsername)
    }
    
    /// Resets the password field focus.
    func passwordEditingChanged(isEditing: Bool) {
        guard !isEditing else { return }
        isPasswordFocused = false
    }
    
    /// Sends the `next` view action so long as the form is ready to submit.
    func submit() {
        otpViewModel.requestOtp(phoneNumber: viewModel.username) { verificationID, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Error: \(error.localizedDescription)")
                    let authError = error as NSError
                    print(authError.code)
                }
                return
            }
            if let verificationId = verificationID {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(verificationId, forKey: "verificationId")
                    isShowingSheet = true
                }
            }
        }
    }

    /// Sends the `fallback` view action.
    func fallback() {
        viewModel.send(viewAction: .fallback)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct AuthenticationLogin_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationLoginScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
