// swiftlint:disable all
//
//  AdSheetView.swift
//  UiKitQa
//
//  Created by Boris on 20.08.2022.
//

import Foundation
import SwiftUI
import Alamofire


enum LinkType: String, CaseIterable{
    case
//        bigstar,
        phoneNumber,
        whatsApp,
        instagram,
        youtube,
        website
}

private var accessToken: String = ""

@available(iOS 15.0, *)
struct AdSheetView: View{
    
    var clientAd: ClientAds
    @State private var isAnimatedLottie = true
    @State private var showText = false
    @State private var isImageVisible = false
    @State private var isLottieAnimation = false
    
    
    func getLinkByLinkType(linkType: LinkType) -> String {
        switch linkType {
//            case .bigstar:
//            return clientAd.bigstarUrl ?? ""
            case .youtube:
            return clientAd.youtubeUrl ?? ""
            case .instagram:
            return clientAd.instagramUrl ?? ""
            case .website:
            return clientAd.websiteUrl ?? ""
            case .phoneNumber:
            return "tel:\(clientAd.phoneNumber ?? "")"
            case .whatsApp:
            return "https://api.whatsapp.com/send?phone=\(clientAd.phoneNumber ?? "")&text=%D0%97%D0%B4%D1%80%D0%B0%D0%B2%D1%81%D1%82%D0%B2%D1%83%D0%B9%D1%82%D0%B5!%20%D0%9F%D0%B8%D1%88%D1%83%20%D0%B2%D0%B0%D0%BC%20%D0%B8%D0%B7%20BigStar%20Messenger%20https://bigstar.netlify.app/"
        }
    }

    
    func clickUrl(linkType: LinkType) async {
        var link = ""
        switch linkType {
//            case .bigstar:
//                link = "bigstar"
            case .youtube:
                link = "youtube"
            case .instagram:
                link = "instagram"
            case .website:
                link = "website"
            case .phoneNumber:
                link = ""
            case .whatsApp:
                link = ""
            
        }
        print("\(baseURL)/ads/\(clientAd.uuid)/\(link)/click")
        if link != "" {
            let asd = try! await AF.request(
                "\(baseURL)/ads/\(clientAd.uuid)/\(link)/click",
                method: .patch
            ).serializingDecodable(ClientAds.self).value.uuid
            print(asd)
        }
       
    }
    func openUrl(urlString: String) {
        let url = URL(string: urlString)!
      
        UIApplication.shared.open(url)
    }
    
    private func login() async -> String{
        
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
    
        
    private func addFavorite(adUUID: String) async {
        do {
            let token = await login()
            
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token)"
            ]
            
            let url = "\(baseURL)/ads/\(clientAd.uuid)/favorite"
            
            let response = try await AF.request(
                url,
                method: .post,
                headers: headers
            ).serializingDecodable(ClientAds.self).value       
        } catch {
            // Обработка ошибки сетевого запроса или аутентификации
        }
    }

    var body: some View {
        ZStack{
        ScrollView {
            VStack(alignment: .leading){
                              Text("\n\(clientAd.description)")
                                  .font(.system(size: 16))
                                  .fontWeight(.semibold)
                                  .foregroundColor(.white)
                                  .opacity(showText ? 1 : 0)
                                  .animation(.easeIn(duration: 0.5))
                                  .onAppear {
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                          withAnimation {
                                                 showText = true
                                                                       }
                                                    }

                       }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 130)
            .padding(.bottom, 112)
            .padding(.horizontal, 16)
          
        }
        .padding(.top, 170)
        
        VStack{
            VStack{
                HStack(alignment: .center){
                    Spacer()
                    Text(clientAd.title)
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                        .foregroundColor(.white)
                    Spacer()
                }
        
            }
            VStack(alignment: .trailing) {
                ZStack {
                  
                    GeometryReader { proxy in
              
                        let maskWidth = proxy.size.width
                        let maskHeight = proxy.size.height

                       
                        let mask = Image("bannerMask")
                            .resizable()
                            .scaledToFit()
                            .frame(width: maskWidth, height: maskHeight)

                     
                        AsyncImage(
                            url: URL(string: "\(baseURL)/files/\(clientAd.bannerUuid)")
                        ) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable(resizingMode: .stretch)
                                    .frame(width: maskWidth, height: maskHeight)
                                    .mask(mask)
                                    .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 4)
                                    .offset(x: isImageVisible ? 0 : -UIScreen.main.bounds.width)
                                    .animation(.easeInOut(duration: 1.0))
                            case .failure(_):
                                Text("Произошла ошибка")
                                    .foregroundColor(.purple)
                                    .frame(maxHeight: maskHeight)
                                    .frame(maxWidth: maskWidth)

                            case .empty:
                                Text("Загрузка")
                                    .foregroundColor(.purple)
                                    .frame(maxHeight: maskHeight)
                                    .frame(maxWidth: maskWidth)

                            @unknown default:
                                Text("Произошла ошибка")
                                    .foregroundColor(.purple)
                                    .frame(maxHeight: maskHeight)
                                    .frame(maxWidth: maskWidth)
                            }
                        }
                       
                    }
                    
                    HStack{
                        Spacer()
                        
                        Circle()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .shadow(
                                color: Color.black.opacity(0.3),
                                radius: 4,
                                x: 0,
                                y: 0
                            )
                            .padding(-10)
                            .padding(.top, -20)
                            .overlay(
                                ZStack {
                                   

                                    Button(action: {
                                        isLottieAnimation.toggle()
                                        if isLottieAnimation {
                                            Task {
                                                await addFavorite(adUUID: clientAd.uuid)
                                            }
                                        }
                                    }) {
                                        if isLottieAnimation{
                                            LottieViewAnimationOnce(lottieFile: "heart")
                                                .frame(width: 60, height: 60)
                                            
                                        }
                                        else{
                                            LottieView(lottieFile: "heart")
                                                .frame(width: 60, height: 60)
                                        }
                                        
                              
                                    }
                                    .frame(width: 60, height: 60)
                                    .offset(y: -10)
                                }
                            )
                    }
                }

                Spacer()
            }
            .padding(.top,-100)
            .offset(y: -14)
            .onAppear {
                withAnimation {
                    isImageVisible = true
                }
            }

            Spacer()
        }
        .offset(y: -8)
       
        VStack{
            Spacer()

            ZStack {
                Image("adSheetFooter")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 16) {
                    ForEach(LinkType.allCases, id: \.rawValue) { linkType in
                        Button(action: {
                            let link = getLinkByLinkType(linkType: linkType)
                            
                            if(link.count > 0){
                                openUrl(urlString: link)
                                Task {
                                    await clickUrl(linkType: linkType)
                                }
                            }
                        }) {
                            Image(uiImage: UIImage(named: "\(linkType.rawValue).png")!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 45, height: 45)
                                .opacity(showText ? 1 : 0)
                                .animation(.easeIn(duration: 0.5))
                                
                        }
                    }
                }
                .padding(.top, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .allowsHitTesting(true)
        .offset(y: 4)
            

        }
        .padding(.top, 16)
        .background(
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(UIColor(red: 156/255, green: 58/255, blue: 218/255, alpha: 1.0)),
                        Color(UIColor(red: 135/255, green: 43/255, blue: 184/255, alpha: 0.6))
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isAnimatedLottie = false
     
                          }
        }

    }
}

    

