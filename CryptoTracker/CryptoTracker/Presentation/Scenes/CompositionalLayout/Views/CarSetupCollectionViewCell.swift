import UIKit

final class CarSetupCollectionViewCell: UICollectionViewCell, ReuseIdentifiable {
    // UI
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.cornerRadius = contentView.frame.height / 2
        contentView.layer.masksToBounds = true
    }

    func bind(with model: CarSetup) {
        nameLabel.text = model.setupSettings
        contentView.layer.borderColor = model.isSelected ? UIColor.black.cgColor : UIColor.clear.cgColor
    }

    // Assemble
    func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - Configure UI
private extension CarSetupCollectionViewCell {
    func addSubviews() {
        contentView.addSubview(nameLabel)
    }

    func setConstraints() {
        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-12)
            $0.bottom.equalToSuperview().offset(-4)
        }
    }

    func configureViews() {
        contentView.backgroundColor = .mercury
        contentView.layer.borderWidth = 1

        // nameLabel
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .black.withAlphaComponent(0.8)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 0
    }
}
