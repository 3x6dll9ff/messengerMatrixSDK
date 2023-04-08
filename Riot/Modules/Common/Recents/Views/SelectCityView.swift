// swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire

private struct City: Decodable {
    var uuid: String
    var name: String
    var createdAt: String
    var updatedAt: String
}

private struct Country: Decodable {
    var uuid: String
    var name: String
    var createdAt: String
    var updatedAt: String
}

@available(iOS 15.0, *)
struct SelectCityView: View {
    @State private var isAlertShowing: Bool = false
    @State private var countries: [Country] = []
    @State private var cities: [City] = []
    @State private var selectedCountryUuid: String = ""
    @State private var selectedCityUuid: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    SwiftUI.Section {
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
                }
                Button("Сохранить", action: {
                    Task {
                        if (selectedCityUuid.count > 0) {
                            UserDefaults.standard.set(selectedCityUuid, forKey: "cityUuid")
                            dismiss()
                   
                        } else {
                            isAlertShowing = true
                        }
                    }
                })
            }
            .navigationTitle("Выберите ваш город")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: fetch)
            .alert("Вы не выбрали город", isPresented: $isAlertShowing) {
                Button("Хорошо", role: .cancel) { }
            }
        }
    }
    
    

    private func fetch() {
        Task {
            countries = try await AF.request(
                "\(baseURL)/countries",
                method: .get
            ).serializingDecodable([Country].self).value
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
}
