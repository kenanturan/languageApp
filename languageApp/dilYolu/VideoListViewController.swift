import UIKit
import AVKit
import SwiftUI
import SafariServices

class VideoListViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var videos: [PlaylistItem] = []
    private var displayedVideos: [PlaylistItem] = []
    private var filteredVideos: [PlaylistItem] = [] // Filtrelenmiş videolar için yeni dizi
    private var currentPage = 0
    private let videosPerPage = 8
    private var nextPageToken: String?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var hideWatchedVideos = false // İzlenen videoları gizleme durumu
    private var languageSelector: UIView?
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
    
    // Sağa ve sola geçiş için ok butonları
    private lazy var leftArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Şık, transparan iç içe daire tasarımı
        let size: CGFloat = 44
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let arrowImage = renderer.image { context in
            // Dış daire (mavi ton)
            let outerCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.systemBlue.withAlphaComponent(0.3).setFill()
            outerCirclePath.fill()
            
            // İç daire (daha koyu mavi)
            let innerCirclePath = UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: size-10, height: size-10))
            UIColor.systemBlue.withAlphaComponent(0.5).setFill()
            innerCirclePath.fill()
            
            // Ok ikonu
            let arrowPath = UIBezierPath()
            let centerY = size/2
            let arrowWidth: CGFloat = 14
            let arrowHeight: CGFloat = 14
            
            arrowPath.move(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY))
            arrowPath.addLine(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY + arrowHeight/2))
            
            arrowPath.lineWidth = 2.5
            UIColor.white.setStroke()
            arrowPath.stroke()
        }
        
        button.setImage(arrowImage, for: .normal)
        
        // Görsel efektler
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.layer.shadowOpacity = 1
        
        button.addTarget(self, action: #selector(previousPageTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var rightArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Şık, transparan iç içe daire tasarımı
        let size: CGFloat = 44
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let arrowImage = renderer.image { context in
            // Dış daire (mavi ton)
            let outerCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.systemBlue.withAlphaComponent(0.3).setFill()
            outerCirclePath.fill()
            
            // İç daire (daha koyu mavi)
            let innerCirclePath = UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: size-10, height: size-10))
            UIColor.systemBlue.withAlphaComponent(0.5).setFill()
            innerCirclePath.fill()
            
            // Ok ikonu
            let arrowPath = UIBezierPath()
            let centerY = size/2
            let arrowWidth: CGFloat = 14
            let arrowHeight: CGFloat = 14
            
            arrowPath.move(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY))
            arrowPath.addLine(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY + arrowHeight/2))
            
            arrowPath.lineWidth = 2.5
            UIColor.white.setStroke()
            arrowPath.stroke()
        }
        
        button.setImage(arrowImage, for: .normal)
        
        // Görsel efektler
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.layer.shadowOpacity = 1
        
        button.addTarget(self, action: #selector(nextPageTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var segmentedContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true
        
        // Üst parlaklık efekti
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        // İkon oluştur
        let iconType = "eye.slash"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iconImage = UIImage(systemName: iconType, withConfiguration: iconConfig)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .white
        
        // Metin için etiket
        let textLabel = UILabel()
        textLabel.text = NSLocalizedString("hide_watched", comment: "Hide watched")
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        // Stack'e içerikleri ekle
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textLabel)
        
        // Parlaklık efekti için overlay'i ekle
        overlayView.frame = CGRect(x: 0, y: 0, width: 160, height: 20) // Sadece üst yarısına parlaklık ekle
        container.addSubview(overlayView)
        
        // Container'a stack'i ekle
        container.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        // Tıklama işlevi
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleWatchedVideos))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        return container
    }()
    
    // Dil seçimi için kullanılacak dropdown menu
    private var languageTableView: UITableView?
    private var languageDropdown: UIView?
    private var isLanguageDropdownVisible = false
    private var outsideTapGesture: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Video izleme durumu değiştiğinde bildirim için observer ekle
        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoWatchStatusChanged), name: NSNotification.Name("VideoWatchStatusChanged"), object: nil)
        
        // Önce tüm videoların yüklendiğinden ve sıralandığından emin ol
        if !isLoadingCompletedForFirstTime {
            showLoadingScreen()
            return
        }
        
        setupUI()
        loadVideosFromCacheOrAPI()
        updateDisplayedVideos()
        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoListUpdated), name: Notification.Name("VideoListUpdated"), object: nil)
    }
    
    private var isLoadingCompletedForFirstTime: Bool {
        return UserDefaults.standard.bool(forKey: "InitialLoadingCompleted")
    }
    
    // VideoListViewController için videoları önbellekten yükleyen metot
    // Önbellekleme kaldırıldı
    
    // Video listesi güncellendiğinde çağrılan metot
    @objc private func handleVideoListUpdated() {
        updateDisplayedVideos()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    // Video kontrollerini temizle
    deinit {
        // Bildirim gözlemcisini kaldır
        NotificationCenter.default.removeObserver(self)
        print("[VideoList] VideoListViewController deinit çağrıldı, gözlemciler kaldırıldı")
    }
    
    // Video izleme durumu değiştiğinde çağrılacak metot
    @objc private func handleVideoWatchStatusChanged() {
        print("[VideoList] Video izleme durumu değişti, UI güncelleniyor")
        updateDisplayedVideos()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            
            // Eğer tüm videoları gizleme aktifse ve hiç video kalmadıysa boş ekranı göster
            if self.displayedVideos.isEmpty && self.hideWatchedVideos {
                let emptyView = self.createEmptyStateView()
                self.collectionView.backgroundView = emptyView
            } else {
                self.collectionView.backgroundView = nil
            }
            
            // Ok butonlarını ve sayfa kontrolünü güncelle
            self.updateArrowButtons()
        }
    }
    
    private func showLoadingScreen() {
        // Yükleme gösterilirken UI elementlerini gizle
        // collectionView ve pageControl, setupUI'dan önce çağrıldığında nil olabilir
        if collectionView != nil {
            collectionView.isHidden = true
        }
        
        if pageControl != nil {
            pageControl.isHidden = true
        }
        
        // Yükleme göstergesi ekle
        view.backgroundColor = .white
        let loadingView = UIView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        loadingView.addSubview(activityIndicator)
        
        let loadingLabel = UILabel()
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.text = NSLocalizedString("videos_loading", comment: "Videos are loading...")
        loadingLabel.textAlignment = .center
        loadingLabel.font = UIFont.systemFont(ofSize: 16)
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: loadingView.topAnchor),
            
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
        ])
        
        // Tüm videoları yükle, sırala ve önbelleğe al
        loadAllVideos { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // Yükleme tamamlandığında UI'ı güncelle
                UserDefaults.standard.set(true, forKey: "InitialLoadingCompleted")
                
                // UI'ı ana thread'de güncelle
                DispatchQueue.main.async {
                    // Yükleme görünümünü kaldır
                    loadingView.removeFromSuperview()
                    
                    // Normal UI'ı göster
                    self.setupUI()
                    self.loadVideosFromCacheOrAPI()
                    self.updateDisplayedVideos()
                    self.collectionView.isHidden = false
                    self.pageControl.isHidden = false
                }
            }
        }
    }
    
    private func loadAllVideos(completion: @escaping (Bool) -> Void) {
        // Config sınıfını kullanarak GitHub'dan API anahtarını çek
        Config.loadAPIKey { [weak self] success in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if !success {
                print("[VideoList] API anahtarı yüklenemedi, videolar çekilemiyor")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // API anahtarı yüklendikten sonra kontrol et
            if Config.apiKey.isEmpty {
                print("[VideoList] API anahtarı boş, videolar yüklenemiyor")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Config.channelId değerini kullan
            let channelId = Config.channelId
            
            // Tüm videoları yükle
            self.fetchAllVideosForFirstTime(playlistId: channelId) { success, videos in
                if success, let videos = videos {
                    print("[VideoList] Videolar başarıyla yüklendi. Toplam: \(videos.count)")
                    
                    // Videoları sırala - en eski videolar önce gelecek şekilde
                    let sortedVideos = videos.sorted { item1, item2 in
                        guard let date1 = ISO8601DateFormatter().date(from: item1.snippet.publishedAt),
                              let date2 = ISO8601DateFormatter().date(from: item2.snippet.publishedAt) else {
                            return false
                        }
                        // En eski videoları başa al
                        return date1 < date2
                    }
                    
                    print("[VideoList] Videolar eskiden yeniye doğru sıralandı. Toplam: \(sortedVideos.count)")
                    
                    // Ana thread'de tamamlandı bilgisini gönder
                    DispatchQueue.main.async {
                        self.videos = sortedVideos
                        completion(true)
                    }
                } else {
                    print("[VideoList] Video yükleme başarısız!")
                    // Ana thread'de hata bilgisini gönder
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func fetchAllVideosForFirstTime(playlistId: String, pageToken: String? = nil, fetchedVideos: [PlaylistItem] = [], completion: @escaping (Bool, [PlaylistItem]?) -> Void) {
        // Config'den API anahtarı ve URL al
        let apiKey = Config.apiKey
        let baseUrl = Config.baseUrl
        
        // API anahtarı kontrolü
        if apiKey.isEmpty {
            print("[VideoList] API anahtarı boş olduğu için videolar yüklenemiyor")
            DispatchQueue.main.async {
                completion(false, nil)
            }
            return
        }
        
        // Burada playlistId kanal ID'si olabilir, kontrol edelim
        // Kanal ID'si ile başlıyorsa (örn: UC...), önce upload listesini almalıyız
        if playlistId.hasPrefix("UC") {
            // Bu bir kanal ID'si, önce uploads playlist ID'si almalıyız
            print("[VideoList] Bu bir kanal ID'si, önce uploads playlist ID'si alınıyor: \(playlistId)")
            let channelUrlString = "\(baseUrl)/channels?key=\(apiKey)&id=\(playlistId)&part=contentDetails"
            
            guard let channelUrl = URL(string: channelUrlString) else {
                print("[VideoList] Geçersiz kanal URL'si")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            URLSession.shared.dataTask(with: channelUrl) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[VideoList] YouTube kanal API yanıt kodu: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    print("[VideoList] Kanal verisi çekilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                    return
                }
                
                do {
                    // JSON'u ayrıştır
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ChannelResponse.self, from: data)
                    
                    if let uploadsPlaylistId = response.items.first?.contentDetails.relatedPlaylists.uploads {
                        print("[VideoList] Kanal uploads playlist ID'si alındı: \(uploadsPlaylistId)")
                        // Şimdi gerçek playlist ID ile videoları çek
                        self.fetchAllVideosForFirstTime(playlistId: uploadsPlaylistId, pageToken: pageToken, fetchedVideos: fetchedVideos, completion: completion)
                    } else {
                        print("[VideoList] Kanal için uploads playlist ID'si bulunamadı")
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                    }
                } catch {
                    print("[VideoList] Kanal yanıtı ayrıştırma hatası: \(error)")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            }.resume()
            
            return
        }
        
        // Bu noktada elimizde gerçek bir playlist ID var, videoları çekelim
        // URL oluştur ve konsola yazdır (debug için)
        var urlString = "\(baseUrl)/playlistItems?key=\(apiKey)&playlistId=\(playlistId)&part=snippet&maxResults=50"
        if let pageToken = pageToken {
            urlString += "&pageToken=\(pageToken)"
        }
        
        print("[VideoList] YouTube API'ye istek yapılıyor: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[VideoList] Geçersiz URL: \(urlString)")
            DispatchQueue.main.async {
                completion(false, nil)
            }
            return
        }
        
        var allFetchedVideos = fetchedVideos
        
        // URLSession yapılandırması
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // 15 saniye zaman aşımı
        config.waitsForConnectivity = true // Bağlantı bekleme
        
        let session = URLSession(configuration: config)
        
        // API'ye istek gönder
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let _ = self else {
                print("[VideoList] Self referansı kayboldu")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            // Hata kontrolü
            if let error = error {
                print("[VideoList] YouTube API hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            // HTTP yanıt kodunu kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("[VideoList] YouTube API yanıt kodu: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("[VideoList] YouTube API hatalı yanıt kodu: \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                    return
                }
            }
            
            // Veri kontrolü
            guard let data = data, !data.isEmpty else {
                print("[VideoList] YouTube API'den veri alınamadı veya boş veri")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistResponse.self, from: data)
                
                // Yeni videoları ekle
                allFetchedVideos.append(contentsOf: response.items)
                
                // Sonraki sayfayı çek
                if let nextPageToken = response.nextPageToken {
                    self?.fetchAllVideosForFirstTime(playlistId: playlistId, pageToken: nextPageToken, fetchedVideos: allFetchedVideos, completion: completion)
                } else {
                    // Tüm sayfalar başarıyla çekildi
                    completion(true, allFetchedVideos)
                }
            } catch {
                completion(false, nil)
            }
        }.resume()
    }
    
    private func setupUI() {
        title = "" // Başlık kaldırıldı
        view.backgroundColor = .systemBackground
        
        // UI öğelerini oluştur
        createFilterButton()  // Filtreleme butonunu oluştur
        setupNavigationBarItems()
        
        // Collection view yapılandırması
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        // 8 video göstermek için (her satırda 2 video) daha kompakt düzen
        let screenWidth = UIScreen.main.bounds.width
        let itemsPerRow: CGFloat = 2
        let padding: CGFloat = 12 // Kenar boşluklarını azalttık
        let spacing: CGFloat = 12 // Hücreler arası mesafeyi azalttık
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let availableWidth = screenWidth - (2 * padding) - spacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        
        // 16:9 aspect ratio için daha kompakt height hesaplama
        let itemHeight = itemWidth * 9/16 + 28 // Başlık alanını azalttık
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
        
        // OK butonlarını diğer view'lardan sonra ekleyelim ki en üstte görünsün
        view.addSubview(leftArrowButton)
        view.addSubview(rightArrowButton)
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
            pageControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            leftArrowButton.centerYAnchor.constraint(equalTo: pageControl.centerYAnchor),
            leftArrowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),  
            leftArrowButton.widthAnchor.constraint(equalToConstant: 44),
            leftArrowButton.heightAnchor.constraint(equalToConstant: 44),
            
            rightArrowButton.centerYAnchor.constraint(equalTo: pageControl.centerYAnchor),
            rightArrowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),  
            rightArrowButton.widthAnchor.constraint(equalToConstant: 44),
            rightArrowButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Butonları en üste getir
        view.bringSubviewToFront(leftArrowButton)
        view.bringSubviewToFront(rightArrowButton)
    }
    
    private func setupLanguageSelector() {
        // SwiftUI view'ını eklemek için bir controller oluştur
        let languageSelectorVC = UIHostingController(rootView: 
            LanguageSelectorView()
                .environmentObject(AppLanguageManager.shared)
                .frame(width: 100, height: 40)
        )
        languageSelectorVC.view.backgroundColor = .clear
        
        // View Controller hiyerarşisini düzgün kurmadan sadece view'ı alalım
        languageSelector = languageSelectorVC.view
    }
    
    private func setupNavigationBarItems() {
        // Dil seçici butonu için
        let languageButton = UIButton(type: .system)
        languageButton.setTitle(AppLanguageManager.shared.currentLanguage.nativeName, for: .normal)
        languageButton.setImage(UIImage(systemName: "globe"), for: .normal)
        languageButton.tintColor = .systemBlue
        languageButton.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        languageButton.addTarget(self, action: #selector(showLanguageSelector), for: .touchUpInside)
        
        // Dil seçici butonu sola yerleştir
        let leftItem = UIBarButtonItem(customView: languageButton)
        navigationItem.leftBarButtonItem = leftItem
        
        // Filtre butonu sağa yerleştir
        let rightItem = UIBarButtonItem(customView: segmentedContainer)
        navigationItem.rightBarButtonItem = rightItem
    }
    
    @objc private func showLanguageSelector() {
        // Önce mevcut dropdown'ı kaldıralım ve durumu tersine çevirelim
        if isLanguageDropdownVisible {
            hideLanguageDropdown()
            return
        }
        
        isLanguageDropdownVisible = true
        
        // Dropdown container oluştur
        let dropdownContainer = UIView()
        dropdownContainer.backgroundColor = .systemBackground
        dropdownContainer.layer.cornerRadius = 10
        dropdownContainer.layer.shadowColor = UIColor.black.cgColor
        dropdownContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        dropdownContainer.layer.shadowRadius = 5
        dropdownContainer.layer.shadowOpacity = 0.2
        dropdownContainer.layer.borderWidth = 1
        dropdownContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Tablo görünümü oluştur
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.bounces = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.rowHeight = 44
        
        // Dropdown pozisyonunu ayarla
        if let leftBarButton = navigationItem.leftBarButtonItem?.customView {
            let buttonFrame = leftBarButton.convert(leftBarButton.bounds, to: view)
            let dropdownWidth: CGFloat = 160
            let dropdownHeight: CGFloat = CGFloat(AppLanguage.allCases.count * 44)
            
            // Dropdown'ı butonun altında konumlandır - Arapça için RTL desteği
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            
            var xPosition: CGFloat = 0
            if isRTL {
                // Arapça gibi sağdan sola diller için
                xPosition = view.bounds.width - dropdownWidth - 20 // Sağ kenara yakın
            } else {
                // Soldan sağa diller için
                xPosition = max(20, buttonFrame.minX) // En azından 20px sol kenardan uzak
            }
            
            let yPosition = buttonFrame.maxY + 10 + (navigationController?.navigationBar.frame.height ?? 0)
            
            dropdownContainer.frame = CGRect(x: xPosition, y: yPosition, width: dropdownWidth, height: dropdownHeight)
            
            // Z düzeninde en üstte göster
            dropdownContainer.layer.zPosition = 1000
            
            // Tablo görünümünü dropdown container'a ekle
            dropdownContainer.addSubview(tableView)
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: dropdownContainer.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: dropdownContainer.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: dropdownContainer.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: dropdownContainer.bottomAnchor)
            ])
            
            // Dropdown'ı ana görünüme ekle
            view.addSubview(dropdownContainer)
            
            // Tablo ve dropdown referanslarını kaydet
            languageTableView = tableView
            languageDropdown = dropdownContainer
            
            // Dropdown'ı gösterirken animasyon ekle
            dropdownContainer.alpha = 0
            dropdownContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            
            UIView.animate(withDuration: 0.2) {
                dropdownContainer.alpha = 1
                dropdownContainer.transform = .identity
            }
            
            // Dropdown dışına tıklandığında kapatmak için gesture recognizer ekle
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
            outsideTapGesture = tapGesture
        }
    }
    
    @objc private func handleOutsideTap(gesture: UITapGestureRecognizer) {
        if let dropdown = languageDropdown {
            let location = gesture.location(in: view)
            if !dropdown.frame.contains(location) {
                hideLanguageDropdown()
            }
        }
    }
    
    private func hideLanguageDropdown() {
        guard isLanguageDropdownVisible, let dropdown = languageDropdown else { return }
        
        // Dropdown'ı gizle
        UIView.animate(withDuration: 0.2, animations: {
            dropdown.alpha = 0
            dropdown.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            dropdown.removeFromSuperview()
            self.languageDropdown = nil
            self.languageTableView = nil
            
            // Gesture recognizer'ı kaldır
            if let tapGesture = self.outsideTapGesture {
                self.view.removeGestureRecognizer(tapGesture)
                self.outsideTapGesture = nil
            }
        }
        
        isLanguageDropdownVisible = false
    }
    
    private func createFilterButton() {
        // Button container ayarla (daha önce tanımlanmış)
        segmentedContainer.layer.cornerRadius = 20
        segmentedContainer.layer.masksToBounds = true
        segmentedContainer.backgroundColor = hideWatchedVideos ? .systemGreen : .systemBlue
        
        // İçerik stack'i oluştur
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        
        // Üst parlaklık efekti
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        // İkon oluştur
        let iconType = hideWatchedVideos ? "eye" : "eye.slash"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iconImage = UIImage(systemName: iconType, withConfiguration: iconConfig)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .white
        
        // Metin için etiket
        let textLabel = UILabel()
        textLabel.text = hideWatchedVideos ? NSLocalizedString("show_all", comment: "Show all") : NSLocalizedString("hide_watched", comment: "Hide watched")
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        // Stack'e içerikleri ekle
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textLabel)
        
        // Parlaklık efekti için overlay'i ekle
        overlayView.frame = CGRect(x: 0, y: 0, width: 160, height: 20) // Sadece üst yarısına parlaklık ekle
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
    }
    
    /// Her zaman API'den videoları çeker
    private func loadVideosFromCacheOrAPI() {
        activityIndicator.startAnimating()
        collectionView.isHidden = true
        
        // Doğrudan API'den çek
        fetchChannelUploadsPlaylistId()
    }
    
    /// Arka planda güncellemeleri kontrol et (kullanıcı deneyimini etkilemez)
    private func checkForUpdatesInBackground() {
        print("[VideoList] API güncellemeleri arka planda kontrol ediliyor...")
        fetchChannelUploadsPlaylistId(isBackgroundUpdate: true)
    }
    
    private func fetchChannelUploadsPlaylistId(isBackgroundUpdate: Bool = false) {
        if !isBackgroundUpdate {
            activityIndicator.startAnimating()
            collectionView.isHidden = true
        }
        
        let urlString = "\(Config.baseUrl)/channels?key=\(Config.apiKey)&id=\(Config.channelId)&part=contentDetails"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                if !isBackgroundUpdate {
                    self?.showError("Invalid URL configuration")
                }
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    if !isBackgroundUpdate {
                        self?.showError("No data received")
                    }
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChannelResponse.self, from: data)
                if let playlistId = response.items.first?.contentDetails.relatedPlaylists.uploads {
                    self?.fetchVideos(playlistId: playlistId, isBackgroundUpdate: isBackgroundUpdate)
                } else {
                    DispatchQueue.main.async {
                        if !isBackgroundUpdate {
                            self?.showError("Could not find uploads playlist")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if !isBackgroundUpdate {
                        self?.showError("Failed to decode channel data: \(error.localizedDescription)")
                    }
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
        print("Container alt elemanları taranıyor")
        
        var foundLabel = false
        
        // Duruma göre buton rengini belirle
        let newColor = hideWatchedVideos ? UIColor.systemGreen : UIColor.systemBlue
        
        // Butonun arka plan rengini güncelle
        segmentedContainer.backgroundColor = newColor
        
        // Gölgeyi güncelle
        segmentedContainer.layer.shadowColor = newColor.withAlphaComponent(0.3).cgColor
        
        // Container içindeki stack view'ı bul
        for subview in segmentedContainer.subviews {
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
                        let newText = hideWatchedVideos ? NSLocalizedString("show_all", comment: "Show all videos") : NSLocalizedString("hide_watched", comment: "Hide watched videos")
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
            self.segmentedContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.segmentedContainer.transform = .identity
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
        titleLabel.text = NSLocalizedString("all_videos_watched", comment: "All videos watched")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .systemGray
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString("show_all_videos_info", comment: "Tap 'Show All' to see more videos")
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
    
    private func fetchVideos(playlistId: String, pageToken: String? = nil, isBackgroundUpdate: Bool = false, fetchedVideos: [PlaylistItem] = []) {
        // Her zaman maksimum sayıda video çek
        let maxResults = 50 // Her istekte 50 video çek
        
        var urlString = "\(Config.baseUrl)/playlistItems?key=\(Config.apiKey)&playlistId=\(playlistId)&part=snippet&maxResults=\(maxResults)"
        if let pageToken = pageToken {
            urlString += "&pageToken=\(pageToken)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                if !isBackgroundUpdate {
                    self?.showError("Invalid URL configuration")
                }
            }
            return
        }
        
        print("[VideoList] \(isBackgroundUpdate ? "Arka planda" : "Ön planda") API isteği gönderiliyor: \(maxResults) video istendi")
        
        // Yerel değişkende mevcut videoları sakla
        var allFetchedVideos = fetchedVideos
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Önce internet bağlantısı hatasını kontrol et
            if let error = error as NSError?, error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    DispatchQueue.main.async {
                        if !isBackgroundUpdate {
                            self.showError(NSLocalizedString("no_internet_connection", comment: "No internet connection"))
                        }
                    }
                    return
                default:
                    break
                }
            }
            
            // HTTP hata kodlarını kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("[VideoList] YouTube API yanıt kodu: \(httpResponse.statusCode)")
                
                // 400, 401 veya 403 hatası API anahtarı sorunu olabilir
                if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    print("[VideoList] API anahtarı hatası olasılığı var, yenileme deneniyor...")
                    
                    Config.refreshAfterAPIFailure() { success in
                        if success {
                            print("[VideoList] API anahtarı başarıyla yenilendi, video yükleme tekrar deneniyor...")
                            // Videoyu tekrar yüklemeyi dene
                            DispatchQueue.main.async {
                                if !isBackgroundUpdate {
                                    self.fetchChannelUploadsPlaylistId(isBackgroundUpdate: isBackgroundUpdate)
                                }
                            }
                        } else {
                            // Yenileme başarısız, kullanıcıya hata göster
                            DispatchQueue.main.async {
                                if !isBackgroundUpdate {
                                    self.showError(NSLocalizedString("api_key_update_failed", comment: "API key update failed"))
                                }
                            }
                        }
                    }
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    if !isBackgroundUpdate {
                        self.showError(NSLocalizedString("no_data_received", comment: "No data received"))
                    }
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistResponse.self, from: data)
                
                // Yeni videoları ekle
                allFetchedVideos.append(contentsOf: response.items)
                
                // API limit tasarrufu: İlk sayfada yeterli video alındıysa ve arka plan güncellemesi değilse,
                // sonraki sayfaları şimdilik çekme - kullanıcı tarafından talep edilmediği sürece
                let hasEnoughVideosForFirstLoad = allFetchedVideos.count >= videosPerPage && pageToken == nil && !isBackgroundUpdate
                
                // Sonraki sayfayı çek (yeterli video yoksa veya arka plan güncellemesiyse)
                if let nextPageToken = response.nextPageToken, (!hasEnoughVideosForFirstLoad || isBackgroundUpdate) {
                    self.fetchVideos(playlistId: playlistId, pageToken: nextPageToken, isBackgroundUpdate: isBackgroundUpdate, fetchedVideos: allFetchedVideos)
                } else {
                    // Tüm videoları çekmek için bir sonraki sayfaya geç
                    if let nextPageToken = response.nextPageToken {
                        self.fetchVideos(playlistId: playlistId, pageToken: nextPageToken, isBackgroundUpdate: isBackgroundUpdate, fetchedVideos: allFetchedVideos)
                    } else {
                        // Tüm videolar çekildi, şimdi tarihe göre sırala ve UI'ı güncelle
                        DispatchQueue.main.async {
                            if !isBackgroundUpdate {
                                // Normal yükleme - UI'ı güncelle
                                print("[VideoList] Toplam çekilen video sayısı: \(allFetchedVideos.count)")
                                // En eski videoları başa al
                                self.videos = allFetchedVideos.sorted { $0.snippet.publishedAt < $1.snippet.publishedAt }
                                self.updateDisplayedVideos()
                                self.pageControl.numberOfPages = Int(ceil(Double(self.videos.count) / Double(self.videosPerPage)))
                                self.collectionView.reloadData()
                                self.activityIndicator.stopAnimating()
                                self.collectionView.isHidden = false
                            } else {
                                // Arka plan güncellemesi - önbelleği güncelle ama UI'ı değiştirme
                                print("[VideoList] Arka plan güncellemesi tamamlandı: \(allFetchedVideos.count) video alındı")
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if !isBackgroundUpdate {
                        self.showError(String(format: NSLocalizedString("playlist_decode_error", comment: "Failed to decode playlist data"), error.localizedDescription))
                    }
                }
            }
        }.resume()
    }
    
    @objc private func openVideo(videoId: String, index: Int) {
        let playerVC = VideoPlayerViewController(videoId: videoId, index: index)
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("warning", comment: "Warning"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// Sayfa değişikliğini yönetmek için yeni fonksiyonlar
extension VideoListViewController {
    // Sayfa değiştirme işlemleri için yeni buton eventi
    @objc private func previousPageTapped() {
        if currentPage > 0 {
            let newPage = currentPage - 1
            pageControl.currentPage = newPage
            animatePageChange(to: newPage)
        }
    }
    
    @objc private func nextPageTapped() {
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        if currentPage < totalPages - 1 {
            let newPage = currentPage + 1
            pageControl.currentPage = newPage
            animatePageChange(to: newPage)
        }
    }
    
    private func animatePageChange(to page: Int) {
        // Butonun basılma animasyonu
        let button = page > currentPage ? rightArrowButton : leftArrowButton
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform.identity
            }
        }
        
        // Sayfa geçiş animasyonu
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self = self else { return }
            self.currentPage = page
            self.updateDisplayedVideos()
            self.collectionView.reloadData()
            self.updateArrowButtons()
        })
    }
    
    private func updateArrowButtons() {
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        leftArrowButton.isEnabled = currentPage > 0
        rightArrowButton.isEnabled = currentPage < totalPages - 1
        
        // Devre dışı butonlar için görsel geribildirim
        UIView.animate(withDuration: 0.3) {
            self.leftArrowButton.alpha = self.currentPage > 0 ? 1.0 : 0.3
            self.rightArrowButton.alpha = self.currentPage < totalPages - 1 ? 1.0 : 0.3
        }
    }
    
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
        
        // Ok butonlarını güncelle
        updateArrowButtons()
    }
    
    @objc private func pageControlValueChanged(_ sender: UIPageControl) {
        // Animasyonlu sayfa geçişi
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self = self else { return }
            self.currentPage = sender.currentPage
            self.updateDisplayedVideos()
            self.collectionView.reloadData()
            self.updateArrowButtons()
            
            // Butonları en üste getir
            self.view.bringSubviewToFront(self.leftArrowButton)
            self.view.bringSubviewToFront(self.rightArrowButton)
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

extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppLanguage.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        cell.textLabel?.text = AppLanguage.allCases[indexPath.row].nativeName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textColor = .systemGray
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Seçilen dili güncelle
        let selectedLanguage = AppLanguage.allCases[indexPath.row]
        
        // Dil değişimini yönet
        let currentLanguage = AppLanguageManager.shared.currentLanguage
        if currentLanguage != selectedLanguage {
            // Dil seçimini güncelle
            AppLanguageManager.shared.currentLanguage = selectedLanguage
            
            // Dil değişimini LanguageManager ile de uygula (bu UserDefaults'u ve Bundle'ı günceller)
            LanguageManager.shared.setLanguage(selectedLanguage)
            
            // Dil butonunu güncelle
            if let languageButton = navigationItem.leftBarButtonItem?.customView as? UIButton {
                languageButton.setTitle(selectedLanguage.nativeName, for: .normal)
            }
            
            // Dil değişikliği yapıldığını ve yeniden başlatılması gerektiğini kullanıcıya bildir
            let message = NSLocalizedString("restart_required", comment: "Restart required message")
            let alert = UIAlertController(title: NSLocalizedString("attention", comment: "Attention title"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
            present(alert, animated: true)
        }
        
        // Dil seçicisini gizle
        hideLanguageDropdown()
    }
}

// Not: Config.loadAPIKey metodu Config.swift dosyasına taşındı
