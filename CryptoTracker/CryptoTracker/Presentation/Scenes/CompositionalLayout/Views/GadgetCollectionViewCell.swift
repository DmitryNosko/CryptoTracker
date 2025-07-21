import UIKit

final class GadgetCollectionViewCell: UICollectionViewCell, ReuseIdentifiable {
    // UI
    private let imageView = UIImageView()
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

        imageView.image = nil
        nameLabel.text = nil
    }

    func bind(with model: Gadget) {
        imageView.image = .search
        nameLabel.text = model.name
    }

    // Assemble
    func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - Configure UI
private extension GadgetCollectionViewCell {
    func addSubviews() {
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
    }

    func setConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-4)
            $0.bottom.equalToSuperview().offset(-4)
        }
    }

    func configureViews() {
        contentView.backgroundColor = .mercury

        // imageView
        imageView.contentMode = .scaleToFill

        // nameLabel
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .black.withAlphaComponent(0.8)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 0
    }
}
