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

import SwiftUI

struct OnboardingMainScreen: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack{
            Text("Big Star Messenger Your business partner")
                .font(theme.fonts.title1B)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.center)
            
            Image("onboarding_center_circle_dark")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            Text("Big Star Messenger Your business partner")
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.center)
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

#Preview {
    OnboardingMainScreen()
}
