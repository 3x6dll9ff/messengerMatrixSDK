//swiftlint:disable all

//Developed by Patched && Boris

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK


private var accessToken: String = ""
private var showIcon = false

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
private func uploadFile(fileUuid: String, matrixId: String) async {
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    let parameters: Parameters = [
        "fileUuid": fileUuid,
        "matrixId": matrixId
    ]
    
    do {
        let response = AF.request(
            "\(baseURL)/avatars",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        ).response { response in
            switch response.result {
            case .success(let avatarResponse):
                showIcon = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                       showIcon = false
                                   }
                print("Avatar response: \(response.data?.jsonString)")
            
    
            case .failure(let error):
                print("Error uploading avatar: \(error)")
                showIcon = false
            }
        }
        
    } catch {
        print("Error uploading avatar: \(error)")
        showIcon = false
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
        
        LottieViewAnimation(lottieFile: "UploadComplete")
                      .frame(width: 150, height: 150)
                      .padding()
                      .opacity(showIcon ? 1.0 : 0.0)
        
        
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
                          
                                Task {
                                    let imageData = newImage.jpegData(compressionQuality: 0.8)
                                    let base64String = imageData?.base64EncodedString() ?? ""
                                    
                                    let fileUuid = UUID().uuidString
                                    let matrixId = userInfo.userId 

                                    let uploadedAvatarUUID = await uploadFile(fileUuid: fileUuid, matrixId: matrixId)
                                    
                              
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
        .opacity(showIcon ? 0.0 : 1.0)
        Spacer()
    }
    }
    
    
