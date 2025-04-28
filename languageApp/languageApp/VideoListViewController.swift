import UIKit
import SafariServices

class VideoListViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var videos: [PlaylistItem] = []
    private var displayedVideos: [PlaylistItem] = []
    private var filteredVideos: [PlaylistItem] = [] // Filtrelenmiş videolar için yeni dizi
    private var currentPage = 0
    private let videosPerPage = 6
    private var nextPageToken: String?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var hideWatchedVideos = false // İzlenen videoları gizleme durumu
    
    // Modern stil sayfa kontrollerü
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = UIColor.systemBlue
        control.pageIndicatorTintColor = UIColor.systemGray5
        control.backgroundColor = UIColor.systemBackground
        
        // Kenar çizgisi ve gölge ekleme
        control.layer.borderWidth = 1.0
        control.layer.borderColor = UIColor.systemGray5.cgColor
        control.layer.cornerRadius = 20
        
        // Gölge efekti
        control.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        control.layer.shadowOffset = CGSize(width: 0, height: 2)
        control.layer.shadowRadius = 6
        control.layer.shadowOpacity = 1.0
        
        control.addTarget(self, action: #selector(pageControlValueChanged(_:)), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchChannelUploadsPlaylistId()
        
        // İzlendi durumu değiştiğinde listeyi yenile
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(videoWatchStatusChanged),
                                             name: NSNotification.Name("VideoWatchStatusChanged"),
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func videoWatchStatusChanged() {
        collectionView.reloadData()
    }
    
    private func setupUI() {
        title = "" // Başlığı kaldır
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false // Large titles'i kapat
        
        // Navigation bar'a stil ekle
        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
        
        // Modern pill-shaped buton - başlangıç durumuna göre renk belirleme
        let segmentedContainer = UIView()
        let buttonColor = hideWatchedVideos ? UIColor.systemGreen : UIColor.systemBlue
        segmentedContainer.backgroundColor = buttonColor
        segmentedContainer.layer.cornerRadius = 20
        
        // Parlak efekt için overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        overlayView.layer.cornerRadius = 20
        overlayView.layer.masksToBounds = true
        
        // Gölge ekle - renk buton rengine göre değişir
        segmentedContainer.layer.shadowColor = buttonColor.withAlphaComponent(0.3).cgColor
        segmentedContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        segmentedContainer.layer.shadowRadius = 8
        segmentedContainer.layer.shadowOpacity = 1
        
        // İçerik için stack
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.isUserInteractionEnabled = false
        
        // İkon için görsel 
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        
        let iconType = hideWatchedVideos ? "eye" : "eye.slash"
        iconView.image = UIImage(systemName: iconType)?.withRenderingMode(.alwaysTemplate)
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // Metin için etiket
        let textLabel = UILabel()
        textLabel.text = hideWatchedVideos ? "Hepsini Göster" : "İzlenenleri Gizle"
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        // Stack'e içerikleri ekle
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textLabel)
        
        // Parlaklık efekti için overlay'i ekle
        segmentedContainer.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        overlayView.frame = CGRect(x: 0, y: 0, width: 180, height: 20) // Sadece üst yarısına parlaklık ekle
        segmentedContainer.addSubview(overlayView)
        
        // Container'a stack'i ekle
        segmentedContainer.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: segmentedContainer.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: segmentedContainer.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: segmentedContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: segmentedContainer.trailingAnchor, constant: -16)
        ])
        
        // Tıklama işlevi
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleWatchedVideos))
        segmentedContainer.addGestureRecognizer(tapGesture)
        segmentedContainer.isUserInteractionEnabled = true
        
        // Butonu navigation bar'a ekle
        let customButtonItem = UIBarButtonItem(customView: segmentedContainer)
        navigationItem.rightBarButtonItem = customButtonItem
        
        // Setup collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        // Her satırda 2 video olacak şekilde hesaplama
        let screenWidth = UIScreen.main.bounds.width
        let itemsPerRow: CGFloat = 2
        let padding: CGFloat = 16
        let spacing: CGFloat = 16
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let availableWidth = screenWidth - (2 * padding) - spacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        
        // 16:9 aspect ratio için height hesaplama
        let itemHeight = itemWidth * 9/16 + 32 // Extra padding için
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding) // 1.4 aspect ratio for thumbnail + text
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        // Setup collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.reuseIdentifier)
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            pageControl.heightAnchor.constraint(equalToConstant: 40),
            pageControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    private func fetchChannelUploadsPlaylistId() {
        activityIndicator.startAnimating()
        collectionView.isHidden = true
        
        let urlString = "\(Config.baseUrl)/channels?key=\(Config.apiKey)&id=\(Config.channelId)&part=contentDetails"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Invalid URL configuration")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showError("No data received")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChannelResponse.self, from: data)
                if let playlistId = response.items.first?.contentDetails.relatedPlaylists.uploads {
                    self?.fetchVideos(playlistId: playlistId)
                } else {
                    DispatchQueue.main.async {
                        self?.showError("Could not find uploads playlist")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showError("Failed to decode channel data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    @objc private func toggleWatchedVideos() {
        print("Toggle butonuna tıklandı. Mevcut durum: \(hideWatchedVideos)")
        
        // İzlenen videoları gizleme/gösterme durumunu değiştir
        hideWatchedVideos = !hideWatchedVideos
        
        print("Yeni durum: \(hideWatchedVideos)")
        
        // Buton görünümünü güncelle
        updateFilterButtonAppearance()
        
        // Videoları güncelle ve koleksiyonu yeniden yükle
        currentPage = 0 // İlk sayfaya dön
        updateDisplayedVideos()
        collectionView.reloadData()
        
        // Sayfada hiç içerik kalmadıysa bilgilendirme göster
        if displayedVideos.isEmpty && hideWatchedVideos {
            let emptyView = createEmptyStateView()
            collectionView.backgroundView = emptyView
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    private func updateFilterButtonAppearance() {
        // Buton metni ve ikonunu güncelle
        guard let container = navigationItem.rightBarButtonItem?.customView as? UIView else {
            print("Buton container bulunamadı")
            return
        }
        
        print("Container bulundu, alt elemanları taranıyor")
        
        var foundLabel = false
        
        // Duruma göre buton rengini belirle
        let newColor = hideWatchedVideos ? UIColor.systemGreen : UIColor.systemBlue
        
        // Butonun arka plan rengini güncelle
        container.backgroundColor = newColor
        
        // Gölgeyi güncelle
        container.layer.shadowColor = newColor.withAlphaComponent(0.3).cgColor
        
        // Container içindeki stack view'ı bul
        for subview in container.subviews {
            // ContentStack'i bul
            if let contentStack = subview as? UIStackView {
                print("StackView bulundu, eleman sayısı: \(contentStack.arrangedSubviews.count)")
                
                // Stack view içindeki elemanları tara
                for (index, view) in contentStack.arrangedSubviews.enumerated() {
                    if index == 0, let iconView = view as? UIImageView {
                        // İkon görselini güncelle
                        let newIconName = hideWatchedVideos ? "eye" : "eye.slash"
                        print("İkon güncelleniyor: \(newIconName)")
                        iconView.image = UIImage(systemName: newIconName)?.withRenderingMode(.alwaysTemplate)
                    } else if index == 1, let textLabel = view as? UILabel {
                        // Metin etiketini güncelle
                        let newText = hideWatchedVideos ? "Hepsini Göster" : "İzlenenleri Gizle"
                        print("Etiket güncelleniyor: \(newText)")
                        textLabel.text = newText
                        foundLabel = true
                    }
                }
            }
        }
        
        if !foundLabel {
            print("HATA: Metin etiketi bulunamadı!")
        }
        
        // Basma ve renk değişimi için animasyon
        UIView.animate(withDuration: 0.2, animations: {
            container.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                container.transform = .identity
            })
        })
    }
    
    private func createEmptyStateView() -> UIView {
        let containerView = UIView()
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        
        let imageView = UIImageView(image: UIImage(systemName: "play.slash.fill"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Tüm videolar izlendi"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .systemGray
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Başka video görmek için 'Hepsini Göster' butonuna dokunun"
        descriptionLabel.font = UIFont.systemFont(ofSize: 15)
        descriptionLabel.textColor = .systemGray2
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, constant: -40)
        ])
        
        return containerView
    }
    
    private func fetchVideos(playlistId: String, pageToken: String? = nil) {
        var urlString = "\(Config.baseUrl)/playlistItems?key=\(Config.apiKey)&playlistId=\(playlistId)&part=snippet&maxResults=50"
        if let pageToken = pageToken {
            urlString += "&pageToken=\(pageToken)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Invalid URL configuration")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showError("No data received")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistResponse.self, from: data)
                
                DispatchQueue.main.async {
                    // Append new videos to existing ones
                    self.videos.append(contentsOf: response.items)
                    
                    // If there are more pages, fetch them
                    if let nextPageToken = response.nextPageToken {
                        self.fetchVideos(playlistId: playlistId, pageToken: nextPageToken)
                    } else {
                        // All videos fetched, now sort them by date and update UI
                        self.videos.sort { $0.snippet.publishedAt < $1.snippet.publishedAt }
                        self.updateDisplayedVideos()
                        self.pageControl.numberOfPages = Int(ceil(Double(self.videos.count) / Double(self.videosPerPage)))
                        self.collectionView.reloadData()
                        self.activityIndicator.stopAnimating()
                        self.collectionView.isHidden = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError("Failed to decode video data: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    self.collectionView.isHidden = false
                }
            }
        }.resume()
    }
    
    private func openVideo(videoId: String, index: Int) {
        let playerVC = VideoPlayerViewController(videoId: videoId, index: index)
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// Sayfa değişikliğini yönetmek için yeni fonksiyonlar
extension VideoListViewController {
    private func updateDisplayedVideos() {
        // Önce tüm videoları veya sadece izlenmemiş videoları filtrele
        if hideWatchedVideos {
            filteredVideos = videos.filter { videoItem in
                // WatchedVideosManager kullanarak izlenen videoları kontrol et
                return !WatchedVideosManager.shared.isWatched(videoItem.snippet.resourceId.videoId)
            }
        } else {
            filteredVideos = videos
        }
        
        // Görüntülenecek sayfayı güncelle
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        if totalPages > 0 && currentPage >= totalPages {
            currentPage = totalPages - 1 // Sayfa sayısı azaldıysa, geçerli sayfayı güncelle
        }
        
        // Gösterilecek videoları ayarla
        let startIndex = currentPage * videosPerPage
        let endIndex = min(startIndex + videosPerPage, filteredVideos.count)
        
        if startIndex < endIndex {
            displayedVideos = Array(filteredVideos[startIndex..<endIndex])
        } else {
            displayedVideos = []
        }
        
        // Sayfa kontrolünü güncelle
        pageControl.numberOfPages = totalPages
        pageControl.isHidden = (totalPages <= 1)
    }
    
    @objc private func pageControlValueChanged(_ sender: UIPageControl) {
        // Animasyonlu sayfa geçişi
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self = self else { return }
            self.currentPage = sender.currentPage
            self.updateDisplayedVideos()
            self.collectionView.reloadData()
        })
        
        // Page control animasyonu
        UIView.animate(withDuration: 0.2) {
            self.pageControl.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.pageControl.transform = CGAffineTransform.identity
            }
        }
    }
}

extension VideoListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.reuseIdentifier, for: indexPath) as? VideoCollectionViewCell else {
            fatalError("Failed to dequeue VideoCollectionViewCell")
        }
        
        let video = displayedVideos[indexPath.row]
        let absoluteIndex = currentPage * videosPerPage + indexPath.row
        cell.configure(with: video, index: absoluteIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = displayedVideos[indexPath.row]
        let absoluteIndex = currentPage * videosPerPage + indexPath.row
        openVideo(videoId: video.snippet.resourceId.videoId, index: absoluteIndex)
        
        // Tıklama animasyonunu tetikle
        if let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
            cell.handleTap()
        }
    }
}
