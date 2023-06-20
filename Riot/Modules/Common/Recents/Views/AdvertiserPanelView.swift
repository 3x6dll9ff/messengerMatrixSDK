// swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire
import MatrixSDKCrypto

private var accessToken: String = ""

@available(iOS 15.0, *)
struct AdvertiserPanelView: View {
    @State private var ads: [AdvertiserAds] = []
    @State private var showAlert: Bool = false
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
                                        .padding(.bottom, 4)
                                    VStack(alignment: .leading){
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
                                    .padding(.bottom, 8)
                                    Button(
                                        VectorL10n.delete,
                                        role: .destructive,
                                        action: {
                                            showAlert = true
                                        }
                                    )
                                    .alert(isPresented: $showAlert) {
                                        Alert(
                                            title: Text(VectorL10n.confirmDelete),
                                            message: Text(VectorL10n.confirmDeleteDescription),
                                            primaryButton: .destructive(
                                                Text(VectorL10n.delete),
                                                action: {
                                                    Task {
                                                        await deleteAd(adUuid: ads[index].uuid)
                                                    }
                                                }
                                            ),
                                            secondaryButton: .cancel()
                                        )
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
        let inputDateFormat = ISO8601DateFormatter()
        inputDateFormat.formatOptions = [.withInternetDateTime]

        guard let date = inputDateFormat.date(from: inputDate) else {
            return ""
        }

        let outputDateFormat = DateFormatter()
        outputDateFormat.dateFormat = "MMM dd yyyy h:mm a"
        outputDateFormat.locale = Locale(identifier: "en_US_POSIX")

        return outputDateFormat.string(from: date)
    }
                                        
    private func deleteAd(adUuid: String) async {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]

        AF.request(
            "\(baseURL)/ads/\(adUuid)",
            method: .delete,
            headers: headers
        ).response { response in
            if let error = response.error {
                print("Ошибка удаления рекламы: \(error)")
            } else {
                if let index = ads.firstIndex(where: { $0.uuid == adUuid }) {
                    ads.remove(at: index)
                    print("Реклама с UUID \(adUuid) успешно удалена")
                } else {
                    print("Реклама с UUID \(adUuid) не найдена в массиве ads")
                }
            }
        }
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
            
            let token = await login()
            
            let advertiserUuid = await getMyAdvertiserUuid()

            let headers:HTTPHeaders = [
                "Authorization": "Bearer \(accessToken)"
            ]
            ads = try! await AF.request(
                "\(baseURL)/ads/advertiser/\(advertiserUuid)",
                method: .get,
                headers: headers
            ).serializingDecodable([AdvertiserAds].self).value
        }
    }
}
