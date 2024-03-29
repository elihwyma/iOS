//
//  EmoteView.swift
//  NitrolessiOS
//
//  Created by Andromeda on 15/05/2021.
//

import UIKit
import Evander

class EmoteView: UICollectionView {

    var recentlyUsed = [Emote]()
    var repos = [Repo]()
    var toastView: ToastView = .fromNib()
    var repoContext: Repo?
    weak var parentController: UIViewController?
    private var filter: String? = nil
    
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.center(in: self)
        loadingIndicator.startAnimating()
        isPrefetchingEnabled = false
        delegate = self
        dataSource = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .none
        register(UINib(nibName: "NitrolessViewCell", bundle: nil), forCellWithReuseIdentifier: "NitrolessViewCell")
        register(UINib(nibName: "RepoHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Nitroless.RepoHeader")
        
        weak var weakSelf = self
        NotificationCenter.default.addObserver(weakSelf as Any, selector: #selector(updateRepo(_:)), name: .RepoLoad, object: nil)
        NotificationCenter.default.addObserver(weakSelf as Any, selector: #selector(removeRecentlyUsed), name: .RemoveRecentlyUsed, object: nil)
        NotificationCenter.default.addObserver(weakSelf as Any, selector: #selector(removeRepo), name: .RepoRemove, object: nil)
        NotificationCenter.default.addObserver(weakSelf as Any, selector: #selector(updateFilter), name: .RepoRemove, object: nil)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            RepoManager.shared.initWait()
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.loadingIndicator.removeFromSuperview()
                self.updateFilter(self.filter)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func repoReload() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.repoReload()
            }
            return
        }
        updateFilter(filter)
    }
    
    @objc private func removeRepo(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        if let index = repos.firstIndex(where: { $0.url == url }) {
            repos.remove(at: index)
            deleteSections(IndexSet(integer: index + (recentlyUsed.isEmpty ? 0 : 1)))
        }
    }
    
    @objc public func updateFilter(_ string: String? = nil) {
        self.filter = string
        if !RepoManager.shared.isLoaded { return }
        if let repoContext = self.repoContext {
            self.repos = [repoContext]
            return
        }
        self.recentlyUsed.removeAll()
        var repos = RepoManager.shared.repos.sorted(by: { $0.displayName?.lowercased() ?? "" < $1.displayName?.lowercased() ?? "" })
        repos = repos.filter({ !$0.emotes.isEmpty })
        
        if let search = string?.lowercased(),
           !search.isEmpty {
            var buffer = 0
            for (index, repo) in repos.enumerated() {
                let emotes = repo.emotes.filter({ $0.name.lowercased().contains(search) })
                if emotes.isEmpty {
                    repos.remove(at: index - buffer)
                    buffer += 1
                } else {
                    repos[index - buffer].emotes = emotes
                }
            }
        } else {
            if let recentlyUsed = RepoManager.shared.defaults.dictionary(forKey: "Nitroless.RecentlyUsed") as? [String: Int] {
                let allEmotes = RepoManager.shared.allEmotes
                for (k, _) in (Array(recentlyUsed).sorted {$0.1 > $1.1}) {
                    for emote in allEmotes where emote.url.absoluteString == k {
                        self.recentlyUsed.append(emote)
                    }
                }
            }
        }
        NSLog("[Nitroless] Repos = \(repos.map { $0.emotes })")
        self.repos = repos
        self.reloadData()
    }
    
    @objc private func updateRepo(_ notification: Notification) {
        guard let repo = notification.object as? Repo,
              !repo.emotes.isEmpty else { return }
        if repoContext != nil {
            if repoContext?.url != repo.url {
                return
            }
            repoContext = repo
            reloadSections(IndexSet(integer: 0))
            return
        }
        if let index = repos.firstIndex(where: { $0.url == repo.url }) {
            repos[index] = repo
            reloadSections(IndexSet(integer: index + (recentlyUsed.isEmpty ? 0 : 1)))
        } else {
            repos.append(repo)
            repos = repos.sorted(by: { $0.displayName?.lowercased() ?? "" < $1.displayName?.lowercased() ?? "" })
            if let index = repos.firstIndex(where: { $0.url == repo.url }) {
                insertSections(IndexSet(integer: index + (recentlyUsed.isEmpty ? 0 : 1)))
            }
        }
        reloadRecentlyUsed()
    }
    
    private func reloadRecentlyUsed() {
        if let recentlyUsed = RepoManager.shared.defaults.dictionary(forKey: "Nitroless.RecentlyUsed") as? [String: Int] {
            var allEmotesTmp = [Emote]()
            for repo in repos {
                for emote in repo.emotes { allEmotesTmp.append(emote) }
            }
            var recentlyUsedTmp = [Emote]()
            for (k, _) in (Array(recentlyUsed).sorted {$0.1 > $1.1}) {
                for emote in allEmotesTmp where emote.url.absoluteString == k {
                    recentlyUsedTmp.append(emote)
                }
            }
            if recentlyUsedTmp.isEmpty { return }
            if self.recentlyUsed.isEmpty {
                self.recentlyUsed = recentlyUsedTmp
                insertSections(IndexSet(integer: 0))
            } else {
                self.recentlyUsed = recentlyUsedTmp
                reloadSections(IndexSet(integer: 0))
            }
        }
    }
    
    @objc private func removeRecentlyUsed() {
        guard !recentlyUsed.isEmpty else { return }
        recentlyUsed.removeAll()
        deleteSections(IndexSet(integer: 0))
    }
}

extension EmoteView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = Int(self.frame.width / 50)
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if repoContext != nil {
            return .zero
        } else {
            return CGSize(width: collectionView.frame.width, height: 20)
        }
    }
}

extension EmoteView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emote: Emote = { () -> Emote in
            switch section(indexPath.section) {
            case .recentlyUsed: return recentlyUsed[indexPath.row]
            case .repo: return repos[indexPath.section - (recentlyUsed.isEmpty ? 0 : 1)].emotes[indexPath.row]
            }
        }()
        UIPasteboard.general.string = emote.url.absoluteString
        RepoManager.shared.use(emote)
        if let nc = parentController {
            self.toastView.showText(nc, "Copied \(emote.name)")
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        /*
        if emote.type == .gif {
            collectionView.reloadItems(at: [indexPath])
        }
        */
        if let cell = collectionView.cellForItem(at: indexPath) as? NitrolessViewCell {
            NSLog("[Nitroless] Cell = \(cell) \(cell.emote) \(cell.imageView.animationImages) \(cell.imageView.image)")
            
            NSLog("[Nitroless] BReakpoint pls")
        }
        if repoContext == nil {
            reloadRecentlyUsed()
        }
    }
}

extension EmoteView: UICollectionViewDataSource {
    
    enum Section {
        case recentlyUsed
        case repo
    }
    
    func section(_ section: Int) -> Section {
        if recentlyUsed.isEmpty {
            return .repo
        } else if section == 0 {
            return .recentlyUsed
        } else {
            return .repo
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        repos.count + (recentlyUsed.isEmpty ? 0 : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.section(section) {
        case .recentlyUsed: return recentlyUsed.count
        case .repo: return repos[section - (recentlyUsed.isEmpty ? 0 : 1)].emotes.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let emote: Emote = { () -> Emote in
            switch section(indexPath.section) {
            case .recentlyUsed: return recentlyUsed[indexPath.row]
            case .repo: return repos[indexPath.section - (recentlyUsed.isEmpty ? 0 : 1)].emotes[indexPath.row]
            }
        }()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NitrolessViewCell", for: indexPath) as! NitrolessViewCell
        cell.emote = emote
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Nitroless.RepoHeader", for: indexPath) as! RepoHeader
            switch section(indexPath.section) {
            case .repo:
                let repo = repos[indexPath.section - (recentlyUsed.isEmpty ? 0 : 1)]
                header.sectionLabel.text = repo.displayName
                header.repoLink = repo.url
            case .recentlyUsed:
                header.sectionLabel.text = "Recently Used"
                header.sectionImage.image = UIImage(named: "RecentlyUsed")
            }
            return header
        default:  fatalError("Unexpected element kind")
        }
    }
}
