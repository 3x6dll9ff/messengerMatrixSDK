//
//  OTPViewModel.swift
//  MirrorflyUIkit
//
//  Created by User on 24/08/21.
//

import Foundation
import FirebaseAuth
class OTPViewModel : NSObject
{
    
    func requestOtp(phoneNumber: String, completionHandler:  @escaping (String?, Error?)-> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            completionHandler(verificationID,error)
        }
    }
    
    func verifyOtp(verificationId: String, verificationCode: String, completionHandler:  @escaping (AuthDataResult?, Error?)-> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            completionHandler(authResult, error)
        }
    }
    
}

