//swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK


private var accessToken: String = ""

struct AvatarResponse: Decodable {
    let uuid: String
    let fileUuid: String
    let matrixId: String
    
}

@available(iOS 13.0.0, *)
private func login() async -> String {
    
    let params: [String: Any] = [
        "username": userInfo.phoneNumber,
        "password": "12345678",
        "fingerprint": "fingerprint"
    ]
    
    let token = try? await AF.request(
        "\(baseURL)/auth/login",
        method: .post,
        parameters: params
    ).serializingDecodable(LoginResponse.self).value.access_token
    
    if(token == nil){
        return await login()
    }
    
    accessToken = token!
    return token!
}

@available(iOS 13.0.0, *)
private func uploadFile(fileUuid: String, matrixId: String) async -> String {
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    let parameters: Parameters = [
        "fileUuid": fileUuid,
        "matrixId": matrixId
    ]
    
    do {
        let response = try await AF.request(
            "\(baseURL)/avatars",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        ).responseDecodable(of: AvatarResponse.self)

        return try await withCheckedThrowingContinuation { continuation in
            switch response.result {
            case .success(let avatarResponse):
                let uuid = avatarResponse.uuid
                print("Avatar UUID: " + uuid)
                continuation.resume(returning: uuid)

            case .failure(let error):
                print("Error uploading avatar: \(error)")
                continuation.resume(returning: "Unknown UUID")
            }
        }
        
    } catch {
        print("Error uploading avatar: \(error)")
        // Handle the error as needed (e.g., show an error message to the user)
        return "Unknown UUID"
    }
}


@available(iOS 15.0, *)
struct UploadAvatarView: View{
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showContacts = false
    @State private var selectedImage = UIImage()
    @State private var selectedURL: URL?
    @State private var uploadProgress: Double = 0.0
    @Environment(\.colorScheme) var colorScheme
    
    
    let periods = [30]
    
    private func fetch() {
        
        let mainAccount = MXKAccountManager.shared().accounts.first
        
        if let userId = mainAccount?.mxSession.myUser.userId {
            userInfo.userId = userId
        }
        if let email = mainAccount?.linkedEmails.first {
            userInfo.email = email
        }
        if let phoneNumber = mainAccount?.linkedPhoneNumbers.first {
            userInfo.phoneNumber = phoneNumber
        }
        
    }
    
    var body: some View{
        Text("Отправка файла в облако")
            .font(.title)
            .bold()
            .padding(.top, 16)
        Spacer()
        VStack (alignment: .center){
            Text("Отправить:")
                .font(.subheadline)
                .bold()
                .foregroundColor(.gray)
                .padding(.vertical, 8)

            Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Из галереи")
                            }
                        }
                        .padding(.vertical, 6)
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$selectedImage)
                        }
                        .onChange(of: selectedImage) { newImage in
                            if newImage != nil {
                                // Call the uploadFile function with the selected image
                                Task {
                                    let imageData = newImage.jpegData(compressionQuality: 0.8)
                                    let base64String = imageData?.base64EncodedString() ?? ""
                                    
                                    let fileUuid = UUID().uuidString
                                    let matrixId = userInfo.userId  // or use the appropriate user identifier

                                    let uploadedAvatarUUID = await uploadFile(fileUuid: fileUuid, matrixId: matrixId)
                                    
                                    // Handle the uploadedAvatarUUID as needed
                                }
                            }
                        }

            
            Button(action: {
                showDocumentPicker = true
            }){
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("Из файлов")
                }
            }
            .padding(.vertical, 6)
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(selectedURL: $selectedURL)
            }
        }
        Spacer()
    }
    }
    
    
