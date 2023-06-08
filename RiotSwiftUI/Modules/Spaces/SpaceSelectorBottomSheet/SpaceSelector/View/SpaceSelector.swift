//
// Copyright 2021 New Vector Ltd
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

import SwiftUI

@available(iOS 15.0, *)
struct SpaceSelector: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceSelectorViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack (alignment: .leading){
                LazyHStack {
                    Image(systemName: "square.and.arrow.up")
                    NavigationLink(destination: AdsView()) {
                        Text("Подача рекламы")
                            .foregroundColor(.purple)
                    }
                }
                LazyHStack {
                    Image(systemName: "globe.asia.australia")
                    NavigationLink(destination: SelectCityView()) {
                        Text("Выбор города")
                            .foregroundColor(.purple)
                    }
                }
                LazyHStack {
                    Image(systemName: "person.crop.square")
                    NavigationLink(destination: AdvertiserPanelView()) {
                        Text("Кабинет рекламодателя")
                            .foregroundColor(.purple)
                    }
                }
                LazyHStack {
                    Image(systemName: "externaldrive.badge.icloud")
                     
                        Text("Облачное хранилище")
                            .foregroundColor(.purple)
                    
                }
            } .padding(10)
        }
        .frame(maxHeight: .infinity)
        .background(theme.colors.background.edgesIgnoringSafeArea(.all))
        .navigationTitle(viewModel.viewState.navigationTitle)
        .toolbar {
//            ToolbarItem(placement: .confirmationAction) {
//                Button(VectorL10n.create) {
//                    viewModel.send(viewAction: .createSpace)
//                }
//            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
        .accentColor(.purple)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct SpaceSelector_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceSelectorScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
