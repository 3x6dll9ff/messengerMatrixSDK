//swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire
import PassKit
import MatrixSDKCrypto
import MatrixSDK

private class Ad {
    let title: String
    let description: String
    
    let email: String
    let phoneNumber: String
    let startsAt: String
    let endsAt: String
    
    let cityUuids: [String]
    let advertiserUuid: String
    let thumbnailUuid: String
    let bannerUuid: String
    let categoryUuid: String
    
    let youtubeUrl: String
    let instagramUrl: String
    let bigstarUrl: String
    let websiteUrl: String
    
    init(title: String, description: String, email: String, phoneNumber: String, cityUuids: [String], advertiserUuid: String, thumbnailUuid: String, bannerUuid: String, categoryUuid: String, youtubeUrl: String, instagramUrl: String, bigstarUrl: String, websiteUrl: String, days: Int){
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MM-dd"
        let dayInSeconds = 86400.0
        
        let startsAtDate = Date().addingTimeInterval(dayInSeconds)
        let endsAtDate = startsAtDate.addingTimeInterval(dayInSeconds * Double(days))

        self.startsAt = dateFormatterPrint.string(from: startsAtDate)
        self.endsAt = dateFormatterPrint.string(from: endsAtDate)
        
        self.cityUuids = cityUuids
        
        self.title = title
        self.description = description
        self.email = email
        self.phoneNumber = phoneNumber
        self.advertiserUuid = advertiserUuid
        self.thumbnailUuid = thumbnailUuid
        self.categoryUuid = categoryUuid
        self.bannerUuid = bannerUuid
        self.youtubeUrl = youtubeUrl
        self.instagramUrl = instagramUrl
        self.bigstarUrl = bigstarUrl
        self.websiteUrl = websiteUrl
    }
    
    
    
    @available(iOS 13.0.0, *)
    func create() async -> String{
        let headers:HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        var params: [String: Any] = [
            "title": title,
            "description": description,
            "cityUuids": cityUuids,
            "thumbnailUuid": thumbnailUuid,
            "bannerUuid": bannerUuid,
            "categoryUuid": categoryUuid,
            "advertiserUuid": advertiserUuid,
            "email": email,
            "phoneNumber": phoneNumber,
            "startsAt": startsAt,
            "endsAt": endsAt,
        ]
        
        if !youtubeUrl.isEmpty {
            params["youtubeUrl"] = youtubeUrl
        }

        if !instagramUrl.isEmpty {
            params["instagramUrl"] = instagramUrl
        }

        if !bigstarUrl.isEmpty {
            params["bigstarUrl"] = bigstarUrl
        }

        if !websiteUrl.isEmpty {
            params["websiteUrl"] = websiteUrl
        }
        
        let uuid = try! await AF.request(
            "\(baseURL)/ads/apple",
            method: .post,
            parameters: params,
            headers: headers
        ).serializingDecodable(CreateClientAds.self).value.uuid
//        AF.request(
//            "\(baseURL)/ads/apple",
//            method: .post,
//            parameters: params,
//            headers: headers
//        ).responseString { response in
//            switch response.result {
//            case .success(let text):
//                print("Text response: \(text)")
//            case .failure(let error):
//                print("Error: \(error)")
//            }
//        }
        print("Boris \(uuid)")
        return uuid
    }
}


private var accessToken: String = ""

@available(iOS 13.0.0, *)
private func uploadFile(fileData: Data) async -> String {
    print(fileData)
    
    let headers:HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    let uuid = try! await AF.upload(
        multipartFormData: { multipart in
            multipart.append(fileData, withName: "file", fileName: "test", mimeType: "")
        },  
        to: "\(baseURL)/files/upload",
        method: .post,
        headers: headers
    ).serializingDecodable(FileResponse.self).value.uuid
    
    print("File UUID: " + uuid)
    
    return uuid
}

@available(iOS 13.0.0, *)
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

@available(iOS 13.0.0, *)
private func getMyAdvertiserUuid() async -> String{
    let headers:HTTPHeaders = [
        "Authorization": "Bearer \(accessToken)"
    ]
    
    let uuid = try! await AF.request(
        "\(baseURL)/auth/me",
        method: .get,
        headers: headers
    ).serializingDecodable(MeResponse.self).value.advertiser.uuid
    print("Borislav \(uuid)")
    return uuid
}

@available(iOS 13.0.0, *)

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


private struct City: Decodable{
    var uuid: String
    var name: String
    var createdAt: String
    var updatedAt: String
    var isSelected: Bool? = false
}

@available(iOS 15.0, *)
extension AdsView {
    struct Representable: UIViewRepresentable {
        var action: () -> Void
        
        func makeCoordinator() -> PCoordinator {
            PCoordinator(action: action)
        }
        
        func makeUIView(context: Context) -> some UIView {
            context.coordinator.button
        }
        
        func updateUIView(_ uiView: UIViewType, context: Context) {
            context.coordinator.action = action
        }
    }
    
}

@available(iOS 14.0, *)
class PCoordinator: NSObject {
    var action: () -> Void
    var button = PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .automatic)
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
        
        button.addTarget(self, action: #selector(callback(_:)), for: .touchUpInside)

    }

    @objc
    func callback(_ sender: Any) {
        action()
    }
}

struct UserInfo {
    var userId: String
    var email: String
    var phoneNumber: String
}

private struct Country: Decodable {
    var uuid: String
    var name: String
    var createdAt: String
    var updatedAt: String
}

var userInfo = UserInfo(userId: "userId", email: "example@domain.com", phoneNumber: "77777777")

@available(iOS 15.0, *)
struct AdsView: View{
    @Environment(\.dismiss) var dismiss
    @StateObject var storeViewModel = StoreViewModel()
    @State var isOn = false
    @State private var thumbnail = UIImage()
    @State private var banner = UIImage()
    @State private var showSheet = false
    @State private var showSheet1 = false
    @State private var title = ""
    @State private var description = ""
    @State private var youtubeUrl = ""
    @State private var instagramUrl = ""
    @State private var bigstarUrl = ""
    @State private var websiteUrl = ""
    @State private var phoneNumber = ""
    @State private var days = 30
    @State private var categories: [AdCategory] = []
    @State private var cities: [City] = []
    @State private var countries: [Country] = []
    @State private var selectedCountryUuid: String = ""
    @State private var selectedCityUuid: String = ""
    @State private var selectedCategoryUuid: String = ""
    
    
    let periods = [30]
//    var dismissAction: (() -> Void)
//    var action: (() -> Void)
    
    
    private func fetchCountries() {
        Task {
            countries = try await AF.request(
                "\(baseURL)/countries",
                method: .get
            ).serializingDecodable([Country].self).value
        }
    }
    
    private func fetchCategories() {
        Task {
            categories = try await AF.request(
                "\(baseURL)/categories",
                method: .get
            ).serializingDecodable([AdCategory].self).value
        }
    }
    
    private func fetchCountryCities() {
        Task {
            cities = []
            cities = try await AF.request(
                "\(baseURL)/countries/\(selectedCountryUuid)/cities",
                method: .get
            ).serializingDecodable([City].self).value
            print("cities: \(cities.count)")
        }
    }
    
    
    
    
    private func fetch() {
        
        fetchCountries()
        fetchCategories()
        
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
        
        Task {
            cities = try! await AF.request(
                "\(baseURL)/cities",
                method: .get
            ).serializingDecodable([City].self).value
            
            storeViewModel.fetchProducts()
        }
    }
    
    var body: some View{
        NavigationView{
            VStack{
                Form{
                    SwiftUI.Section(header: Text("Основное")){
                        VStack(alignment: .leading) {
                            Text("Введите заголовок")
                                .padding(.top, 8)
                            TextField("Пишите здесь", text: $title)
                                .frame(height: 55)
                                .padding(.all)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }.headerProminence(.increased)
                    
                    VStack(alignment: .leading) {
                        Text("Введите описание")
                            .padding(.top, 8)
                        TextEditor(text: $description)
                            .frame(height: 55)
                            .padding(.all)
                            .border(.gray, width: 1)
                            .cornerRadius(3)
                    }
                    
                    SwiftUI.Section(header: Text("Выберите города")) {
                        List {
                            if(countries.count != 0) {
                                ForEach(0 ..< countries.count) { countryIndex in
                                    VStack(alignment: .leading){
                                        Button(action: {
                                            selectedCountryUuid = countries[countryIndex].uuid
                                            fetchCountryCities()
                                        }) {
                                            HStack {
                                                Text(countries[countryIndex].name)
                                            }
                                        }.buttonStyle(BorderlessButtonStyle())
                                        List {
                                            if(cities.count != 0 && selectedCountryUuid == countries[countryIndex].uuid) {
                                                ForEach(0 ..< cities.count) { cityIndex in
                                                    HStack {
                                                        Button(action: {
                                                            selectedCityUuid = cities[cityIndex].uuid
                                                        }) {
                                                            HStack {
                                                                if (cities[cityIndex].uuid == selectedCityUuid) {
                                                                    Image(systemName: "checkmark.circle.fill")
                                                                        .foregroundColor(.green)
                                                                        .animation(.easeIn)
                                                                } else {
                                                                    Image(systemName: "circle")
                                                                        .foregroundColor(.primary)
                                                                        .animation(.easeOut)
                                                                }
                                                                Text(cities[cityIndex].name)
                                                            }
                                                        }.buttonStyle(BorderlessButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }.headerProminence(.increased)
                    
                    SwiftUI.Section(header: Text("Выберите категорию")) {
                        List {
                            if(categories.count != 0) {
                                ForEach(0 ..< categories.count) { categoryIndex in
                                    HStack {
                                        Button(action: {
                                            let categoryUuid = categories[categoryIndex].uuid
                                            if selectedCategoryUuid == categoryUuid {
                                                selectedCategoryUuid = ""
                                            } else {
                                                selectedCategoryUuid = categoryUuid
                                            }
                                        }) {
                                            HStack {
                                                if (categories[categoryIndex].uuid == selectedCategoryUuid) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .animation(.easeIn)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.primary)
                                                        .animation(.easeOut)
                                                }
                                                Text(categories[categoryIndex].name)
                                                    .font(.system(size: 24))

                                            }
                                        }.buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                        }
                    }.headerProminence(.increased)
                    
                    SwiftUI.Section (header: Text("Выберите фото в списке диалогов")){
                        VStack{
                            Image(uiImage: self.thumbnail)
                                .resizable()
                                .cornerRadius(24)
                                .background(.black.opacity(0.2))
                                .frame(width: 390, height: 130)
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .padding(8);
                    
                                Text("Изменить фото")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .cornerRadius(16)
                                    .onTapGesture {
                                        showSheet = true
                                    }
                                    .sheet(isPresented: $showSheet) {
                                        ImagePicker(sourceType: .photoLibrary, selectedImage: self.$thumbnail)
                                    }
                                }
                        }.headerProminence(.increased)
                        
                    
                    VStack(alignment: .leading){
                        Text("Рекомендуемый размер: 390px 130px")
                        Text("Формат файла: jpg, jpeg, png")
                    }
                        
                        SwiftUI.Section(header: Text("Выберите фото при открытии")) {
                            VStack {
                                Image(uiImage: self.banner)
                                    .resizable()
                                    .cornerRadius(24)
                                    .background(.black.opacity(0.2))
                                    .frame(width: 390, height: 130)
//                                    .aspectRatio(20/9, contentMode: .fit)
                                    .clipped()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .padding(8);
                                Text("Изменить фото")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .cornerRadius(16)
                                    .onTapGesture {
                                        showSheet1 = true
                                    }
                                    .sheet(isPresented: $showSheet1) {
                                        ImagePicker(sourceType: .photoLibrary, selectedImage: self.$banner)
                                    }
                            }
                        }.headerProminence(.increased)
                        
                    VStack(alignment: .leading){
                        Text("Рекомендуемый размер: 390px 130px")
                        Text("Формат файла: jpg, jpeg, png")
                    }
                    
                        SwiftUI.Section(header: Text("Ссылки")){
                            HStack {
                                Image("instagram")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30, alignment: .leading)
                                TextField ("Вставьте ссылку", text: $instagramUrl)
                            }
                            HStack {
                                Image("website")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30, alignment: .leading)
                                TextField ("Вставьте ссылку", text: $websiteUrl)
                            }
                            HStack {
                                Image("youtube")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30, alignment: .leading)
                                TextField ("Вставьте ссылку", text: $youtubeUrl)
                            }
//                            HStack {
//                                Image("bigstar")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 30, height: 30, alignment: .leading)
//                                TextField ("Вставьте ссылку", text: $bigstarUrl)
//                            }
                            HStack {
                                Image("phoneNumber")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 30, height: 30, alignment: .leading)
                                TextField ("Вставьте номер телефона", text: $phoneNumber)
                            }
                        }.headerProminence(.increased)
                        
                        SwiftUI.Section(header: Text("Время показа       15000тг/30 дней")) {
                            Picker("Выберите количество", selection: $days) {
                                ForEach(periods.reversed(), id: \.self) {
                                    Text("\($0) \($0 == 1 ? "сутки" : "суток")")
                                }
                            }
                            .pickerStyle(.menu)
                            //                        Stepper(value: $days,
                            //                                in: 1...365,
                            //                                label: {
                            //                            Text("Период показа: \(self.days) суток")
                            //                        })
                        }.headerProminence(.increased)
                    }
                    
                    //                if !(manager.paymentSuccess) {
                    //                    Representable(action: {
                    //                        manager.pay(quantity: self.days)
                    //                    })
                    //                    .frame(minWidth: 100, maxWidth: 400)
                    //                    .frame(height: 45)
                    //                    .frame(maxWidth: .infinity)
                    //                }
                    
                    Button("Создать", action: {
                        Task {
                            _ = await login()
                            
                            let advertiserUuid = await getMyAdvertiserUuid()
                            let thumbnailUuid = await uploadFile(fileData: self.thumbnail.pngData()!)
                            let bannerUuid = await uploadFile(fileData: self.banner.pngData()!)
                            
                            let ad = Ad(
                                title: self.title,
                                description: self.description,
                                email: userInfo.email,
                                phoneNumber: self.phoneNumber,
                                cityUuids: [self.selectedCityUuid],
                                advertiserUuid: advertiserUuid,
                                thumbnailUuid: thumbnailUuid,
                                bannerUuid: bannerUuid,
                                categoryUuid: self.selectedCategoryUuid,
                                youtubeUrl: self.youtubeUrl,
                                instagramUrl: self.instagramUrl,
                                bigstarUrl: self.bigstarUrl,
                                websiteUrl: self.websiteUrl,
                                days: self.days
                            )
                            
                            let adUuid = await ad.create()
                            
                            await storeViewModel.purchase(quantity: self.days)
                            
                            if(!(storeViewModel.purchasedIds.isEmpty)){
                               
                                let payparams: [String: Any] = [
                                    "order": [
                                        "external_id": adUuid
                                    ]
                                ]
                                
                                let headers:HTTPHeaders = [
                                    "Authorization": "Bearer \(accessToken)"
                                ]
                                
                                
                                AF.request("\(baseURL)/ads/pay",
                                method: .post,
                                parameters: payparams,
                                headers: headers
                                ).responseJSON { response in
                                    print("anal \(response)")
                                }
                                dismiss()
                            }
                        }
                    })
                }
    
                .navigationTitle("Создание объявления")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: fetch)
            }
   
        }
    }
    
    
