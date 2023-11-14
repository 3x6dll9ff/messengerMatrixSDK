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

/// The splash screen shown at the beginning of the onboarding flow.
struct OnboardingSplashScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var isLeftToRight: Bool { layoutDirection == .leftToRight }
    private var pageCount: Int { viewModel.viewState.content.count }
    
    /// A timer to automatically animate the pages.
    @State private var pageTimer: Timer?
    /// The amount of offset to apply when a drag gesture is in progress.
    @State private var dragOffset: CGFloat = .zero
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    
    var body: some View {
        VStack{
            Spacer()
            
            VStack{
                Image("onboarding_center_circle")
                    .resizable()
                    .frame(width: w/2, height: (w/2)-(w*0.02))
                    .scaledToFit()
                
                Spacer().frame(height: 1)
                
                OnboardingSplashScreenPage(viewModel: viewModel)
            }
            .background(
                theme.isDark
                ?
                Image("bg_3_dark")
                    .resizable()
                    .frame(width: w/1.115, height: h*0.72)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 10, y: 10)
                :
                Image("bg_3_light")
                    .resizable()
                    .frame(width: w/1.115, height: h*0.72)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 10, y: 10)
            )
            
            Spacer().frame(height: 35)
        }
        .background(background.ignoresSafeArea())
    }
    
    @ViewBuilder
    /// The view's background, showing a gradient in light mode and a solid colour in dark mode.
    var background: some View {
        if !theme.isDark {
            Image("onboarding_background_light")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        } else {
            Image("onboarding_background_dark")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
}
// MARK: - Previews

struct OnboardingSplashScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingSplashScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
