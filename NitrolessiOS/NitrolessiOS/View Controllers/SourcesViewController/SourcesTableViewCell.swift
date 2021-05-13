//
//  SourcesTableViewCell.swift
//  NitrolessiOS
//
//  Created by Andromeda on 13/05/2021.
//

import UIKit

class SourcesTableViewCell: UITableViewCell {
    
    var repo: Repo
    
    init(repo: Repo) {
        self.repo = repo
        super.init(style: .default, reuseIdentifier: "Nitroless.RepoCell")
        
        textLabel?.text = repo.displayName
        let repoURL = repo.url
        let imageURL = repoURL.appendingPathComponent("RepoImage")
        if let image = AmyNetworkResolver.shared.image(imageURL, cache: true, type: .png, { (success, image) in
            if success,
                  let image = image,
                  self.repo.url == repoURL {
                self.imageView?.image = image
            }
        }) {
            imageView?.image = image
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
