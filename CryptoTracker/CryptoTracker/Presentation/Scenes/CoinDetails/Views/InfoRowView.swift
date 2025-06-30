import UIKit

final class InfoRowView: UIView {
    // UI
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    // Init
    init
    (
        title: String
    ) {
        super.init(frame: .zero)

        titleLabel.text = title
        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }

    func setValueColor(_ color: UIColor) {
        valueLabel.textColor = color
    }

    // Assemble
    private func assemble() {
        addSubviews()
        setConstraints()
        configureViews()
    }
}

// MARK: - Configure UI
private extension InfoRowView {
    func addSubviews() {
        addSubview(titleLabel)
        addSubview(valueLabel)
    }

    func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }
    }

    func configureViews() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
    }
}
