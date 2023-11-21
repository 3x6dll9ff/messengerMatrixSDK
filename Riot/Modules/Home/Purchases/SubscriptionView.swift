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

// swiftlint:disable all

import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @State private var offerings: Offerings?
    @State private var selectedPackage: Package?
    @State private var shakePlans: CGFloat = 0

    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    
    var infoView: some View{
        VStack{
            Image("onboarding_center_circle")
                .resizable()
                .frame(width: w/2, height: w/2)
            Spacer().frame(height: 20)
            Text("Bigstar +")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("More features, no advertising and only benefits for your business!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom)
        }
    }

    var plansView: some View {
        VStack(spacing: 16) {
            if let offerings = offerings, let currentOffering = offerings.current {
                ForEach(currentOffering.availablePackages, id: \.identifier) { package in
                    PlanView(package: package, isSelected: selectedPackage?.identifier == package.identifier) {
                        selectedPackage = package
                    }
                }
            } else {
                Text("Loading plans...")
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
        .padding(.horizontal)
        .modifier(ShakeEffect(animatableData: shakePlans))
        .onAppear {
            Purchases.shared.getOfferings { (offerings, error) in
                if let error = error {
                    print("Error fetching offerings: \(error)")
                } else {
                    self.offerings = offerings
                }
            }
        }
    }

    var benefitsView: some View {
        VStack(spacing: 16) {
            FeatureView(assetName: "vip_no_ads", featureName: "No advertising")
            FeatureView(assetName: "vip_calls", featureName: "Calls from any city")
            FeatureView(assetName: "vip_design", featureName: "New chat design")
            FeatureView(assetName: "vip_voice", featureName: "Voice recognition")
            FeatureView(assetName: "vip_emoji", featureName: "New emoji")
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    var submitButtonText: String {
        if let package = selectedPackage {
            return "Connect for \(package.localizedPriceString)"
        } else {
            return "Select an offer"
        }
    }

    var submitButtonView: some View {
        Button(action: {
            purchaseSelectedPackage()
        }) {
            Text(submitButtonText)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.76, green: 0.45, blue: 0.67), location: 0),
                        .init(color: Color(red: 0.51, green: 0.39, blue: 0.8), location: 0.33),
                        .init(color: Color(red: 0.66, green: 0.55, blue: 0.95), location: 0.65),
                        .init(color: Color(red: 0.39, green: 0.33, blue: 0.55), location: 1),
                    ]),
                    startPoint: UnitPoint(x: 0.15, y: 0.75),
                    endPoint: UnitPoint(x: 1, y: 0.79)
                ))
                .cornerRadius(10)
        }
        .padding()
    }

    var body: some View {
        VStack {
            infoView
            plansView
            benefitsView
            submitButtonView
        }
        .background(Color(red: 0.12, green: 0.13, blue: 0.14))
        .cornerRadius(20)
        .padding()
    }
    
    func purchaseSelectedPackage() {
        if let package = selectedPackage {
            Purchases.shared.purchase(package: package) { (transaction, info, error, userCancelled) in
                RevenueCatUtils.checkVipStatus(onVipStatusChecked: {_ in })

                if let error = error {
                    print("Ошибка покупки: \(error.localizedDescription)")
                } else if userCancelled {
                    print("Покупка отменена пользователем")
                } else {
                    print("Покупка успешно совершена")
                }
            }
        } else {
            print("Пакет не выбран")
            withAnimation(.default) {
                self.shakePlans += 1
            }
        }
    }
}

struct FeatureView: View {
    var assetName: String
    var featureName: String
    
    var body: some View {
        HStack {
            Image(assetName)
                .resizable()
                .frame(maxWidth: 24, maxHeight: 24)
            Text(featureName)
            Spacer()
        }
        
    }
}

struct PlanView: View {
    let package: Package
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                Text(package.storeProduct.localizedTitle)
                Spacer()
                Text(package.localizedPriceString)
            }
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
    }
}


//struct SubscriptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        SubscriptionView()
//    }
//}

//#Preview {
//    SubscriptionView()
//}
