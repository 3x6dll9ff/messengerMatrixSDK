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



@available(iOS 15.0, *)
struct SUIProfilePictureView: View {
    @State private var selectedIndex: Int? = 0
    @State private var yOffset: CGFloat = 0
    @State private var isHandTapped: Bool = false
    //variables for open  View
    @State private var shouldNavigateAds = false
    
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
          
                VStack{
                    
                    Text(shipName)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    Divider()
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(0..<5, id: \.self) { index in
                                    Rectangle()
                                        .frame(width: 200, height: 300)
                                        .foregroundColor(selectedIndex == index ? .white : .white)
                                        .cornerRadius(8)
                                        .scaleEffect(selectedIndex != index ? 0.8 : 1.0)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedIndex == index ? Color("BtnUploadPicture") : Color.clear, lineWidth: selectedIndex == index ? 4 : 0)
                                                .animation(.easeInOut(duration: 0.1))
                                        )
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
                      let screenHeight = UIScreen.main.bounds.height / 5
                      yOffset = -screenHeight / 5

                      withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                          isHandTapped.toggle()
                      }
                  }
        }
  
            
            
        }
       
}
