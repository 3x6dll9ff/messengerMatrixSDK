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
import Foundation
import FirebaseAuth
import Firebase
import UIKit

/// The form shown to enter an OTP for phone number vaildation
struct OTPView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isEditingTextField = false
    @State private var otp = ""
    var dismissAction: (() -> Void)
    var getOTPAction: (() -> Void)
    @State private var verificationId = UserDefaults.standard.string(forKey: "verificationId")
    @State var otpViewModel = OTPViewModel()
    
    // MARK: Public

    
    // MARK: Views
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                .padding(.bottom, 36)
            
            mainContent
                .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                .padding(.bottom, 36)
        }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationMsisdnIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationVerifyMsisdnWaitingTitle)
                .font(theme.fonts.title3SB)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text("Код был отправлен на ваш номер")
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("messageLabel")
        }
    }
    
    /// The text field and submit button where the user enters an OTP.
    var mainContent: some View {
        return VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 15.0, *) {
                textField
                    .onSubmit(submitOTP)
            } else {
                textField
            }

            Button {
                getOTPAction()
                verificationId = UserDefaults.standard.string(forKey: "verificationId")
 } label: {
                Text(VectorL10n.authenticationVerifyMsisdnWaitingButton)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("resendButton")
            .padding(.bottom, 26)
            .foregroundColor(.purple)

            Button(action: submitOTP) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: .purple))
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// The text field, extracted for iOS 15 modifiers to be applied.
    var textField: some View {
        return TextField("Введите код", text: $otp) {
            isEditingTextField = $0
        }
        .textFieldStyle(BorderedInputFieldStyle(isEditing: isEditingTextField, isError: false))
        .keyboardType(.decimalPad)
        .disableAutocorrection(true)
        .accessibilityIdentifier("otpTextField")
    }
    
    /// Sends the `submitOTP` view action so long as a valid OTP has been input.
    func submitOTP() {
        if otp.count == 6 {
            let verificationID = verificationId!
            otpViewModel.verifyOtp(verificationId: verificationID, verificationCode: otp) {  (authResult, error) in
                if let error = error {
                    let authError = error as NSError
                    print(authError)
                    return
                    }
                dismissAction()
                }
                
        } else {
            print("not enough numbers")
        }
    }
        
}


