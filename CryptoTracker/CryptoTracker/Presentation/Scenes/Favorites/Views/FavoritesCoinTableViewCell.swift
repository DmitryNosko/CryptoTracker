import UIKit
import Kingfisher

final class FavoritesCoinTableViewCell: UITableViewCell, ReuseIdentifiable {
    var favoriteTrigger: (() -> Void)?

    // UI
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let favoriteButton = UIButton()

    // Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageView.image = nil
        nameLabel.text = nil
        favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .highlighted)
    }

    func bind(with model: CoinModel) {
        iconImageView.kf.setImage(with: model.imageURL)
        iconImageView.kf.indicatorType = .activity
        nameLabel.text = model.name
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

//MARK: - Configure UI
private extension FavoritesCoinTableViewCell {
    func addSubviews() {
        contentView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(favoriteButton)
    }

    func setConstraints() {
        iconContainerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.size.equalTo(44)
            $0.leading.equalToSuperview().offset(16)
        }

        iconImageView.snp.makeConstraints {
            $0.height.width.equalTo(24)
            $0.center.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.centerY.equalTo(contentView.snp.centerY)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-76)
        }

        favoriteButton.snp.makeConstraints {
            $0.size.equalTo(44)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-16)
        }
    }

    func configureViews() {
        // self
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.borderWidth = 0.7
        layer.borderColor = UIColor.lightGray.cgColor
        selectionStyle = .none

        // iconContainerView
        iconContainerView.layer.cornerRadius = 22
        iconContainerView.backgroundColor = .mercury

        // nameLabel
        nameLabel.textColor = .black
        nameLabel.font = .systemFont(ofSize: 16)

        // favoriteButton
        favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .highlighted)
        favoriteButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else {
                return
            }

            self.favoriteTrigger?()
        }), for: .touchUpInside)
    }
}
