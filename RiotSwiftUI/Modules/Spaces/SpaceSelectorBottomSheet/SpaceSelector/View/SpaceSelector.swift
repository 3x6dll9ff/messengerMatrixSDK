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

import SwiftUI
import Lottie

@available(iOS 15.0, *)
struct SpaceSelector: View {
    // MARK: - Properties
    // MARK: Private
    
    //variables for animating the transparency of buttons
    @State private var showAllBtn = false
    
    //variables for open  View
    @State private var shouldNavigateAds = false
    @State private var shouldNavigateCity = false
    @State private var shouldNavigatePanel = false
    @State private var shouldNavigateCloud = false
    @State private var shouldNavigateCloudShare = false
    @State private var shouldNavigateCategory = false
    @State private var shouldNavigateFavouriteAds = false
    
    //Activate Lottie Animation
    @State private var showAdsLottieView = false
    @State private var showCityLottieView = false
    @State private var showAdvertiserLottieView = false
    @State private var showCloudLottieView = false
    @State private var showCloudShareLottieView = false
    @State private var showCategoryLottieView = false
    @State private var showHeartLottieView = false
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceSelectorViewModel.Context
    
    @State private var goWallpaperSelection: Bool = false
    
    let ds = DesignChatUIView()
    
    var body: some View {
        ScrollView {
            //Wallpaper Selection Btn
            //NavigationLink(destination:  ws, isActive: $goWallpaperSelection) {}
            
            Button(action: {
                goWallpaperSelection = true
            }){
                HStack {
                    Spacer().frame(width: 50)
                    Text("Design")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color("DetailBtnColors"))
                .cornerRadius(10)
                .padding(.horizontal, 10)
                .opacity(showAllBtn ? 1 : 0)
                .animation(.easeInOut(duration: 0.45))
            }
            .fullScreenCover(isPresented: $goWallpaperSelection, content: {
                NavigationView{
                    ds
                }
            })
            
                // Ad submission  Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        shouldNavigateAds = true
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAdsLottieView = true
           
                                  }
                }) {
                    HStack {
                        LottieView(lottieFile: "rocket")
                            .frame(width: 50, height: 50)
                        Text("Подача рекламы")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination:  AdsView(), isActive: $shouldNavigateAds) {}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.45))
                }
                .overlay(
                    ZStack {
                        if showAdsLottieView {
                            LottieViewAnimation(lottieFile: "rocket")
                                .frame(width: 120, height: 120)
                                .padding(.top,300)
                            //задержка перед появлением
                                .opacity(showAdsLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1.0))
                        }
                    }
                    .onAppear{showAdsLottieView = false})
                
                // Select City Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldNavigateCity = true
         
                
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCityLottieView = true
    
                                  }
                }) {
                    HStack {
                        LottieViewAnimation(lottieFile: "city")
                            .frame(width: 50, height: 50)
                        Text("Выбор города")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination: SelectCityView(), isActive: $shouldNavigateCity) {}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.55))
                }
                .overlay(
                    ZStack {
                        if showCityLottieView {
                            LottieViewAnimation(lottieFile: "city")
                                .frame(width: 120, height: 120)
                                .padding(.top,100)
                            //задержка перед появлением
                                .opacity(showCityLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1.0))
                        }
                    }
                    .onAppear{showCityLottieView = false})
                
                // Advertiser Panel Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldNavigatePanel = true
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAdvertiserLottieView = true
                                  }
                }) {
                    HStack {
                        LottieViewAnimation(lottieFile: "person")
                            .padding(5)
                            .frame(width: 50, height: 50)
                        Text("Кабинет рекламодателя")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination: AdvertiserPanelView(),isActive: $shouldNavigatePanel) { }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.65))
                }
                .overlay(
                    ZStack {
                        if showAdvertiserLottieView {
                            LottieViewAnimation(lottieFile: "person")
                                .frame(width: 120, height: 120)
                            //задержка перед появлением
                                .opacity(showAdvertiserLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1.0))
                        }
                    }
                    .onAppear{showAdvertiserLottieView = false})
           

                // Cloud List Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldNavigateCloud = true
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCloudLottieView = true
                                  }
                }) {
                    HStack {
                        LottieViewAnimation(lottieFile: "cloud")
                            .frame(width: 50, height: 50)
                        Text("Облачное хранилище")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination: CloudListView(),isActive: $shouldNavigateCloud) {}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.75))
                }
                .overlay(
                    ZStack {
                        if showCloudLottieView {
                            LottieViewAnimation(lottieFile: "cloud")
                                .frame(width: 120, height: 120)
                                .padding(.top,-100)
                            //задержка перед появлением
                                .opacity(showCloudLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1))
                        }
                    }
                    .onAppear{showCloudLottieView = false})

                // Cloud Share Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldNavigateCloudShare = true
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCloudShareLottieView = true
                                  }
                }) {
                    HStack {
                        LottieViewAnimation(lottieFile: "share")
                            .padding(5)
                            .frame(width: 50, height: 50)
                        Text("Отправить файл")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination: CloudShareView(),isActive: $shouldNavigateCloudShare) {}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.85))
                }
                .overlay(
                    ZStack {
                        if showCloudShareLottieView {
                            LottieViewAnimation(lottieFile: "share")
                                .frame(width: 120, height: 120)
                                .padding(.top,-200)
                            //задержка перед появлением
                                .opacity(showCloudShareLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1.0))
                        }
                    }
                    .onAppear{showCloudShareLottieView = false})
     
                // Select Category Btn
                Button(action: {
                    showAllBtn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        shouldNavigateCategory = true
                     }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                      showCategoryLottieView = true
                                  }
                }) {
                    HStack {
                        LottieViewAnimation(lottieFile: "filter")
                            .padding(5)
                            .frame(width: 50, height: 50)
                        Text("Фильтр рекламы")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        NavigationLink(destination: SelectCategoryView(),isActive: $shouldNavigateCategory) {}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color("DetailBtnColors"))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .opacity(showAllBtn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.95))
                }
                .overlay(
                    ZStack {
                        if showCategoryLottieView {
                            LottieViewAnimation(lottieFile: "filter")
                                .frame(width: 120, height: 120)
                                .padding(.top,-200)
                            //задержка перед появлением
                                .opacity(showCategoryLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1.0))
                        }
                    }
                    .onAppear{showCategoryLottieView = false})
                
                // FavouriteAds
            Button(action: {
                showAllBtn = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    shouldNavigateFavouriteAds = true
                 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showHeartLottieView = true
                }
            }) {
                HStack {
                    LottieViewAnimation(lottieFile: "heart")
                        .frame(width: 50, height: 50)
                    Text("Избранные рекламы")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    NavigationLink(destination: FavouriteAds(), isActive: $shouldNavigateFavouriteAds) {}
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color("DetailBtnColors"))
                .cornerRadius(10)
                .padding(.horizontal, 10)
                .opacity(showAllBtn ? 1 : 0)
                .animation(.easeInOut(duration: 0.75))
            }
                .overlay(
                    ZStack {
                        if showHeartLottieView {
                            LottieViewAnimation(lottieFile: "heart")
                                .frame(width: 120, height: 120)
                                .padding(.top,-300)
                            //задержка перед появлением
                                .opacity(showHeartLottieView ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 1))
                        }
                    }
                    .onAppear{showHeartLottieView = false})
            
        }
        .onAppear {
            withAnimation {
                showAllBtn = true
            }
        }
        .frame(maxWidth: .infinity ,maxHeight: .infinity)
        .background(theme.colors.background.edgesIgnoringSafeArea(.all))
        .navigationTitle(viewModel.viewState.navigationTitle)
        .toolbar {
//            ToolbarItem(placement: .confirmationAction) {
//                Button(VectorL10n.create) {
//                    viewModel.send(viewAction: .createSpace)
//                }
//            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
        .accentColor(.purple)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct SpaceSelector_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceSelectorScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
