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

import SwiftUI
import RevenueCat

struct DesignChatUIView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.theme) private var theme
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    @State private var bubbleStates = [
        true, false, false, false
    ]
    @State private var goWS: Bool = false
    @State private var savedBubble = UserDefaults.standard.integer(forKey: "storedBubble")
    @State private var showingSubscriptionView = false
    
    var body: some View {
        VStack{

            heading
            Spacer()
            
            ScrollView(.vertical){
                logoCircle
                Spacer()
                subscriptionBtn
                Spacer()
                noAdsBtn
                nightModeBtn
                Spacer()
                bubbleSelector
                Spacer()
                createChatChooseWallpaper
                
                NavigationLink("", destination: WallpaperSelection(), isActive: $goWS)
            }
            
            Spacer()
        }
        .onAppear{
            if savedBubble != nil{
                updateBubbleStates(savedBubble-1)
            }
            
            noAdsToggle = getNoAdsToggleState()
        }
        .ignoresSafeArea()
        .frame(width: w, height: h)
        .background(Color(red: 0.12, green: 0.13, blue: 0.14))
    }
    
    //Heading
    var heading: some View{
        HStack{
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }){
                Image(systemName: "chevron.left")
                    .padding(.horizontal)
                Text("Back")
            }
            Spacer()
            Text("Design")
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .padding(.horizontal)
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            Text("Next")
                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .frame(height: h*0.13)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
    }
    
    //LogoCircle
    var logoCircle: some View{
        VStack{
            Image("onboarding_center_circle")
                .resizable()
                .frame(width: w/2, height: w/2)
            Spacer().frame(height: 20)
            Text("Buy a subscription and change the design as you wish!")
              .font(
                Font.custom("Roboto", size: 15)
                  .weight(.semibold)
              )
              .kerning(0.6)
              .multilineTextAlignment(.center)
              .foregroundColor(.white)
              .frame(width: 293, alignment: .top)
        }
    }

    //Subscription
    var subscriptionBtn: some View{
        VStack{
            Button(action: {
                showingSubscriptionView = true
            })
            {
                HStack{
                    Image("logo_mini")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.horizontal)
                    Text("Buy subscription")
                      .font(
                        Font.custom("Inter", size: 13)
                          .weight(.medium)
                      )
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.horizontal)
                }
                .frame(width: w*0.92, height: 45)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                .cornerRadius(10, corners: [.topLeft, .topRight])
            }.sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
            
            Button(action: {
                restorePurchases()
            }){
                HStack{
                    Text("Restore purchase")
                      .font(
                        Font.custom("Inter", size: 13)
                          .weight(.medium)
                      )
                      .padding(.horizontal)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.horizontal)
                }
                .frame(width: w*0.92, height: 45)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            }
        }
    }
    
    @State private var noAdsToggle = false
    var noAdsBtn: some View{
        Button(action: {
            
        }){
            HStack{
                Text("No ads")
                  .font(
                    Font.custom("Inter", size: 13)
                      .weight(.medium)
                  )
                  .padding(.horizontal)
                
                Spacer()
                Toggle("", isOn: $noAdsToggle)
                    .disabled(!RevenueCatUtils.isVip)
                    .padding(.horizontal)
                    .onChange (of: noAdsToggle) { _ in
                        noAdsToggled()
                    }
            }
            .frame(width: w*0.92, height: 45)
            .background(Color(red: 0.06, green: 0.06, blue: 0.06))
            .cornerRadius(10)
            .padding(.vertical)
        }
    }
    
    //NightMode
    @State private var nightModeToggle = true
    var nightModeBtn: some View{
        Button(action: {
            
        }){
            HStack{
                Text("Night mode")
                  .font(
                    Font.custom("Inter", size: 13)
                      .weight(.medium)
                  )
                  .padding(.horizontal)
                
                Spacer()
                Toggle("", isOn: $nightModeToggle)
                    .padding(.horizontal)
            }
            .frame(width: w*0.92, height: 45)
            .background(Color(red: 0.06, green: 0.06, blue: 0.06))
            .cornerRadius(10)
            .padding(.vertical)
        }
    }
    
    //BubbleSelector
    var bubbleSelector: some View{
        HStack{
            Button(action: {
                self.updateBubbleStates(0)
                UserDefaults.standard.set(1, forKey: "storedBubble")
            }){
                VStack{
                    Image("bubbles1")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(5)
                        .background(
                            self.bubbleStates[0] ? RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 1) :
                                RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 0)
                        )
                    Text("Classic")
                      .font(Font.custom("Inter", size: 10))
                      .multilineTextAlignment(.center)
                      .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                }
            }
            Spacer()
            Button(action: {
                self.updateBubbleStates(1)
                UserDefaults.standard.set(2, forKey: "storedBubble")
            }){
                VStack{
                    Image("bubbles2")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(5)
                        .background(
                            self.bubbleStates[1] ? RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 1) :
                                RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 0)
                        )
                    Text("BigStar +")
                      .font(Font.custom("Inter", size: 10))
                      .multilineTextAlignment(.center)
                      .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                }
            }
            Spacer()
            Button(action: {
                self.updateBubbleStates(2)
                UserDefaults.standard.set(3, forKey: "storedBubble")
            }){
                VStack{
                    Image("bubbles3")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(5)
                        .background(
                            self.bubbleStates[2] ? RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 1) :
                                RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 0)
                        )
                    Text("BigStar +")
                      .font(Font.custom("Inter", size: 10))
                      .multilineTextAlignment(.center)
                      .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                }
            }
            Spacer()
            Button(action: {
                self.updateBubbleStates(3)
                UserDefaults.standard.set(4, forKey: "storedBubble")
            }){
                VStack{
                    Image("bubbles4")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(5)
                        .background(
                            self.bubbleStates[3] ? RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 1) :
                                RoundedRectangle(cornerRadius: 10)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.53, green: 0.44, blue: 0.77), lineWidth: 0)
                        )
                    Text("BigStar +")
                      .font(Font.custom("Inter", size: 10))
                      .multilineTextAlignment(.center)
                      .foregroundColor(Color(red: 0.51, green: 0.51, blue: 0.51))
                }
            }
        }
        .padding()
        .frame(width: w*0.92)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
        .cornerRadius(10)
        .padding()
    }
    
    //CreateChat & ChooseWallpaper
    var createChatChooseWallpaper: some View{
        VStack{
            Button(action: {
                
            }){
                HStack{
                    Text("Create new chat")
                      .font(
                        Font.custom("Inter", size: 13)
                          .weight(.medium)
                      )
                      .padding(.horizontal)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.horizontal)
                }
                .frame(width: w*0.92, height: 45)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                .cornerRadius(10, corners: [.topLeft, .topRight])
            }
            
            Button(action: {
                goWS = true
            }){
                HStack{
                    Text("Wallpaper for chat")
                      .font(
                        Font.custom("Inter", size: 13)
                          .weight(.medium)
                      )
                      .padding(.horizontal)
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .padding(.horizontal)
                }
                .frame(width: w*0.92, height: 45)
                .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            }
        }
    }
    
    func restorePurchases() {
        Purchases.shared.restorePurchases { (customerInfo, error) in
            if let error = error {
                print("Ошибка при восстановлении покупок: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                RevenueCatUtils.checkVipStatus { isVip in
                    print("Покупки восстановлены, isVip: \(isVip)")
                }
            }
        }
    }
    
    private func getNoAdsToggleState() -> Bool {
        return UserDefaults.standard.bool(forKey: "noAdsToggle")
    }
    
    func noAdsToggled() {
        print("set noAdsToggle \(noAdsToggle)")
        UserDefaults.standard.set(noAdsToggle, forKey: "noAdsToggle")
    }
    
    func updateBubbleStates(_ selectedBubbleIndex: Int) {
        for i in 0..<bubbleStates.count {
            bubbleStates[i] = (i == selectedBubbleIndex)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

#Preview {
    DesignChatUIView()
}
