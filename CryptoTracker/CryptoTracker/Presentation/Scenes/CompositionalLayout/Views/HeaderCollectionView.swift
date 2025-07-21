import UIKit

final class HeaderCollectionView: UICollectionReusableView, ReuseIdentifiable {
    // UI
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func bind(with text: String) {
        titleLabel.text = text
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - Configure UI
private extension HeaderCollectionView {
    func addSubviews() {
        addSubview(titleLabel)
    }

    func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-4)
            $0.bottom.equalToSuperview().offset(-4)
        }
    }

    func configureViews() {
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
    }
}
