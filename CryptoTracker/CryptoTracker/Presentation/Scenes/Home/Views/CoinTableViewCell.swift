import UIKit
import Kingfisher

final class CoinTableViewCell: UITableViewCell, ReuseIdentifiable {
    // UI
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let favoriteButton = UIButton()

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }, completion: { finished in
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                }
            })
        }
    }

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
        priceLabel.text = nil
        favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "star"), for: .highlighted)
    }

    func bind(with model: CoinModel) {
        iconImageView.kf.setImage(with: model.imageURL)
        nameLabel.text = model.name
        priceLabel.text = model.formattedPrice
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

//MARK: - Configure UI
private extension CoinTableViewCell {
    func addSubviews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(favoriteButton)
    }

    func setConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.width.equalTo(24)
            $0.leading.equalToSuperview().offset(16)
        }

        nameLabel.snp.makeConstraints {
            $0.bottom.equalTo(contentView.snp.centerY)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-76)
        }

        priceLabel.snp.makeConstraints {
            $0.top.equalTo(contentView.snp.centerY)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(8)
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
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        selectionStyle = .none

        // nameLabel
        nameLabel.textColor = .black
        nameLabel.font = .systemFont(ofSize: 16)

        // priceLabel
        priceLabel.textColor = .black.withAlphaComponent(0.8)
        priceLabel.font = .systemFont(ofSize: 12)

        // favoriteButton
        favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "star"), for: .highlighted)
    }
}
