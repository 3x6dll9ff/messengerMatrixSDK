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

import Combine
import CoreLocation
import XCTest

@testable import RiotSwiftUI

class LiveLocationSharingViewerViewModelTests: XCTestCase {
    var service: MockLiveLocationSharingViewerService!
    var viewModel: LiveLocationSharingViewerViewModelProtocol!
    var context: LiveLocationSharingViewerViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockLiveLocationSharingViewerService()
        viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: BuildSettings.defaultTileServerMapStyleURL, service: service)
        context = viewModel.context
    }
    
    func testIsUserBeingShared() {
        XCTAssertTrue(context.viewState.isCurrentUserShared)
    }
    
    func testToggleShowUserLocation() {
        let service = MockLiveLocationSharingViewerService(currentUserSharingLocation: false)
        let viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: BuildSettings.defaultTileServerMapStyleURL, service: service)
        XCTAssertFalse(viewModel.context.viewState.isCurrentUserShared)
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .hide)
        viewModel.context.send(viewAction: .showUserLocation)
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .follow)
        viewModel.context.send(viewAction: .tapListItem("@bob:bigstarmessenger.com"))
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .show)
    }
}
