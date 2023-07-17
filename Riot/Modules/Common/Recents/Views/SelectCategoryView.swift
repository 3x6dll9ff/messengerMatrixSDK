// swiftlint:disable all

import Foundation
import SwiftUI
import Alamofire

struct AdCategory: Decodable {
    var uuid: String
    var name: String
    var createdAt: String
    var updatedAt: String
}

@available(iOS 15.0, *)
struct SelectCategoryView: View {
    @State private var categories: [AdCategory] = []
    @State private var selectedCategoryUuid: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Form {
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
                    }.headerProminence(.increased)
                }
                Button("Сохранить", action: {
                    Task {
                        UserDefaults.standard.set(selectedCategoryUuid, forKey: "categoryUuid")
                        dismiss()
                    }
                })
            }
            .navigationTitle("Выберите категорию")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetch()
                setInitialCategory()
            }
        }
    }
    
    private func getStoredCategoryUuid() -> String?{
        return UserDefaults.standard.string(forKey: "categoryUuid")
    }
    
    private func setInitialCategory () {
        let categoryUuid = getStoredCategoryUuid()
        selectedCategoryUuid = categoryUuid ?? ""
    }

    private func fetch() {
        Task {
            categories = try await AF.request(
                "\(baseURL)/categories",
                method: .get
            ).serializingDecodable([AdCategory].self).value
        }
    }
}
