
// swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire
import MatrixSDKCrypto

private var accessToken: String = ""

@available(iOS 15.0, *)
struct AdvertiserPanelView: View {
    @State private var ads: [AdvertiserAds] = []
    @Environment(\.dismiss) var dismiss
    
    let locale = Locale.current
    
    var body: some View {
        NavigationView {
            VStack {
                SwiftUI.Section {
                    List {
                        if(ads.count != 0) {
                            ForEach(0 ..< ads.count) { index in
                                VStack(alignment: .leading){
                                    Text(ads[index].title)
                                        .font(.title.bold())
                                    Text(ads[index].description)
                                        .lineLimit(1)
                                        .foregroundColor(.gray)
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Shows" : "Просмотров"): ")
                                        Text("\(ads[index].showsNumber)")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Clicks" : "Переходов"): ")
                                        Text("\(ads[index].clicksNumber)")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Created at" : "Создано"): ")
                                        Text("\(convertDateFormat(inputDate: ads[index].createdAt))")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Instagram clicks" : "Instagram переходов"): ")
                                        Text("\(ads[index].instagramClicksNumber)")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Youtube clicks" : "Youtube переходов"): ")
                                        Text("\(ads[index].youtubeClicksNumber)")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Website clicks" : "Website переходов"): ")
                                        Text("\(ads[index].websiteClicksNumber)")
                                            .foregroundColor(.purple)
                                    }
                                    HStack {
                                        Text("\(locale.identifier.hasPrefix("en") ? "Big Star clicks" : "Big Star переходов"): ")
                                        Text("\(ads[index].bigstarClicksNumber)")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }.headerProminence(.increased)
            }
            .navigationTitle("Мои объявления")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: fetch)
        }
    }
    
    private func convertDateFormat(inputDate: String) -> String {
        var endOfStr = inputDate.firstIndex(of: ".")!
        let date = inputDate[...endOfStr].dropLast()

        let olDateFormatter = DateFormatter()
        olDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let oldDate = olDateFormatter.date(from: String(date))

        let convertDateFormatter = DateFormatter()
        convertDateFormatter.dateFormat = "MMM dd yyyy h:mm a"

        return convertDateFormatter.string(from: oldDate!)
   }
    
    private func createAdvertiser() async {
        print(userInfo.userId)
        print(userInfo.phoneNumber)
        print(userInfo.email)
        
        let params: [String: Any] = [
            "username": userInfo.phoneNumber,
            "password": "12345678",
        ]
        
        let uuid = try! await AF.request(
            "\(baseURL)/advertisers",
            method: .post,
            parameters: params
        ).serializingDecodable(CreateAdvertiserResponse.self).value.uuid
        
        print("Advertiser UUID: " + uuid)
    }
    
    private func getMyAdvertiserUuid() async -> String{
        let headers:HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        let uuid = try! await AF.request(
            "\(baseURL)/auth/me",
            method: .get,
            headers: headers
        ).serializingDecodable(MeResponse.self).value.advertiser.uuid
        return uuid
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
            await createAdvertiser()
            return await login()
        }
        
        accessToken = token!
        return token!
    }

    private func fetch() {
        Task {
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
            
            
            _ = await login()
            
            ///TODO change to normal fetching
            let headers:HTTPHeaders = [
                    "Authorization": "Bearer \(accessToken)"
                ]
            let advertiserUuid = await getMyAdvertiserUuid()
            ads = try! await AF.request(
                "\(baseURL)/ads/advertiser/\(advertiserUuid)",
                method: .get,
                headers: headers
            ).serializingDecodable([AdvertiserAds].self).value
        }
    }
}
