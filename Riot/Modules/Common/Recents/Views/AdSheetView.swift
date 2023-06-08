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
         website
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
        }
        print("\(baseURL)/ads/\(clientAd.uuid)/\(link)/click")
         let asd = try! await AF.request(
            "\(baseURL)/ads/\(clientAd.uuid)/\(link)/click",
            method: .patch
         ).serializingDecodable(ClientAds.self).value.uuid
        print(asd)
    }
    func openUrl(urlString: String) {
        let url = URL(string:
            urlString.starts(with: "http")
                ? urlString
                :"https://\(urlString)"
        )!
        
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

