//
//  RepoHeader.swift
//  NitrolessiOS
//
//  Created by Andromeda on 15/05/2021.
//

import UIKit
import Evander

class RepoHeader: UICollectionReusableView {

    @IBOutlet weak var sectionImage: UIImageView!
    @IBOutlet weak var sectionLabel: UILabel!
    
    public var repoLink: URL? {
        didSet {
            sectionImage.image = nil
            guard let tmp = repoLink else { return }
            let imageURL = tmp.appendingPathComponent("RepoImage").appendingPathExtension("png")
            if let image = EvanderNetworking.shared.image(imageURL, cache: true, { [weak self] success, image in
                if success,
                      let image = image,
                      self?.repoLink == tmp {
                    DispatchQueue.main.async {
                        self?.sectionImage.image = image
                    }
                }
            }) {
                sectionImage.image = image
            } else {
                sectionImage.image = UIImage(named: "NoSourceIcon")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sectionLabel.textColor = ThemeManager.headerColor
        sectionImage.layer.masksToBounds = true
        sectionImage.layer.cornerRadius = sectionImage.frame.height / 4.5
    }
    
}
