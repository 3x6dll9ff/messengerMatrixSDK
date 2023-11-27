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

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK
import SwiftUI

struct AvatarResponse: Decodable {
    var uuid: String
    var fileUuid: String
    var matrixId: String?
    var createdAt: Date
}

//MARK: Backend logic

private var accessToken: String = ""

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
    
    guard let userId = mainAccount?.mxSession.myUser.userId else {
        return []
    }

    let url = "\(baseURL)/avatars?matrixId=\(userId)"

    do {
        let dataResponse = try await AF.request(
            url,
            method: .get
        ).responseDecodable(of: [AvatarResponse].self) { response in
            switch response.result {
            case .success(let avatars):
                print("Avatars: \(avatars)")
            case .failure(let error):
                print("Error fetching avatars: \(userId)")
            }
        }
        return []
    } catch {
        print("Error fetching avatars: \(error)")
        return []
    }
}



//MARK: Front
@available(iOS 15.0, *)
struct SUIProfilePictureView: View {
    @State private var selectedIndex: Int? = 0
    @State private var yOffset: CGFloat = 0
    @State private var isHandTapped: Bool = false
    //variables for open  View
    @State private var shouldNavigateAds = false
    @State private var avatars: [AvatarResponse] = []
    
    var shipName = "User Settings"

    var body: some View {
        NavigationView{
            VStack {
                
                VStack {
                    
                    Text("Swipe down to hide")
                        .foregroundColor(.gray)
                        .padding(.top, 15)
                    
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.white)
                        .offset(y: yOffset)
                        .rotationEffect(Angle(degrees: isHandTapped ? -5 : 5))
                        .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
                        .padding(.top, 35)
                    
                }
          
                VStack {
                     Text(shipName)
                         .foregroundColor(.white)
                         .font(.system(size: 20))
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
                                }
                            }
                            .padding()
                        }
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
                             Color("BtnUploadPicture")
                                 .blur(radius: 10)
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
                     avatars = await getAvatars(matrixId: (userId))
                 }

                 let screenHeight = UIScreen.main.bounds.height / 5
                 yOffset = -screenHeight / 5

                 withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                     isHandTapped.toggle()
                 }
             }
         }
     }
 }

struct AvatarTileView: View {
    let avatar: AvatarResponse
    let isSelected: Bool

    var body: some View {
        Rectangle()
            .frame(width: 200, height: 300)
            .foregroundColor(isSelected ? .white : .white)
            .cornerRadius(8)
            .scaleEffect(isSelected ? 1.0 : 0.8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color("BtnUploadPicture") : Color.clear, lineWidth: isSelected ? 4 : 0)
                    .animation(.easeInOut(duration: 0.1))
            )
    }
}
