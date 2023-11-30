//swiftlint:disable all

//Developed by Patched && Boris

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK
import DesignKit
import MobileCoreServices

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
private func uploadFile(fileData: Data, mimeType: String) async -> String {
    print(fileData)
    
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    do {
        let (data, response) = try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { multipart in
                    multipart.append(fileData, withName: "file", fileName: "test", mimeType: mimeType )
                },
                to: "\(baseURL)/files/upload",
                method: .post,
                headers: headers
            ).responseData { response in
                switch response.result {
                case .success(let data):
                    continuation.resume(returning: (data, response.response))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Обработка статуса ответа
        print("Status Code: \(response?.statusCode ?? -1)")
        
        // Обработка JSON-ответа
        if let jsonString = String(data: data ?? Data(), encoding: .utf8) {
            print("JSON Response: \(jsonString)")
        }
        
        // Возвращаем UUID из ответа (предположим, что у вас есть структура FileResponse с свойством uuid)
        let decodedResponse = try JSONDecoder().decode(FileResponse.self, from: data ?? Data())
        return decodedResponse.uuid
    } catch {
        // Обработка ошибок
        print("Error: \(error)")
        return ""
    }
}

@available(iOS 13.0.0, *)
private func uploadFileAvatar(fileUuid: String, matrixId: String) async {
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
                print("Request URL: \(response.request?.url?.absoluteString ?? "")")
                print("Request Headers: \(response.request?.allHTTPHeaderFields ?? [:])")
                print("Response Status Code: \(response.response?.statusCode ?? -1)")
                print("Response Data: \(String(data: response.data ?? Data(), encoding: .utf8) ?? "")")

            
    
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
    var colors: ColorsUIKit = DarkColors.uiKit
    
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
        Text("Загрузка аватара")
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
                                    .foregroundColor(Color(colors.accent))
                                Text("Из галереи")
                                    .foregroundColor(Color(colors.accent))
                            }
                        }
                        .padding(.vertical, 6)
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$selectedImage)
                        }
                        .onChange(of: selectedImage) { newImage in
                                Task {
                                    do {
                                        _ = try await login()

                                        let mainAccount = MXKAccountManager.shared().accounts.first

                                        guard let userID = mainAccount?.mxSession.myUser.userId else {
                                            return
                                        }

                                        let matrixId = userInfo.userId
                                      
                                        
                                        if let imageData = newImage.jpegData(compressionQuality: 0.8) {
                                            if let mimeType = getMimeType(from: imageData) {
                                                print("MIME Type: \(mimeType)")
                                                let fileUuid = try await uploadFile(fileData: imageData, mimeType: "\(mimeType)")
                                                let uploadedAvatarUUID = try await uploadFileAvatar(fileUuid: fileUuid, matrixId: userID)
                                            } else {
                                                print("Failed to determine MIME Type.")
                                            }
                                        } else {
                                            print("Failed to create JPEG data.")
                                        }
                                    } catch {
                                        print("Error: \(error)")
                                    }
                                }
                            
                        }
            Button(action: {
                showDocumentPicker = true
            }){
                HStack {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(Color(colors.accent))
                    Text("Из файлов")
                        .foregroundColor(Color(colors.accent))
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
    
    
func getMimeType(from data: Data) -> String? {
    var result: String?
    let uti = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        "jpeg" as CFString,
        nil
    )?.takeRetainedValue()

    if let uti = uti {
        let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
        result = mimeType as String?
    }

    return result
}
