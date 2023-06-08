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
    case bigstar,
         youtube,
         instagram,
         website,
         phoneNumber,
         whatsApp
}

@available(iOS 15.0, *)
struct AdSheetView: View{
    var clientAd: ClientAds
    
    func getLinkByLinkType(linkType: LinkType) -> String {
        switch linkType {
            case .bigstar:
            return clientAd.bigstarUrl ?? ""
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
            case .bigstar:
                link = "bigstar"
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
        ScrollView{
            VStack(alignment: .center){
                HStack{
                    AsyncImage(
                        url: URL(string: "\(baseURL)/files/\(clientAd.bannerUuid)")
                    ){ phase in
                        switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                     
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
                }
                .frame(height: 170)
                
                VStack(alignment: .leading){
                    Text(clientAd.title)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    Text(clientAd.description)
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }.padding(16)
                
                Spacer()
                
                HStack(spacing: 16){
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
                            if(getLinkByLinkType(linkType: linkType).count > 0){
                                Image(
                                    uiImage: UIImage(named: "\(linkType.rawValue).png")!
                                    )
                            } else {
                                Image(
                                    uiImage: UIImage(named: "\(linkType.rawValue)_inactive.png")!
                                )
                            }
                        }
                    }
                }.padding(.bottom, 24)
            }
        }
    }
}

