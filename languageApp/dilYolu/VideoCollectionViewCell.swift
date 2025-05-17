import UIKit

class VideoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "VideoCell"
    
    private let indexLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .black.withAlphaComponent(0.7)
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.systemBlue.cgColor
        return view
    }()
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let playIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        imageView.image = UIImage(systemName: "play.circle.fill", withConfiguration: config)
        imageView.alpha = 0.9
        return imageView
    }()
    
    private let watchedIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGreen
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        imageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        imageView.isHidden = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        thumbnailImageView.addSubview(playIconView)
        thumbnailImageView.addSubview(indexLabel)
        thumbnailImageView.addSubview(watchedIconView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        playIconView.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        watchedIconView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            thumbnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            playIconView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 50),
            playIconView.heightAnchor.constraint(equalToConstant: 50),
            
            indexLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 8),
            indexLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.leadingAnchor, constant: 8),
            indexLabel.widthAnchor.constraint(equalToConstant: 40),
            indexLabel.heightAnchor.constraint(equalToConstant: 40),
            
            watchedIconView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 8),
            watchedIconView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -8),
            watchedIconView.widthAnchor.constraint(equalToConstant: 30),
            watchedIconView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    

    
    @objc func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
    
    func configure(with video: PlaylistItem, index: Int) {
        indexLabel.text = String(index + 1)
        
        // Arkaplan rengini ayarla (thumbnail yüklenene kadar görünecek)
        thumbnailImageView.backgroundColor = .systemGray5
        
        // Video ID'sini yazdır (hata ayıklama için)
        let videoId = video.snippet.resourceId.videoId
        print("[\(index)] Video ID: \(videoId)")
        
        // Load thumbnail
        if let thumbnailUrl = URL(string: video.snippet.thumbnails.medium.url) {
            print("[\(index)] Thumbnail URL: \(thumbnailUrl)")
            
            URLSession.shared.dataTask(with: thumbnailUrl) { [weak self] data, response, error in
                // Cevap ve hata kontrolü
                if let error = error {
                    print("[\(index)] Thumbnail hatası: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[\(index)] Thumbnail yanıt kodu: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        // Hatalı HTTP yanıtı, alternatif thumbnail dene
                        self?.loadDefaultThumbnail(for: videoId, index: index)
                        return
                    }
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.thumbnailImageView.image = image
                    }
                } else {
                    print("[\(index)] Thumbnail verisi işlenemedi")
                    // Thumbnail veri yüklenemedi, alternatif thumbnail dene
                    self?.loadDefaultThumbnail(for: videoId, index: index)
                }
            }.resume()
        } else {
            print("[\(index)] Geçersiz thumbnail URL")
            // URL oluşturulamadı, alternatif thumbnail dene
            loadDefaultThumbnail(for: videoId, index: index)
        }
        
        // Update watched status
        watchedIconView.isHidden = !WatchedVideosManager.shared.isWatched(videoId)
    }
    
    /// YouTube video ID'sine göre alternatif thumbnail yükleme
    private func loadDefaultThumbnail(for videoId: String, index: Int) {
        // Doğrudan YouTube'dan thumbnail URL'si oluştur
        let alternativeUrl = "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg"
        print("[\(index)] Alternatif thumbnail deneniyor: \(alternativeUrl)")
        
        guard let url = URL(string: alternativeUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("[\(index)] Alternatif thumbnail hatası: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.thumbnailImageView.image = image
                    print("[\(index)] Alternatif thumbnail başarıyla yüklendi")
                }
            } else {
                print("[\(index)] Alternatif thumbnail yüklenemedi")
            }
        }.resume()
    }
}
