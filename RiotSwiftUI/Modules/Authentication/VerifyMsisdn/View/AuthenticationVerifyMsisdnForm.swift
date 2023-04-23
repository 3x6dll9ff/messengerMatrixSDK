//
// Copyright 2022 New Vector Ltd
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

import SwiftUI

/// The form shown to enter an email address.
struct AuthenticationVerifyMsisdnForm: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isEditingTextField = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyMsisdnViewModel.Context
    
    @State private var selectedCountry: PhoneNumberCountryDefinition = COUNTRIES[0]

    @State private var searchText = ""
    @State var phoneNumberText = ""
    
    @State var сountries: [PhoneNumberCountryDefinition] = COUNTRIES
    
    var сountryPicker: some View {
        Picker(selection: $selectedCountry, label: Text("")) {
            ForEach(сountries) { country in
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
        VStack(spacing: 0) {
            header
                .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                .padding(.bottom, 36)
            
            mainContent
        }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationMsisdnIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationVerifyMsisdnInputTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text(viewModel.viewState.formHeaderMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("messageLabel")
        }
    }
    
    /// The text field and submit button where the user enters a phone number.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 15.0, *) {
                textField
                    .onSubmit(sendSMS)
            } else {
                textField
            }

            Button(action: sendSMS) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasInvalidPhoneNumber)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// The text field, extracted for iOS 15 modifiers to be applied.
    var textField: some View {
        VStack(spacing: 8){
            HStack(spacing: 8){
                ZStack(alignment: .leading) {
                    Text("\(getEmojiFlag(countryCode: selectedCountry.iso2)) +\(selectedCountry.prefix)")
                        .frame(height: 30)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.colors.background))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.colors.quinaryContent, lineWidth: 1))
                }
                .padding(.bottom, 7)
                
                RoundedBorderTextField(placeHolder: VectorL10n.settingsPhoneNumber,
                                       text: $phoneNumberText,
                                       isFirstResponder: false,
                                       configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                                  autocapitalizationType: .none,
                                                                                  autocorrectionType: .no),
                                       onTextChanged: { newText in
                    viewModel.phoneNumber = "+\(selectedCountry.prefix)" + newText
                    print(viewModel.phoneNumber)
                                       })
                .accessibilityIdentifier("usernameTextField")
                .padding(.bottom, 7)
            }
            
            сountryPicker
        }
    }
    
    /// Sends the `send` view action so long as a valid phone number has been input.
    func sendSMS() {
        guard !viewModel.viewState.hasInvalidPhoneNumber else { return }
        viewModel.send(viewAction: .send)
    }
}
