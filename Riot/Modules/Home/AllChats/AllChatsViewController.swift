//
// Copyright 2022 New Vector Ltd
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


import UIKit
import ImageSlideshow
import Alamofire
import Foundation
import Reusable
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import QuickLook

struct AdSlide {
    let clientAd: ClientAds
    let image: ImageSource
}

@available(iOS 15.0, *)
protocol AllChatsViewControllerDelegate: AnyObject {
    func allChatsViewControllerDidCompleteAuthentication(_ allChatsViewController: AllChatsViewController)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomWithParameters roomNavigationParameters: RoomNavigationParameters, completion: @escaping () -> Void)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomPreviewWithParameters roomPreviewNavigationParameters: RoomPreviewNavigationParameters, completion: (() -> Void)?)
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectContact contact: MXKContact, with presentationParameters: ScreenPresentationParameters)
}

@available(iOS 15.0, *)
class AllChatsViewController: HomeViewController, ImageSlideshowDelegate, UIGestureRecognizerDelegate {
    // MARK: - Class methods
    
    static override func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self.classForCoder()))
    }
    
    static override func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "AllChatsViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    
    
    @IBOutlet weak var slideshow: ImageSlideshow!
   
    @IBAction func show(_ sender: Any) {
        didTapAd()
    }
    
    let db = Firestore.firestore()
    var currentUserId = ""
    var ads = [AdSlide]()
    var clientAds: [ClientAds] = []
    var cityUuid: String = ""
    var tapGestureRecognizer: UITapGestureRecognizer!
    var previewItemData: Data?
    var previewItemTitle: String?
    var previewItemFileExtension: String?
    var documents: [QueryDocumentSnapshot]? = []
    
    // MARK: - Properties
    
    weak var allChatsDelegate: AllChatsViewControllerDelegate?
    
    // MARK: - Private
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let spaceActionProvider = AllChatsSpaceActionProvider()
    
    private let editActionProvider = AllChatsEditActionProvider()

    private var spaceSelectorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter?
    
    private var childCoordinators: [Coordinator] = []
    
    private let tableViewPaginationThrottler = MXThrottler(minimumDelay: 0.1)
    
    private let reviewSessionAlertSnoozeController = ReviewSessionAlertSnoozeController()
    
    private var bannerView: UIView? {
        didSet {
            bannerView?.translatesAutoresizingMaskIntoConstraints = false
            set(tableHeadeView: bannerView)
        }
    }
    
    private var isOnboardingCoordinatorPreparing: Bool = false

    private var theme: Theme {
        ThemeService.shared().theme
    }

    @IBOutlet private var toolbar: UIToolbar!
    private var isToolbarHidden: Bool = false {
        didSet {
            if isViewLoaded {
                toolbar.transform = isToolbarHidden ? CGAffineTransform(translationX: 0, y: 2 * toolbarHeight) : .identity
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setToolbarHidden(_ isHidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.isToolbarHidden = false
        }

    }
    
    // MARK: - SplitViewMasterViewControllerProtocol
    
    // References on the currently selected room
    private(set) var selectedRoomId: String?
    private(set) var selectedEventId: String?
    private(set) var selectedRoomSession: MXSession?
    private(set) var selectedRoomPreviewData: RoomPreviewData?
    
    // References on the currently selected contact
    private(set) var selectedContact: MXKContact?
    
    // Reference to the current onboarding flow. It is always nil unless the flow is being presented.
    private(set) var onboardingCoordinatorBridgePresenter: OnboardingCoordinatorBridgePresenter?
    
    // Tell whether the onboarding screen is preparing.
    private(set) var isOnboardingInProgress: Bool = false
    
    private var toolbarHeight: CGFloat = 0

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TEST: viewDidLoad")
        
        editActionProvider.delegate = self
        spaceActionProvider.delegate = self
        
        recentsTableView.tag = RecentsDataSourceMode.allChats.rawValue
        recentsTableView.clipsToBounds = false
        recentsTableView.register(RecentEmptySectionTableViewCell.nib, forCellReuseIdentifier: RecentEmptySectionTableViewCell.reuseIdentifier)
        recentsTableView.register(RecentEmptySpaceSectionTableViewCell.nib, forCellReuseIdentifier: RecentEmptySpaceSectionTableViewCell.reuseIdentifier)
        recentsTableView.register(RecentsInvitesTableViewCell.nib, forCellReuseIdentifier: RecentsInvitesTableViewCell.reuseIdentifier)
        recentsTableView.contentInsetAdjustmentBehavior = .automatic
        
        toolbarHeight = toolbar.frame.height
        emptyViewBottomAnchor = toolbar.topAnchor
        
        
        slideshow.isUserInteractionEnabled = true

        slideshow.slideshowInterval = 5.0
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFill
        slideshow.activityIndicator = DefaultActivityIndicator()
        slideshow.delegate = self
        
        updateUI()
        
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(self.setupEditOptions), name: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateBadgeButton), name: MXSpaceNotificationCounter.didUpdateNotificationCount, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("TEST: viewWillAppear")

        fetchAds()
        self.toolbar.tintColor = theme.colors.accent
        if self.navigationItem.searchController == nil {
            self.navigationItem.searchController = searchController
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didInitialise, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceListDidChange), name: MXSpaceService.didBuildSpaceGraph, object: nil)
        
        set(tableHeadeView: self.bannerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("TEST: viewDidAppear")

        // Check whether we're not logged in
        let authIsShown: Bool
        if MXKAccountManager.shared().accounts.isEmpty {
            showOnboardingFlow()
            authIsShown = true
        } else {
            // Display a login screen if the account is soft logout
            // Note: We support only one account
            if let account = MXKAccountManager.shared().accounts.first, account.isSoftLogout {
                showSoftLogoutOnboardingFlow(with: account.mxCredentials)
                authIsShown = true
            } else {
                authIsShown = false
            }
        }
                
        guard !authIsShown else {
            return
        }
        
        AppDelegate.theDelegate().checkAppVersion()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("TEST: viewWillTransition")
        
        coordinator.animate { context in
            self.recentsTableView?.tableHeaderView?.layoutIfNeeded()
            self.recentsTableView?.tableHeaderView = self.recentsTableView?.tableHeaderView
        }
    }
    
    // MARK: - Public
    func acceptPendingFile(filePath: String, documentID: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to the pending file
        let pendingRef = storageRef.child(filePath)
        
        // Define the path for the saved file
        let savedPath = filePath.replacingOccurrences(of: "/pending/", with: "/saved/")
        let savedRef = storageRef.child(savedPath)
        
        // Download the pending file
        pendingRef.getData(maxSize: 1 * 1024 * 1024 * 1024) { data, error in
            if let error = error {
                // Uh-oh, an error occurred while downloading the file
                print("Error downloading file:", error)
                return
            }
            
            // Upload the downloaded file to the saved path
            savedRef.putData(data!, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred while uploading the file
                    print("Error uploading file:", error ?? "Unknown error")
                    return
                }
                
                // Delete the pending file
                pendingRef.delete { error in
                    if let error = error {
                        // Uh-oh, an error occurred while deleting the file
                        print("Error deleting file:", error)
                    } else {
                        // File deleted successfully
                        print("File deleted successfully")
                        
                        self.db.collection("cloud").document(documentID).setData([ "status": "Accepted", "filePath": savedPath ], merge: true) { err in
                            if let err = err {
                                print("Error updating document status: \(err)")
                            } else {
                                print("Document status successfully updated!")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func firestoreDocumentsUpdateHandler(documents: [QueryDocumentSnapshot]) {
        print("TSETSETSET \(documents)")
        
        let storage = Storage.storage(url: storageUrl)
        let storageRef = storage.reference()
        
        for document in documents {
            let senderName = (document["senderName"] ?? "") as! String
            let filePath = document["filePath"]! as! String
            let fileName = filePath.components(separatedBy: "/").last ?? ""
            let fileRef = storageRef.child(filePath)
            
            fileRef.getData(maxSize: 1 * 1024 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading file: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "\(senderName) отправил файл в облако", message: fileName, preferredStyle: .alert)
                    
                    let rejectAction = UIAlertAction(title: "Отклонить", style: .destructive) { _ in
                        // Delete the file
                        fileRef.delete { error in
                            if let error = error {
                                print("Error removing file: \(error)")
                            } else {
                                self.db.collection("cloud").document(document.documentID).setData([ "status": "Rejected" ], merge: true) { err in
                                    if let err = err {
                                        print("Error updating document status: \(err)")
                                    } else {
                                        print("Document status successfully updated!")
                                    }
                                }
                            }
                        }
                    }
                    
                    let acceptAction = UIAlertAction(title: "Принять", style: .default) { _ in
                        self.acceptPendingFile(filePath: filePath, documentID: document.documentID)
                    }
                    
                    let previewAction = UIAlertAction(title: "Просмотр", style: .default) { _ in
                        // Открыть предпросмотр файла
                        if let data = data {
                            let previewController = QLPreviewController()
                            previewController.dataSource = self
                            previewController.currentPreviewItemIndex = 0
                            
                            // Передать данные файла в просмотрщик
                            self.previewItemData = data
                            
                            // Получить расширение файла
                            let fileExtension = (fileName as NSString).pathExtension
                            
                            // Установить расширение файла для просмотрщика
                            self.previewItemTitle = fileName
                            self.previewItemFileExtension = fileExtension
                            
                            // Показать просмотрщик
                            if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                                previewController.delegate = self
                                viewController.present(previewController, animated: true, completion: nil)
                            }
                        }
                    }
                    alertController.addAction(previewAction)
                    alertController.addAction(rejectAction)
                    alertController.addAction(acceptAction)
                    
                    // Показать модальное окно
                    if let viewController = UIApplication.shared.keyWindow?.rootViewController {
                        viewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func watchFirestore (userId: String) {
        if (currentUserId == userId) {
            return
        }
        
        currentUserId = userId
        db.collection("cloud")
            .whereField("recipientID", isEqualTo: userId)
            .whereField("status", isEqualTo: "Pending")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                self.documents = documents
                self.firestoreDocumentsUpdateHandler(documents: documents)
                let filePaths = documents.map { $0.documentID }
                print("Current documents (uuid: \(userId)): \(filePaths)")
            }
    }
    
    func switchSpace(withId spaceId: String?) {
        searchController.isActive = false

        guard let spaceId = spaceId else {
            dataSource?.currentSpace = nil
            updateUI()

            return
        }

        guard let space = self.mainSession.spaceService.getSpace(withId: spaceId) else {
            MXLog.warning("[AllChatsViewController] switchSpace: no space found with id \(spaceId)")
            return
        }
        
        dataSource?.currentSpace = space
        updateUI()
        
        self.recentsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    override var recentsDataSourceMode: RecentsDataSourceMode {
        .allChats
    }
    
    override func addMatrixSession(_ mxSession: MXSession!) {
        super.addMatrixSession(mxSession)
        
        if let dataSource = dataSource, !dataSource.mxSessions.contains(where: { $0 as? MXSession == mxSession }) {
            dataSource.addMatrixSession(mxSession)
            // Setting the delegate is required to send a RecentsViewControllerDataReadyNotification.
            // Without this, when clearing the cache we end up with an infinite green spinner.
            (dataSource as? RecentsDataSource)?.setDelegate(self, andRecentsDataSourceMode: recentsDataSourceMode)
        } else {
            initDataSource()
        }
    }
    
    override func removeMatrixSession(_ mxSession: MXSession!) {
        super.removeMatrixSession(mxSession)
        
        guard let dataSource = dataSource else { return }
        dataSource.removeMatrixSession(mxSession)
        
        if dataSource.mxSessions.isEmpty {
            // The user logged out -> we need to reset the data source
            displayList(nil)
        }
    }
    
    private func initDataSource() {
        guard self.dataSource == nil, let mainSession = self.mxSessions.first as? MXSession else {
            return
        }
        
        MXLog.debug("[AllChatsViewController] initDataSource")
        let recentsListService = RecentsListService(withSession: mainSession)
        let recentsDataSource = RecentsDataSource(matrixSession: mainSession, recentsListService: recentsListService)
        displayList(recentsDataSource)
        recentsDataSource?.setDelegate(self, andRecentsDataSourceMode: self.recentsDataSourceMode)
    }
    
    @objc private func spaceListDidChange() {
        guard self.editActionProvider.shouldUpdate(with: self.mainSession, parentSpace: self.dataSource?.currentSpace) else {
            return
        }
        
        updateUI()
    }

    @objc private func addFabButton() {
        // Nothing to do. We don't need FAB
    }

    @objc private func sections() -> Array<Int> {
        return [
            RecentsDataSourceSectionType.directory.rawValue,
            RecentsDataSourceSectionType.invites.rawValue,
            RecentsDataSourceSectionType.favorites.rawValue,
            RecentsDataSourceSectionType.people.rawValue,
            RecentsDataSourceSectionType.allChats.rawValue,
            RecentsDataSourceSectionType.lowPriority.rawValue,
            RecentsDataSourceSectionType.serverNotice.rawValue,
            RecentsDataSourceSectionType.suggestedRooms.rawValue,
            RecentsDataSourceSectionType.breadcrumbs.rawValue
        ]
    }
    
    private func fetchImages(){
        for clientAd in self.clientAds {
            AF.request("\(baseURL)/files/\(clientAd.thumbnailUuid)").responseImage { response in
                let ad = AdSlide (
                    clientAd: clientAd,
                    image:ImageSource(image: response.value!)
                )
                self.ads.append(ad)
                self.slideshow.setImageInputs(self.ads.map { $0.image })
            }
        }
    }
    
    private func getStoredCityUuid() -> String?{
        return UserDefaults.standard.string(forKey: "cityUuid")
    }
    
    private func getStoredCategoryUuid() -> String?{
        return UserDefaults.standard.string(forKey: "categoryUuid")
    }
    
    private func staticCityUuid() {
        return UserDefaults.standard.set("2c53b916-234d-4b24-9271-70e30dbdfca7", forKey: "cityUuid")
    }
    
    private func fetchAds(){
        staticCityUuid()
        
        let cityUuid = getStoredCityUuid()
        let categoryUuid = getStoredCategoryUuid()

       
        print("привет как дела \(cityUuid)")
        
        
        if cityUuid != nil {
            var parameters: [String: Any] = [
                "cityUuid": cityUuid!
            ]

            if let categoryUuid = categoryUuid, !categoryUuid.isEmpty {
                parameters["categoryUuid"] = categoryUuid
            }

            AF.request("\(baseURL)/ads/client", parameters: parameters).responseDecodable(of: [ClientAds].self) { response in
                if (response.value != nil && !response.value!.isEmpty) {
                    print(response.value!)
                    self.clientAds = response.value!
                    self.ads = []
                    self.fetchImages()
                }
            }
            
            
        }
    }
    
    func sendAdClickRequest(adUuid: String){
        Task {
            print("adUuid: \(adUuid)")
            let clickedAd = try await AF.request(
                "\(baseURL)/ads/\(adUuid)/click",
                method: .patch
            ).serializingDecodable(AdvertiserAds.self).value
            print("clickedAd: \(clickedAd.showsNumber)")
            print("clickedAd: \(clickedAd.clicksNumber)")
        }
    }
    
    @objc func didTapAd(){
        let clientAd = self.ads[slideshow.currentPage].clientAd
            
        if #available(iOS 15.0, *) {
            let adSheetView = AdSheetView(
                clientAd: clientAd
            )
            
            let adSheetViewController = UIHostingController(rootView: adSheetView)
            
            if let presentationController = adSheetViewController.presentationController as? UISheetPresentationController {
                if #available(iOS 16.0, *) {
                    presentationController.detents = [
                        .custom { _ in
                            var myDefaultHeight: CGFloat = 452
                            let deviceType = UIDevice().type.rawValue
                            print(deviceType)
                            if (deviceType == "iPhone 14 Pro Max") {
                                myDefaultHeight = 530
                            } else if (deviceType == "iPhone 13 Pro Max") {
                                myDefaultHeight = 530
                            } else if (deviceType == "iPhone 12 Pro Max") {
                                myDefaultHeight = 530
                            }
                            return myDefaultHeight
                        }
                    ]
                } else {
                    // Fallback on earlier versions
                }
            }
                
            present(adSheetViewController, animated: true)
        } else {
            // Fallback on earlier versions
        }
            
        }
    
    override func startActivityIndicator() {
        super.startActivityIndicator()
    }
    
    // MARK: - Actions
    
    @objc private func showSpaceSelectorAction(sender: AnyObject) {
        Analytics.shared.viewRoomTrigger = .roomList
        let currentSpaceId = dataSource?.currentSpace?.spaceId ?? SpaceSelectorConstants.homeSpaceId
        let spaceSelectorBridgePresenter = SpaceSelectorBottomSheetCoordinatorBridgePresenter(session: self.mainSession, selectedSpaceId: currentSpaceId, showHomeSpace: true)
        spaceSelectorBridgePresenter.present(from: self, animated: true)
        spaceSelectorBridgePresenter.delegate = self
        self.spaceSelectorBridgePresenter = spaceSelectorBridgePresenter
    }
    
    // MARK: - UITableViewDataSource
    
    private func sectionType(forSectionAt index: Int) -> RecentsDataSourceSectionType? {
        guard let recentsDataSource = dataSource as? RecentsDataSource else {
            return nil
        }
        
        return recentsDataSource.sections.sectionType(forSectionIndex: index)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = sectionType(forSectionAt: section), sectionType == .invites else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        
        return dataSource?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        guard let dataSource = dataSource else {
            MXLog.failure("Missing data source")
            return UITableViewCell()
        }
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        return dataSource?.cellHeight(at: indexPath) ?? 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionType = sectionType(forSectionAt: indexPath.section), sectionType == .invites else {
            super.tableView(tableView, didSelectRowAt: indexPath)
            return
        }

        showRoomInviteList()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

        guard let recentsDataSource = dataSource as? RecentsDataSource else {
            return
        }
        
        let sectionType = recentsDataSource.sections.sectionType(forSectionIndex: indexPath.section)
        // We need to trottle a bit earlier so the next section is not visible even if the tableview scrolls faster
        guard sectionType == .allChats, let numberOfRowsInSection = recentsDataSource.recentsListService.allChatsRoomListData?.counts.numberOfRooms, indexPath.row == numberOfRowsInSection - 4 else {
            return
        }
        
        tableViewPaginationThrottler.throttle {
            recentsDataSource.paginate(inSection: indexPath.section)
        }
    }

    // MARK: - Toolbar animation
    
    private var initialScrollPosition: Double = 0
    
    private func scrollPosition(of scrollView: UIScrollView) -> Double {
        return scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == recentsTableView else {
            return
        }
        
        initialScrollPosition = scrollPosition(of: scrollView)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        guard scrollView == recentsTableView else {
            return
        }
        
        let scrollPosition = scrollPosition(of: scrollView)
        
        if !self.recentsTableView.isDragging && scrollPosition == 0 && self.isToolbarHidden == true {
            self.setToolbarHidden(false, animated: true)
        }

        guard self.recentsTableView.isDragging else {
            return
        }

        guard scrollPosition > 0 && scrollPosition < self.recentsTableView.contentSize.height - self.recentsTableView.bounds.height else {
            return
        }

        let isToolBarHidden: Bool = scrollPosition - initialScrollPosition > 0
        if isToolBarHidden != self.isToolbarHidden {
            self.setToolbarHidden(isToolBarHidden, animated: true)
        }
    }
    
    // MARK: - Empty view management
    
    override func updateEmptyView() {
        guard let mainSession = self.mainSession else {
            return
        }
        
        let title: String
        let informationText: String
        if let currentSpace = self.dataSource?.currentSpace {
            title = VectorL10n.allChatsEmptyViewTitle(currentSpace.summary?.displayName ?? VectorL10n.spaceTag)
            informationText = VectorL10n.allChatsEmptySpaceInformation
        } else {
            let myUser = mainSession.myUser
            let displayName = (myUser?.displayName ?? myUser?.userId) ?? ""
            let appName = AppInfo.current.displayName
            title = VectorL10n.homeEmptyViewTitle(appName, displayName)
            informationText = VectorL10n.allChatsEmptyViewInformation
            
            if let userId = myUser?.userId {
                watchFirestore(userId: userId)
            }
        }
        
        self.emptyView?.fill(with: emptyViewArtwork,
                             title: title,
                             informationText: informationText)        
    }
    
    private var emptyViewArtwork: UIImage {
        if self.dataSource?.currentSpace == nil {
            return ThemeService.shared().isCurrentThemeDark() ? Asset.Images.allChatsEmptyScreenArtworkDark.image : Asset.Images.allChatsEmptyScreenArtwork.image
        } else {
            return ThemeService.shared().isCurrentThemeDark() ? Asset.Images.allChatsEmptySpaceArtworkDark.image : Asset.Images.allChatsEmptySpaceArtwork.image
        }
    }
    
    override func shouldShowEmptyView() -> Bool {
        let shouldShowEmptyView = super.shouldShowEmptyView() && !AllChatsLayoutSettingsManager.shared.hasAnActiveFilter
        
        if shouldShowEmptyView {
            self.navigationItem.searchController = nil
            navigationItem.largeTitleDisplayMode = .never
        } else {
            self.navigationItem.searchController = searchController
            navigationItem.largeTitleDisplayMode = .automatic
        }

        return shouldShowEmptyView
    }
    

    // MARK: - Theme management
    
    override func userInterfaceThemeDidChange() {
        super.userInterfaceThemeDidChange()
        
        guard self.toolbarItems != nil else {
            return
        }
        
        self.update(with: theme)
    }
    
    private func update(with theme: Theme) {
        self.navigationController?.toolbar?.tintColor = theme.colors.accent
    }
    
    // MARK: - Private
    
    private func set(tableHeadeView: UIView?) {
        guard let tableView = recentsTableView else {
            return
        }
        
        tableView.tableHeaderView = tableHeadeView
        tableView.tableHeaderView?.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = self.recentsTableView?.tableHeaderView
    }

    @objc private func setupEditOptions() {
        guard let currentSpace = self.dataSource?.currentSpace else {
            updateRightNavigationItem(with: AllChatsActionProvider().menu)
            return
        }
        
        updateRightNavigationItem(with: spaceActionProvider.updateMenu(with: mainSession, space: currentSpace) { [weak self] menu in
            self?.updateRightNavigationItem(with: menu)
        })
    }

    private func updateUI() {
        let currentSpace = self.dataSource?.currentSpace
        self.title = currentSpace?.summary?.displayName ?? VectorL10n.allChatsTitle
        
        setupEditOptions()
        updateToolbar(with: editActionProvider.updateMenu(with: mainSession, parentSpace: currentSpace, completion: { [weak self] menu in
            self?.updateToolbar(with: menu)
        }))
        updateEmptyView()
        updateBadgeButton()
    }
    
    private func updateRightNavigationItem(with menu: UIMenu) {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
    }
    
    private lazy var spacesButton: BadgedBarButtonItem = {
        let innerButton = UIButton(type: .system)
        innerButton.accessibilityLabel = VectorL10n.spaceSelectorTitle
        innerButton.addTarget(self, action: #selector(self.showSpaceSelectorAction(sender:)), for: .touchUpInside)
        innerButton.setImage(Asset.Images.allChatsSpacesIcon.image, for: .normal)
        return BadgedBarButtonItem(withBaseButton: innerButton, theme: theme)
    }()
    
    @objc private func updateBadgeButton() {
        guard isViewLoaded, let session = mainSession else {
            return
        }
        
        let notificationCount = session.spaceService.missedNotificationsCount
        let hasSpaceInvite = session.spaceService.hasSpaceInvite
        let isBadgeHighlighed = session.spaceService.hasHighlightNotification || hasSpaceInvite
        let badgeValue: String
        
        switch notificationCount {
        case 0:
            badgeValue = "\(notificationCount)"
        case (1 ... Constants.spacesButtonMaxCount):
            badgeValue = "\(notificationCount)"
        default:
            badgeValue = "\(Constants.spacesButtonMaxCount)+"
        }
        
        spacesButton.badgeText = badgeValue
        spacesButton.badgeBackgroundColor = isBadgeHighlighed ? theme.noticeColor : theme.noticeSecondaryColor
    }
    
    private func updateToolbar(with menu: UIMenu) {
        guard isViewLoaded else {
            return
        }
        
        self.isToolbarHidden = false
        self.update(with: theme)
        
        self.toolbar.items = [
            spacesButton,
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(image: Asset.Images.allChatsEditIcon.image, menu: menu)
        ]
    }
    
    private func showCreateSpace(parentSpaceId: String?) {
        let coordinator = SpaceCreationCoordinator(parameters: SpaceCreationCoordinatorParameters(session: self.mainSession, parentSpaceId: parentSpaceId))
        let presentable = coordinator.toPresentable()
        self.present(presentable, animated: true, completion: nil)
        coordinator.callback = { [weak self] result in
            guard let self = self else {
                return
            }
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.remove(childCoordinator: coordinator)
                switch result {
                case .cancel:
                    break
                case .done(let spaceId):
                    self.switchSpace(withId: spaceId)
                }
            }
        }
        add(childCoordinator: coordinator)
        coordinator.start()
    }
    
    private func add(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    private func remove(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    private func showSpaceInvite() {
        guard let session = mainSession, let spaceRoom = dataSource?.currentSpace?.room else {
            return
        }
        
        let coordinator = ContactsPickerCoordinator(session: session, room: spaceRoom, initialSearchText: nil, actualParticipants: nil, invitedParticipants: nil, userParticipant: nil)
        coordinator.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        present(coordinator.toPresentable(), animated: true)
    }
    
    private func showSpaceMembers() {
        guard let session = mainSession, let spaceId = dataSource?.currentSpace?.spaceId else {
            return
        }
        
        let coordinator = SpaceMembersCoordinator(parameters: SpaceMembersCoordinatorParameters(userSessionsService: UserSessionsService.shared, session: session, spaceId: spaceId))
        coordinator.delegate = self
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        present(presentable, animated: true, completion: nil)
    }

    private func showSpaceSettings() {
        guard let session = mainSession, let spaceId = dataSource?.currentSpace?.spaceId else {
            return
        }
        
        let coordinator = SpaceSettingsModalCoordinator(parameters: SpaceSettingsModalCoordinatorParameters(session: session, spaceId: spaceId, parentSpaceId: nil))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.remove(childCoordinator: coordinator)
            }
        }
        
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        present(presentable, animated: true, completion: nil)
        coordinator.start()
        add(childCoordinator: coordinator)
    }
    
    private func showLeaveSpace() {
        guard let session = mainSession, let spaceSummary = dataSource?.currentSpace?.summary else {
            return
        }
        
        let name = spaceSummary.displayName ?? VectorL10n.spaceTag
        
        let selectionHeader = MatrixItemChooserSelectionHeader(title: VectorL10n.leaveSpaceSelectionTitle,
                                                               selectAllTitle: VectorL10n.leaveSpaceSelectionAllRooms,
                                                               selectNoneTitle: VectorL10n.leaveSpaceSelectionNoRooms)
        let paramaters = MatrixItemChooserCoordinatorParameters(session: session,
                                                                title: VectorL10n.leaveSpaceTitle(name),
                                                                detail: VectorL10n.leaveSpaceMessage(name),
                                                                selectionHeader: selectionHeader,
                                                                viewProvider: LeaveSpaceViewProvider(navTitle: nil),
                                                                itemsProcessor: LeaveSpaceItemsProcessor(spaceId: spaceSummary.roomId, session: session))
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        coordinator.toPresentable().presentationController?.delegate = self
        coordinator.start()
        add(childCoordinator: coordinator)
        coordinator.completion = { [weak self] result in
            // switching to home space
            self?.switchSpace(withId: nil)
            coordinator.toPresentable().dismiss(animated: true) {
                self?.remove(childCoordinator: coordinator)
            }
        }
        present(coordinator.toPresentable(), animated: true)
    }
    
    private func showRoomInviteList() {
        let invitesViewController = RoomInvitesViewController.instantiate()
        invitesViewController.userIndicatorStore = self.userIndicatorStore
        let recentsListService = RecentsListService(withSession: mainSession)
        let recentsDataSource = RecentsDataSource(matrixSession: mainSession, recentsListService: recentsListService)
        invitesViewController.displayList(recentsDataSource)
        self.navigationController?.pushViewController(invitesViewController, animated: true)
    }
    
}
@available(iOS 15.0, *)

private extension AllChatsViewController {
    enum Constants {
        static let spacesButtonMaxCount: UInt = 999
    }
}
@available(iOS 15.0, *)

// MARK: - SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate
extension AllChatsViewController: SpaceSelectorBottomSheetCoordinatorBridgePresenterDelegate {
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        fetchAds()
    }
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenterDidSelectHome(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        
        switchSpace(withId: nil)
    }
    
    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didSelectSpaceWithId spaceId: String) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        
        switchSpace(withId: spaceId)
    }

    func spaceSelectorBottomSheetCoordinatorBridgePresenter(_ coordinatorBridgePresenter: SpaceSelectorBottomSheetCoordinatorBridgePresenter, didCreateSpaceWithinSpaceWithId parentSpaceId: String?) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.spaceSelectorBridgePresenter = nil
        }
        self.showCreateSpace(parentSpaceId: parentSpaceId)
    }

}

// MARK: - UISearchResultsUpdating
@available(iOS 15.0, *)
extension AllChatsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            self.dataSource?.search(withPatterns: nil)
            return
        }
        
        self.dataSource?.search(withPatterns: [searchText])
    }
}

// MARK: - UISearchControllerDelegate
@available(iOS 15.0, *)
extension AllChatsViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        // Fix for https://github.com/vector-im/element-ios/issues/6680
        self.recentsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
@available(iOS 15.0, *)
extension AllChatsViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let coordinator = childCoordinators.last else {
            return
        }
        
        remove(childCoordinator: coordinator)
    }
}

// MARK: - AllChatsEditActionProviderDelegate
@available(iOS 15.0, *)
extension AllChatsViewController: AllChatsEditActionProviderDelegate {
    
    func allChatsEditActionProvider(_ actionProvider: AllChatsEditActionProvider, didSelect option: AllChatsEditActionProviderOption) {
        switch option {
        case .exploreRooms:
            joinARoom()
        case .createRoom:
            createNewRoom()
        case .startChat:
            startChat()
        case .createSpace:
            showCreateSpace(parentSpaceId: dataSource?.currentSpace?.spaceId)
        }
    }
    
}

@available(iOS 15.0, *)
// MARK: - AllChatsSpaceActionProviderDelegate
extension AllChatsViewController: AllChatsSpaceActionProviderDelegate {
    func allChatsSpaceActionProvider(_ actionProvider: AllChatsSpaceActionProvider, didSelect option: AllChatsSpaceActionProviderOption) {
        switch option {
        case .invitePeople:
            showSpaceInvite()
        case .spaceMembers:
            showSpaceMembers()
        case .spaceSettings:
            showSpaceSettings()
        case .leaveSpace:
            showLeaveSpace()
        }
    }
}

// MARK: - ContactsPickerCoordinatorDelegate
@available(iOS 15.0, *)

extension AllChatsViewController: ContactsPickerCoordinatorDelegate {
    
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
        remove(childCoordinator: coordinator)
    }

}

// MARK: - SpaceMembersCoordinatorDelegate
@available(iOS 15.0, *)
extension AllChatsViewController: SpaceMembersCoordinatorDelegate {
    
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        coordinator.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - BannerPresentationProtocol
@available(iOS 15.0, *)
extension AllChatsViewController: BannerPresentationProtocol {
    func presentBannerView(_ bannerView: UIView, animated: Bool) {
        self.bannerView = bannerView
    }
    
    func dismissBannerView(animated: Bool) {
        self.bannerView = nil
    }
}

// TODO: The `MasterTabBarViewController` is called from the entire app through the `LegacyAppDelegate`. this part of the code should be moved into `AppCoordinator`
// MARK: - SplitViewMasterViewControllerProtocol
@available(iOS 15.0, *)
extension AllChatsViewController: SplitViewMasterViewControllerProtocol {

    /// Release the current selected item (if any).
    func releaseSelectedItem() {
        selectedRoomId = nil
        selectedEventId = nil
        selectedRoomSession = nil
        selectedRoomPreviewData = nil
        selectedContact = nil
    }
    
    /// Refresh the missed conversations badges on tab bar icon
    func refreshTabBarBadges() {
        // Nothing to do here as we don't have tab bar
    }
    
    /// Verify the current device if needed.
    ///
    /// - Parameters:
    ///   - session: the matrix session.
    func presentVerifyCurrentSessionAlertIfNeeded(with session: MXSession) {
        guard !RiotSettings.shared.hideVerifyThisSessionAlert,
              !isOnboardingInProgress,
              presentedViewController == nil,
              viewIfLoaded?.window != nil else {
            return
        }
        
        // Force verification if required by the HS configuration
        guard !session.vc_homeserverConfiguration().encryption.isSecureBackupRequired else {
            MXLog.debug("[AllChatsViewController] presentVerifyCurrentSessionAlertIfNeededWithSession: Force verification of the device")
            AppDelegate.theDelegate().presentCompleteSecurity(for: session)
            return
        }

        presentVerifyCurrentSessionAlert(with: session)
    }

    /// Verify others device if needed.
    ///
    /// - Parameters:
    ///   - session: the matrix session.
    func presentReviewUnverifiedSessionsAlertIfNeeded(with session: MXSession) {
        guard BuildSettings.showUnverifiedSessionsAlert,
              !reviewSessionAlertSnoozeController.isSnoozed(),
              presentedViewController == nil,
              viewIfLoaded?.window != nil else {
            return
        }

        if let userId = mainSession.myUserId, let crypto = mainSession.crypto {
            let devices = crypto.devices(forUser: userId).values
            let userHasOneUnverifiedDevice = devices.contains(where: {!$0.trustLevel.isCrossSigningVerified})
            if userHasOneUnverifiedDevice {
                presentReviewUnverifiedSessionsAlert(with: session)
            }
        }
    }
    
    func showOnboardingFlow() {
        MXLog.debug("[AllChatsViewController] showOnboardingFlow")
        self.showOnboardingFlowAndResetSessionFlags(true)
    }

    /// Display the onboarding flow configured to log back into a soft logout session.
    ///
    /// - Parameters:
    ///   - credentials: the credentials of the soft logout session.
    func showSoftLogoutOnboardingFlow(with credentials: MXCredentials?) {
        // This method can be called after the user chooses to clear their data as the MXSession
        // is opened to call logout from. So we only set the credentials when authentication isn't
        // in progress to prevent a second soft logout screen being shown.
        guard self.onboardingCoordinatorBridgePresenter == nil && !self.isOnboardingCoordinatorPreparing else {
            return
        }

        MXLog.debug("[AllChatsViewController] showAuthenticationScreenAfterSoftLogout")
        AuthenticationService.shared.softLogoutCredentials = credentials
        self.showOnboardingFlowAndResetSessionFlags(false)
    }

    /// Open the room with the provided identifier in a specific matrix session.
    ///
    /// - Parameters:
    ///   - parameters: the presentation parameters that contains room information plus display information.
    ///   - completion: the block to execute at the end of the operation.
    func selectRoom(with parameters: RoomNavigationParameters, completion: @escaping () -> Void) {
        releaseSelectedItem()
        
        selectedRoomId = parameters.roomId
        selectedEventId = parameters.eventId
        selectedRoomSession = parameters.mxSession

        allChatsDelegate?.allChatsViewController(self, didSelectRoomWithParameters: parameters, completion: completion)

        refreshSelectedControllerSelectedCellIfNeeded()
    }
    
    /// Open the RoomViewController to display the preview of a room that is unknown for the user.
    /// This room can come from an email invitation link or a simple link to a room.
    /// - Parameters:
    ///   - parameters: the presentation parameters that contains room preview information plus display information.
    ///   - completion: the block to execute at the end of the operation.
    func selectRoomPreview(with parameters: RoomPreviewNavigationParameters, completion: (() -> Void)?) {
        releaseSelectedItem()
        
        let roomPreviewData = parameters.previewData
        
        selectedRoomPreviewData = roomPreviewData
        selectedRoomId = roomPreviewData.roomId
        selectedRoomSession = roomPreviewData.mxSession

        allChatsDelegate?.allChatsViewController(self, didSelectRoomPreviewWithParameters: parameters, completion: completion)

        refreshSelectedControllerSelectedCellIfNeeded()
    }

    /// Open a ContactDetailsViewController to display the information of the provided contact.
    func select(_ contact: MXKContact) {
        let presentationParameters = ScreenPresentationParameters(restoreInitialDisplay: true, stackAboveVisibleViews: false)
        select(contact, with: presentationParameters)
    }
    
    /// Open a ContactDetailsViewController to display the information of the provided contact.
    func select(_ contact: MXKContact, with presentationParameters: ScreenPresentationParameters) {
        releaseSelectedItem()
        
        selectedContact = contact
        
        allChatsDelegate?.allChatsViewController(self, didSelectContact: contact, with: presentationParameters)

        refreshSelectedControllerSelectedCellIfNeeded()
    }

    /// The current number of rooms with missed notifications, including the invites.
    func missedDiscussionsCount() -> UInt {
        guard let session = mxSessions as? [MXSession] else {
            return 0
        }
        
        return session.reduce(0) { $0 + $1.vc_missedDiscussionsCount() }
    }

    /// The current number of rooms with unread highlighted messages.
    func missedHighlightDiscussionsCount() -> UInt {
        guard let session = mxSessions as? [MXSession] else {
            return 0
        }
        
        return session.reduce(0) { $0 + $1.missedHighlightDiscussionsCount() }
    }
    
    /// Emulated `UItabBarViewController.selectedViewController` member
    var selectedViewController: UIViewController? {
        return self
    }
    
    var tabBar: UITabBar? {
        return nil
    }
    
    // MARK: - Private
    
    private func presentVerifyCurrentSessionAlert(with session: MXSession) {
        MXLog.debug("[AllChatsViewController] presentVerifyCurrentSessionAlertWithSession")
        
        let title: String
        let message: String
        
        if MXSDKOptions.sharedInstance().cryptoMigrationDelegate?.needsVerificationUpgrade == true {
            title = VectorL10n.keyVerificationSelfVerifySecurityUpgradeAlertTitle
            message = VectorL10n.keyVerificationSelfVerifySecurityUpgradeAlertMessage
        } else {
            title = VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertTitle
            message = VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertMessage
        }
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.keyVerificationSelfVerifyCurrentSessionAlertValidateAction,
                                      style: .default,
                                      handler: { action in
            AppDelegate.theDelegate().presentCompleteSecurity(for: session)
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.later, style: .cancel))
        
        alert.addAction(UIAlertAction(title: VectorL10n.doNotAskAgain,
                                      style: .destructive,
                                      handler: { action in
            RiotSettings.shared.hideVerifyThisSessionAlert = true
        }))
        
        self.present(alert, animated: true)
    }

    private func presentReviewUnverifiedSessionsAlert(with session: MXSession) {
        MXLog.debug("[AllChatsViewController] presentReviewUnverifiedSessionsAlert")
        
        let alert = UIAlertController(title: VectorL10n.keyVerificationAlertTitle,
                                      message: VectorL10n.keyVerificationAlertBody,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: VectorL10n.keyVerificationSelfVerifyUnverifiedSessionsAlertValidateAction,
                                      style: .default,
                                      handler: { action in
            self.showSettingsSecurityScreen(with: session)
        }))
        
        alert.addAction(UIAlertAction(title: VectorL10n.later, style: .cancel, handler: { [weak self] _ in
            self?.reviewSessionAlertSnoozeController.snooze()
        }))
        
        present(alert, animated: true)
    }

    private func showSettingsSecurityScreen(with session: MXSession) {
        guard let settingsViewController = SettingsViewController.instantiate() else {
            MXLog.warning("[AllChatsViewController] showSettingsSecurityScreen: cannot instantiate SettingsViewController")
            return
        }
        
        guard let securityViewController = SecurityViewController.instantiate(withMatrixSession: session) else {
            MXLog.warning("[AllChatsViewController] showSettingsSecurityScreen: cannot instantiate SecurityViewController")
            return
        }
        
        settingsViewController.loadViewIfNeeded()
        AppDelegate.theDelegate().restoreInitialDisplay {
            if RiotSettings.shared.enableNewSessionManager {
                self.navigationController?.viewControllers = [self, settingsViewController]
                settingsViewController.showUserSessionsFlow()
            } else {
                self.navigationController?.viewControllers = [self, settingsViewController, securityViewController]
            }
        }
    }
    
    private func showOnboardingFlowAndResetSessionFlags(_ resetSessionFlags: Bool) {
        // Check whether an authentication screen is not already shown or preparing
        guard self.onboardingCoordinatorBridgePresenter == nil && !self.isOnboardingCoordinatorPreparing else {
            return
        }
        
        self.isOnboardingCoordinatorPreparing = true
        self.isOnboardingInProgress = true
        
        if resetSessionFlags {
            resetReviewSessionsFlags()
        }
        
        AppDelegate.theDelegate().restoreInitialDisplay {
            self.presentOnboardingFlow()
        }
    }

    private func resetReviewSessionsFlags() {
        RiotSettings.shared.hideVerifyThisSessionAlert = false
    }
    
    private func presentOnboardingFlow() {
        MXLog.debug("[AllChatsViewController] presentOnboardingFlow")
        
        let onboardingCoordinatorBridgePresenter = OnboardingCoordinatorBridgePresenter()
        onboardingCoordinatorBridgePresenter.completion = { [weak self] in
            guard let self = self else { return }
            
            self.onboardingCoordinatorBridgePresenter?.dismiss(animated: true, completion: {
                self.onboardingCoordinatorBridgePresenter = nil
            })
            
            self.isOnboardingInProgress = false   // Must be set before calling didCompleteAuthentication
            self.allChatsDelegate?.allChatsViewControllerDidCompleteAuthentication(self)
        }
        
        onboardingCoordinatorBridgePresenter.present(from: self, animated: true)
        self.onboardingCoordinatorBridgePresenter = onboardingCoordinatorBridgePresenter
        self.isOnboardingCoordinatorPreparing = false
    }
    
    private func refreshSelectedControllerSelectedCellIfNeeded() {
        guard splitViewController != nil else {
            return
        }
        
        // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
        self.refreshCurrentSelectedCell(false)
    }
}

private extension MXSpaceService {
    var hasSpaceInvite: Bool {
        spaceSummaries.contains(where: { $0.isJoined == false })
    }
    
    var missedNotificationsCount: UInt {
        let notificationState = notificationCounter.homeNotificationState
        let groupNotifications = notificationState.groupMissedDiscussionsCount
        let directNotifications = notificationState.directMissedDiscussionsCount
        
        // `notificationState.allCount` returns twice the messages for favourite rooms. Fixing it here.
        return groupNotifications + directNotifications
    }
    
    var hasHighlightNotification: Bool {
        notificationCounter.homeNotificationState.allHighlightCount > 0
    }
}

@available(iOS 15.0, *)
extension AllChatsViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        // Вернуть количество файлов для предпросмотра (в данном случае - 1)
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // Создать временный файл для предпросмотра
        let tempDirectory = NSTemporaryDirectory()
        let tempFilePath = tempDirectory + "previewFile." + (previewItemFileExtension ?? "")
        
        FileManager.default.createFile(atPath: tempFilePath, contents: previewItemData, attributes: nil)
        
        // Вернуть путь к временному файлу в качестве предпросмотра
        return NSURL(fileURLWithPath: tempFilePath)
    }
    
    func previewController(_ controller: QLPreviewController, titleForPreviewItemAt index: Int) -> String? {
        // Вернуть имя файла для отображения в просмотрщике
        return previewItemTitle
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Показать снова первое модальное окно после закрытия просмотрщика
        if let documents = self.documents {
            firestoreDocumentsUpdateHandler(documents: documents)
        }
    }
}


public enum Model : String {

//Simulator
case simulator     = "simulator/sandbox",

//iPod
iPod1              = "iPod 1",
iPod2              = "iPod 2",
iPod3              = "iPod 3",
iPod4              = "iPod 4",
iPod5              = "iPod 5",
iPod6              = "iPod 6",
iPod7              = "iPod 7",

//iPad
iPad2              = "iPad 2",
iPad3              = "iPad 3",
iPad4              = "iPad 4",
iPadAir            = "iPad Air ",
iPadAir2           = "iPad Air 2",
iPadAir3           = "iPad Air 3",
iPadAir4           = "iPad Air 4",
iPadAir5           = "iPad Air 5",
iPad5              = "iPad 5", //iPad 2017
iPad6              = "iPad 6", //iPad 2018
iPad7              = "iPad 7", //iPad 2019
iPad8              = "iPad 8", //iPad 2020
iPad9              = "iPad 9", //iPad 2021

//iPad Mini
iPadMini           = "iPad Mini",
iPadMini2          = "iPad Mini 2",
iPadMini3          = "iPad Mini 3",
iPadMini4          = "iPad Mini 4",
iPadMini5          = "iPad Mini 5",
iPadMini6          = "iPad Mini 6",

//iPad Pro
iPadPro9_7         = "iPad Pro 9.7\"",
iPadPro10_5        = "iPad Pro 10.5\"",
iPadPro11          = "iPad Pro 11\"",
iPadPro2_11        = "iPad Pro 11\" 2nd gen",
iPadPro3_11        = "iPad Pro 11\" 3rd gen",
iPadPro12_9        = "iPad Pro 12.9\"",
iPadPro2_12_9      = "iPad Pro 2 12.9\"",
iPadPro3_12_9      = "iPad Pro 3 12.9\"",
iPadPro4_12_9      = "iPad Pro 4 12.9\"",
iPadPro5_12_9      = "iPad Pro 5 12.9\"",

//iPhone
iPhone4            = "iPhone 4",
iPhone4S           = "iPhone 4S",
iPhone5            = "iPhone 5",
iPhone5S           = "iPhone 5S",
iPhone5C           = "iPhone 5C",
iPhone6            = "iPhone 6",
iPhone6Plus        = "iPhone 6 Plus",
iPhone6S           = "iPhone 6S",
iPhone6SPlus       = "iPhone 6S Plus",
iPhoneSE           = "iPhone SE",
iPhone7            = "iPhone 7",
iPhone7Plus        = "iPhone 7 Plus",
iPhone8            = "iPhone 8",
iPhone8Plus        = "iPhone 8 Plus",
iPhoneX            = "iPhone X",
iPhoneXS           = "iPhone XS",
iPhoneXSMax        = "iPhone XS Max",
iPhoneXR           = "iPhone XR",
iPhone11           = "iPhone 11",
iPhone11Pro        = "iPhone 11 Pro",
iPhone11ProMax     = "iPhone 11 Pro Max",
iPhoneSE2          = "iPhone SE 2nd gen",
iPhone12Mini       = "iPhone 12 Mini",
iPhone12           = "iPhone 12",
iPhone12Pro        = "iPhone 12 Pro",
iPhone12ProMax     = "iPhone 12 Pro Max",
iPhone13Mini       = "iPhone 13 Mini",
iPhone13           = "iPhone 13",
iPhone13Pro        = "iPhone 13 Pro",
iPhone13ProMax     = "iPhone 13 Pro Max",
iPhoneSE3          = "iPhone SE 3nd gen",
iPhone14           = "iPhone 14",
iPhone14Plus       = "iPhone 14 Plus",
iPhone14Pro        = "iPhone 14 Pro",
iPhone14ProMax     = "iPhone 14 Pro Max",

// Apple Watch
AppleWatch1         = "Apple Watch 1gen",
AppleWatchS1        = "Apple Watch Series 1",
AppleWatchS2        = "Apple Watch Series 2",
AppleWatchS3        = "Apple Watch Series 3",
AppleWatchS4        = "Apple Watch Series 4",
AppleWatchS5        = "Apple Watch Series 5",
AppleWatchSE        = "Apple Watch Special Edition",
AppleWatchS6        = "Apple Watch Series 6",
AppleWatchS7        = "Apple Watch Series 7",

//Apple TV
AppleTV1           = "Apple TV 1gen",
AppleTV2           = "Apple TV 2gen",
AppleTV3           = "Apple TV 3gen",
AppleTV4           = "Apple TV 4gen",
AppleTV_4K         = "Apple TV 4K",
AppleTV2_4K        = "Apple TV 4K 2gen",

unrecognized       = "?unrecognized?"
}

// #-#-#-#-#-#-#-#-#-#-#-#-#
// MARK: UIDevice extensions
// #-#-#-#-#-#-#-#-#-#-#-#-#

    public extension UIDevice {
    
    var type: Model {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
    
        let modelMap : [String: Model] = [
    
            //Simulator
            "i386"      : .simulator,
            "x86_64"    : .simulator,
    
            //iPod
            "iPod1,1"   : .iPod1,
            "iPod2,1"   : .iPod2,
            "iPod3,1"   : .iPod3,
            "iPod4,1"   : .iPod4,
            "iPod5,1"   : .iPod5,
            "iPod7,1"   : .iPod6,
            "iPod9,1"   : .iPod7,
    
            //iPad
            "iPad2,1"   : .iPad2,
            "iPad2,2"   : .iPad2,
            "iPad2,3"   : .iPad2,
            "iPad2,4"   : .iPad2,
            "iPad3,1"   : .iPad3,
            "iPad3,2"   : .iPad3,
            "iPad3,3"   : .iPad3,
            "iPad3,4"   : .iPad4,
            "iPad3,5"   : .iPad4,
            "iPad3,6"   : .iPad4,
            "iPad6,11"  : .iPad5, //iPad 2017
            "iPad6,12"  : .iPad5,
            "iPad7,5"   : .iPad6, //iPad 2018
            "iPad7,6"   : .iPad6,
            "iPad7,11"  : .iPad7, //iPad 2019
            "iPad7,12"  : .iPad7,
            "iPad11,6"  : .iPad8, //iPad 2020
            "iPad11,7"  : .iPad8,
            "iPad12,1"  : .iPad9, //iPad 2021
            "iPad12,2"  : .iPad9,
    
            //iPad Mini
            "iPad2,5"   : .iPadMini,
            "iPad2,6"   : .iPadMini,
            "iPad2,7"   : .iPadMini,
            "iPad4,4"   : .iPadMini2,
            "iPad4,5"   : .iPadMini2,
            "iPad4,6"   : .iPadMini2,
            "iPad4,7"   : .iPadMini3,
            "iPad4,8"   : .iPadMini3,
            "iPad4,9"   : .iPadMini3,
            "iPad5,1"   : .iPadMini4,
            "iPad5,2"   : .iPadMini4,
            "iPad11,1"  : .iPadMini5,
            "iPad11,2"  : .iPadMini5,
            "iPad14,1"  : .iPadMini6,
            "iPad14,2"  : .iPadMini6,
    
            //iPad Pro
            "iPad6,3"   : .iPadPro9_7,
            "iPad6,4"   : .iPadPro9_7,
            "iPad7,3"   : .iPadPro10_5,
            "iPad7,4"   : .iPadPro10_5,
            "iPad6,7"   : .iPadPro12_9,
            "iPad6,8"   : .iPadPro12_9,
            "iPad7,1"   : .iPadPro2_12_9,
            "iPad7,2"   : .iPadPro2_12_9,
            "iPad8,1"   : .iPadPro11,
            "iPad8,2"   : .iPadPro11,
            "iPad8,3"   : .iPadPro11,
            "iPad8,4"   : .iPadPro11,
            "iPad8,9"   : .iPadPro2_11,
            "iPad8,10"  : .iPadPro2_11,
            "iPad13,4"  : .iPadPro3_11,
            "iPad13,5"  : .iPadPro3_11,
            "iPad13,6"  : .iPadPro3_11,
            "iPad13,7"  : .iPadPro3_11,
            "iPad8,5"   : .iPadPro3_12_9,
            "iPad8,6"   : .iPadPro3_12_9,
            "iPad8,7"   : .iPadPro3_12_9,
            "iPad8,8"   : .iPadPro3_12_9,
            "iPad8,11"  : .iPadPro4_12_9,
            "iPad8,12"  : .iPadPro4_12_9,
            "iPad13,8"  : .iPadPro5_12_9,
            "iPad13,9"  : .iPadPro5_12_9,
            "iPad13,10" : .iPadPro5_12_9,
            "iPad13,11" : .iPadPro5_12_9,
    
            //iPad Air
            "iPad4,1"   : .iPadAir,
            "iPad4,2"   : .iPadAir,
            "iPad4,3"   : .iPadAir,
            "iPad5,3"   : .iPadAir2,
            "iPad5,4"   : .iPadAir2,
            "iPad11,3"  : .iPadAir3,
            "iPad11,4"  : .iPadAir3,
            "iPad13,1"  : .iPadAir4,
            "iPad13,2"  : .iPadAir4,
            "iPad13,16" : .iPadAir5,
            "iPad13,17" : .iPadAir5,
    
            //iPhone
            "iPhone3,1" : .iPhone4,
            "iPhone3,2" : .iPhone4,
            "iPhone3,3" : .iPhone4,
            "iPhone4,1" : .iPhone4S,
            "iPhone5,1" : .iPhone5,
            "iPhone5,2" : .iPhone5,
            "iPhone5,3" : .iPhone5C,
            "iPhone5,4" : .iPhone5C,
            "iPhone6,1" : .iPhone5S,
            "iPhone6,2" : .iPhone5S,
            "iPhone7,1" : .iPhone6Plus,
            "iPhone7,2" : .iPhone6,
            "iPhone8,1" : .iPhone6S,
            "iPhone8,2" : .iPhone6SPlus,
            "iPhone8,4" : .iPhoneSE,
            "iPhone9,1" : .iPhone7,
            "iPhone9,3" : .iPhone7,
            "iPhone9,2" : .iPhone7Plus,
            "iPhone9,4" : .iPhone7Plus,
            "iPhone10,1" : .iPhone8,
            "iPhone10,4" : .iPhone8,
            "iPhone10,2" : .iPhone8Plus,
            "iPhone10,5" : .iPhone8Plus,
            "iPhone10,3" : .iPhoneX,
            "iPhone10,6" : .iPhoneX,
            "iPhone11,2" : .iPhoneXS,
            "iPhone11,4" : .iPhoneXSMax,
            "iPhone11,6" : .iPhoneXSMax,
            "iPhone11,8" : .iPhoneXR,
            "iPhone12,1" : .iPhone11,
            "iPhone12,3" : .iPhone11Pro,
            "iPhone12,5" : .iPhone11ProMax,
            "iPhone12,8" : .iPhoneSE2,
            "iPhone13,1" : .iPhone12Mini,
            "iPhone13,2" : .iPhone12,
            "iPhone13,3" : .iPhone12Pro,
            "iPhone13,4" : .iPhone12ProMax,
            "iPhone14,4" : .iPhone13Mini,
            "iPhone14,5" : .iPhone13,
            "iPhone14,2" : .iPhone13Pro,
            "iPhone14,3" : .iPhone13ProMax,
            "iPhone14,6" : .iPhoneSE3,
            "iPhone14,7" : .iPhone14,
            "iPhone14,8" : .iPhone14Plus,
            "iPhone15,2" : .iPhone14Pro,
            "iPhone15,3" : .iPhone14ProMax,
            
            // Apple Watch
            "Watch1,1" : .AppleWatch1,
            "Watch1,2" : .AppleWatch1,
            "Watch2,6" : .AppleWatchS1,
            "Watch2,7" : .AppleWatchS1,
            "Watch2,3" : .AppleWatchS2,
            "Watch2,4" : .AppleWatchS2,
            "Watch3,1" : .AppleWatchS3,
            "Watch3,2" : .AppleWatchS3,
            "Watch3,3" : .AppleWatchS3,
            "Watch3,4" : .AppleWatchS3,
            "Watch4,1" : .AppleWatchS4,
            "Watch4,2" : .AppleWatchS4,
            "Watch4,3" : .AppleWatchS4,
            "Watch4,4" : .AppleWatchS4,
            "Watch5,1" : .AppleWatchS5,
            "Watch5,2" : .AppleWatchS5,
            "Watch5,3" : .AppleWatchS5,
            "Watch5,4" : .AppleWatchS5,
            "Watch5,9" : .AppleWatchSE,
            "Watch5,10" : .AppleWatchSE,
            "Watch5,11" : .AppleWatchSE,
            "Watch5,12" : .AppleWatchSE,
            "Watch6,1" : .AppleWatchS6,
            "Watch6,2" : .AppleWatchS6,
            "Watch6,3" : .AppleWatchS6,
            "Watch6,4" : .AppleWatchS6,
            "Watch6,6" : .AppleWatchS7,
            "Watch6,7" : .AppleWatchS7,
            "Watch6,8" : .AppleWatchS7,
            "Watch6,9" : .AppleWatchS7,
    
            //Apple TV
            "AppleTV1,1" : .AppleTV1,
            "AppleTV2,1" : .AppleTV2,
            "AppleTV3,1" : .AppleTV3,
            "AppleTV3,2" : .AppleTV3,
            "AppleTV5,3" : .AppleTV4,
            "AppleTV6,2" : .AppleTV_4K,
            "AppleTV11,1" : .AppleTV2_4K
        ]
    
        guard let mcode = modelCode, let map = String(validatingUTF8: mcode), let model = modelMap[map] else { return Model.unrecognized }
        if model == .simulator {
            if let simModelCode = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                if let simMap = String(validatingUTF8: simModelCode), let simModel = modelMap[simMap] {
                    return simModel
                }
            }
        }
        return model
    }
}
