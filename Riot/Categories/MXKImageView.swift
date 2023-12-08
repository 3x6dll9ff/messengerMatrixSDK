// swiftlint:disable all

import Foundation
import SDWebImage
import MatrixSDK

extension MXKImageView {
    @objc func vc_setRoomApiAvatarImage(directUserId: String) {
        let avatarUrl = "https://bigsapi.pro/avatars/preview?matrixId=\(directUserId)"
        if let imageUrl = URL(string: avatarUrl) {
            self.imageView?.sd_setImage(with: imageUrl, placeholderImage: AvatarGenerator.generateAvatar(forMatrixItem: directUserId, withDisplayName: directUserId), options: .allowInvalidSSLCertificates, completed: nil)
        }
    }

    @objc func vc_setRoomAvatarImage(with url: String?, roomId: String, displayName: String, mediaManager: MXMediaManager) {
        // Use the display name to prepare the default avatar image.
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: roomId, withDisplayName: displayName)

        if let avatarUrl = url {
            self.enableInMemoryCache = true
            self.setImageURIRoom(avatarUrl, withType: nil, andImageOrientation: .up, toFitViewSize: self.frame.size, with: MXThumbnailingMethodCrop, previewImage: avatarImage, mediaManager: mediaManager)
        } else {
            self.image = avatarImage
        }
        self.contentMode = .scaleAspectFill

        if let session = MXKAccountManager.shared()?.activeAccounts.first?.mxSession,
           let room = session.room(withRoomId: roomId),
           let directUserId = room.directUserId {
            self.vc_setRoomApiAvatarImage(directUserId: directUserId)
        }
    }
}
