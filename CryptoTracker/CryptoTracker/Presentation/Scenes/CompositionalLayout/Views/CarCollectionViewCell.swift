import UIKit
import SnapKit

final class CarCollectionViewCell: UICollectionViewCell, ReuseIdentifiable {
    // MARK: - UI
    private let nameLabel = UILabel()
    private let expandButton = UIButton(type: .system)
    private let descriptionLabel = UILabel()

    // MARK: - State
    private var isExpanded = false
    private var descriptionHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        assemble()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        descriptionLabel.text = nil
        updateExpansion(animated: false)
    }

    // MARK: - Public
    func bind(with model: Car) {
        nameLabel.text = model.name
        descriptionLabel.text = "descriptionLabel, descriptionLabel, descriptionLabel, descriptionLabel, descriptionLabel, descriptionLabel"
        nameLabel.backgroundColor = model.isSelected ? .dodgerBlue : .mercury
    }

    // MARK: - Actions
    private func setupActions() {
        expandButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)
    }

    @objc private func expandTapped() {
        isExpanded.toggle()
        updateExpansion(animated: true)

        // Обновляем layout коллекции
        if let collectionView = self.superview as? UICollectionView {
            collectionView.performBatchUpdates(nil)
        }
    }

    private func updateExpansion(animated: Bool) {
        if isExpanded {
            descriptionLabel.isHidden = false
            descriptionHeightConstraint?.deactivate()
            expandButton.setTitle("↑", for: .normal)
        } else {
            descriptionLabel.isHidden = true
            descriptionHeightConstraint?.activate()
            expandButton.setTitle("↓", for: .normal)
        }

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }

    // MARK: - UI Setup
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
        updateExpansion(animated: false) // начальное состояние
    }

    private func addSubviews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(expandButton)
        contentView.addSubview(descriptionLabel)
    }

    private func setConstraints() {
        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(8)
            $0.trailing.equalTo(expandButton.snp.leading).offset(-8)
        }

        expandButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalToSuperview().offset(-8)
            $0.width.height.equalTo(24)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().offset(-8)

            // Эта constraint активируется при свернутом состоянии
            descriptionHeightConstraint = $0.height.equalTo(0).constraint
        }
    }

    private func configureViews() {
        contentView.backgroundColor = .mercury
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        // nameLabel
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .black.withAlphaComponent(0.8)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 0

        // expandButton
        expandButton.setTitle("↓", for: .normal)
        expandButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)

        // descriptionLabel
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.isHidden = true
    }
}
