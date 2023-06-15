//swiftlint:disable all
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

@available(iOS 15.0, *)
struct AdSheetView: View{
    var clientAd: ClientAds
    
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
            return "https://api.whatsapp.com/send?phone=\(clientAd.phoneNumber ?? "")&text=%D0%97%D0%B4%D1%80%D0%B0%D0%B2%D1%81%D1%82%D0%B2%D1%83%D0%B9%D1%82%D0%B5!%20%D0%9F%D0%B8%D1%88%D1%83%20%D0%B2%D0%B0%D0%BC%20%D0%B8%D0%B7%20BigStar%20Messenger"
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

    var body: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading){
                    Text("\n\(clientAd.description)")
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.top, 168)
                .padding(.bottom, 112)
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            
            VStack(alignment: .center){
                Text(clientAd.title)
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .foregroundColor(.white)
                HStack {
                    AsyncImage(
                        url: URL(string: "\(baseURL)/files/\(clientAd.bannerUuid)")
                    ) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .mask(
                                    Image("bannerMask")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                )
                                .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 4)
                                .frame(maxHeight: 275)
                                .frame(maxWidth: .infinity)
                            
                        case .failure(_):
                            Text("Произошла ошибка")
                                .foregroundColor(.purple)
                            
                        case .empty:
                            Text("Загрузка")
                                .foregroundColor(.purple)
                            
                        @unknown default:
                            Text("Произошла ошибка")
                                .foregroundColor(.purple)
                        }
                    }
                    
                    Spacer().frame(width: 24)
                }
                .offset(y: -14)


                Spacer()
            }
            .offset(y: -8)
            .allowsHitTesting(false)

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

    }
}

    
