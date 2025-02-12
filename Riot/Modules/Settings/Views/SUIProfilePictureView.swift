//
// Copyright 2023 New Vector Ltd
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

//
//  SUIProfilePictureView.swift
//
//swiftlint:disable all
//Developed by Patched

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK
import SwiftUI
import DesignKit

private var accessToken: String = ""
//MARK: Model for Avatars
struct AvatarResponseElement: Codable, Hashable, Equatable {
    let uuid: String
    let file: File
    let createdAt: String
}

struct File: Codable, Hashable, Equatable {
    let id: Int
    let uuid, fieldname, originalname, filename: String
    let mimetype, path, destination, encoding: String
    let size: Int
    let createdAt, updatedAt: String
}

typealias AvatarResponse = [AvatarResponseElement]

//MARK: Backend logic

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
private func getAvatars(matrixId: String) async -> [AvatarResponse] {
    let mainAccount = MXKAccountManager.shared().accounts.first
    
    guard let userID = mainAccount?.mxSession.myUser.userId else {
        return []
    }

    let url = "\(baseURL)/avatars?matrixId=\(userID)"

    do {
    
        let avatars: [AvatarResponseElement] = try await withCheckedThrowingContinuation { continuation in
            AF.request(
                url,
                method: .get
            ).responseDecodable(of: [AvatarResponseElement].self) { response in
                switch response.result {
                case .success(let avatars):
                    continuation.resume(returning: avatars)
                case .failure(let error):
                    print("Error fetching avatars: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
        
        print("Avatars: \(avatars)")

        return [avatars]
    } catch {
        print("Error fetching avatars: \(error)")
        return []
    }
}


@available(iOS 13.0.0, *)
private func deleteFileAvatar(Uuid: String) {
    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    do {
        AF.request(
            "\(baseURL)/avatars/\(Uuid)",
            method: .delete,
            encoding: JSONEncoding.default,
            headers: headers
        ).response { response in
            switch response.result {
            case .success(let avatarResponse):
                print("uiid rn : \(Uuid)")
                print("Avatar response: \(response.data?.jsonString)")
                
            case .failure(let error):
                print("Error uploading avatar: \(error)")
            }
        }
    }
    catch{
        print("baaad block")
    }
}

//MARK: Front
@available(iOS 15.0, *)
struct SUIProfilePictureView: View {
    @State private var selectedIndex: Int? = 0
    // переменные для открытия View
    @State private var shouldNavigateAds = false
    @State private var avatars: [AvatarResponseElement] = []
    var colors: ColorsUIKit = DarkColors.uiKit

    var shipName = "User Settings"
    
    var body: some View {
     
        NavigationView {
            VStack {
                VStack {
                    Text("Swipe down to hide")
                     .foregroundColor(.gray)
                     .padding(.top, 15)

             
                }
                
                VStack {
                    Text(shipName)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(.top, 30)
                    Divider()
                    
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(avatars.indices, id: \.self) { index in
                                    AvatarTileView(avatar: avatars[index], isSelected: index == selectedIndex)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedIndex = index
                                                proxy.scrollTo(index, anchor: .center)
                                            }
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                Task {
                                                    do {
                                                        await login()
                                                        deleteFileAvatar(Uuid: avatars[index].uuid)
                                                        let fetchedAvatars = try await getAvatars(matrixId: userId)
                                                        if let firstAvatar = fetchedAvatars.first {
                                                                withAnimation {
                                                                    avatars = firstAvatar
                                                                }
                                                        }
                                                    } 
                                                    catch {
                                                        print("Error: \(error)")
                                                    }
                                                }
                                            }) {
                                                Label("Удалить", systemImage: "xmark.circle.fill")
                                            }
                                        }
                                }
                                .onDelete { indexSet in
                                    withAnimation {
                                            avatars.remove(atOffsets: indexSet)
                                    }
                                }
                            }
                            .padding()
                          
                        }
                    }
                    .padding(.top, 15)
                    
                    Divider()
                    
                    Button(action: {
                        shouldNavigateAds = true
                    }) {
                        Text("Upload Picture")
                            .foregroundColor(.white)
                            .font(Font.system(size: 20, weight: .bold))
                            .frame(width: 254, height: 54)
                            .background(
                                Color(colors.accent)
                                    .blur(radius: 5)
                            )
                            .cornerRadius(30)
                            .padding(.top, 30)
                    }
                    
                    NavigationLink(destination: UploadAvatarView(), isActive: $shouldNavigateAds) {
                        EmptyView()
                    }
                    
                    Spacer()
                }
                .onAppear {
                    Task {
                       do {
                           let fetchedAvatars = try await getAvatars(matrixId: userId)
                            if let firstAvatar = fetchedAvatars.first {
                                avatars = firstAvatar
                            }
                           }
                        catch {
                               print("Error fetching avatars: \(error)")
                           }
                       }

                }
            }
        }
       
    }
}




//View For Avatars
@available(iOS 15.0, *)
struct AvatarTileView: View {
    let avatar: AvatarResponseElement
    let isSelected: Bool
    var colors: ColorsUIKit = DarkColors.uiKit
    
    var body: some View {
        AsyncImage(url: URL(string: "\(baseURL)/files/\(avatar.file.uuid)")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .frame(width: 200, height: 200)
                    .cornerRadius(8)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color(colors.accent) : Color.clear, lineWidth: isSelected ? 4 : 0)
                            .animation(.easeInOut(duration: 0.1))
                    )
            case .failure:
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 200, height: 300)
                    .cornerRadius(8)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color(colors.accent) : Color.clear, lineWidth: isSelected ? 4 : 0)
                            .animation(.easeInOut(duration: 0.1))
                    )
            @unknown default:
                EmptyView()
            }
        }
    }
}
