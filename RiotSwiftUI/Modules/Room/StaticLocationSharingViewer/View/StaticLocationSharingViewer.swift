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

@available(iOS 14.0, *)
struct StaticLocationSharingViewer: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: StaticLocationSharingViewerViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                LocationSharingMapView(tileServerMapURL: viewModel.viewState.mapStyleURL,
                                       annotations: [viewModel.viewState.sharedAnnotation],
                                       highlightedAnnotation: viewModel.viewState.sharedAnnotation,
                                       userAvatarData: viewModel.viewState.userAvatarData,
                                       showsUserLocation: false,
                                       userLocation: Binding.constant(nil),
                                       mapCenterCoordinate: Binding.constant(nil),
                                       errorSubject: viewModel.viewState.errorSubject)
                MapCreditsView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(VectorL10n.cancel, action: {
                        viewModel.send(viewAction: .cancel)
                    })
                }
                ToolbarItem(placement: .principal) {
                    Text(VectorL10n.locationSharingTitle)
                        .font(.headline)
                        .foregroundColor(theme.colors.primaryContent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.send(viewAction: .share)
                    } label: {
                        Image(uiImage: Asset.Images.locationShareIcon.image)
                            .accessibilityIdentifier("LocationSharingView.shareButton")
                    }
                    .disabled(!viewModel.viewState.shareButtonEnabled)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .introspectNavigationController { navigationController in
                ThemeService.shared().theme.applyStyle(onNavigationBar: navigationController.navigationBar)
            }
            .alert(item: $viewModel.alertInfo) { info in
                info.alert
            }
        }
        .accentColor(theme.colors.accent)
        .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var activityIndicator: some View {
        if viewModel.viewState.showLoadingIndicator {
            ActivityIndicator()
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct StaticLocationSharingViewer_Previews: PreviewProvider {
    static let stateRenderer = MockStaticLocationSharingViewerScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
