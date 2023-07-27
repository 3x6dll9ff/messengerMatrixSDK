// swiftlint:disable all

import Foundation

@objc protocol VoiceMessagePlainCellDelegate: AnyObject {
    func voiceMessagePlainCellDidRequestTableUpdate(_ cell: VoiceMessagePlainCell)
}

@objc class VoiceMessagePlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable, RoomCellThreadSummaryDisplayable {
    
    @objc weak var voiceMessageDelegate: VoiceMessagePlainCellDelegate?

    private(set) var playbackController: VoiceMessagePlaybackController!
    private var transcriptionLabel: UILabel = UILabel()
    
    func updateTranscriptionLabel(with text: String) {
        DispatchQueue.main.async {
            print("TEXT \(text)")
//            self.transcriptionLabel.text = text
//            self.layoutIfNeeded()
//            self.voiceMessageDelegate?.voiceMessagePlainCellDidRequestTableUpdate(self)
        }
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        print("RENDER \(transcriptionLabel.text ?? "")")
        
        guard let data = cellData as? RoomBubbleCellData else {
            return
        }
        
        guard data.attachment.type == .voiceMessage || data.attachment.type == .audio else {
            fatalError("Invalid attachment type passed to a voice message cell.")
        }
        
        if playbackController.attachment != data.attachment {
            playbackController.attachment = data.attachment
        }
        
        self.update(theme: ThemeService.shared().theme)
    }

    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
        
        guard let contentView = roomCellContentView?.innerContentView else {
            return
        }
        
        playbackController = VoiceMessagePlaybackController(mediaServiceProvider: VoiceMessageMediaServiceProvider.sharedProvider,
                                                            cacheManager: VoiceMessageAttachmentCacheManager.sharedManager, updateTranscriptionLabel: updateTranscriptionLabel)

        transcriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptionLabel.numberOfLines = 0
        
        print("SETUPVIEWS \(transcriptionLabel.text ?? "")")
        
        let stackView = UIStackView(arrangedSubviews: [playbackController.playbackView, transcriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }



    override func update(theme: Theme) {
        
        super.update(theme: theme)
        
        print("UPDATE: \(transcriptionLabel.text ?? "")")
        
        guard let playbackController = playbackController else {
            return
        }
        
        playbackController.playbackView.update(theme: theme)
    }
}
