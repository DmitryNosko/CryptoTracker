import UIKit
import Combine

final class SearchView: UIView {
    // UI
    private let iconImageView = UIImageView()
    private let textField = UITextField()

    // Combine
    let searchDidBeginTrigger = PassthroughSubject<String?, Never>()
    let searchTextDidChangeTrigger = PassthroughSubject<String, Never>()
    let searchDidEndTrigger = PassthroughSubject<String?, Never>()

    // Data
    private var isClearing: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        assemble()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 22
    }

    func setText(_ text: String) {
        textField.text = text
    }

    private func assemble() {
        addSubviews()
        configureViews()
        setConstraints()
    }
}

private extension SearchView {
    func addSubviews() {
        addSubview(iconImageView)
        addSubview(textField)
    }

    func configureViews() {
        backgroundColor = .white

        layer.borderWidth = 0.7
        layer.borderColor = UIColor.lightGray.cgColor

        iconImageView.image = .search
        iconImageView.contentMode = .scaleAspectFill

        textField.placeholder = "Search Coins"
        textField.font = .systemFont(ofSize: 16)
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
    }

    func setConstraints() {
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.top.leading.bottom.equalToSuperview().inset(16)
        }

        textField.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(iconImageView)
        }
    }

    func updateShadowPath() {
        let shadowPath = UIBezierPath(roundedRect: bounds.insetBy(dx: -2, dy: -2), cornerRadius: layer.cornerRadius)
        layer.shadowPath = shadowPath.cgPath
    }
}

extension SearchView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchDidBeginTrigger.send(textField.text)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        searchDidEndTrigger.send(textField.text)
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        isClearing = true
        searchTextDidChangeTrigger.send("")
        DispatchQueue.main.async {
            self.isClearing = false
        }
        return true
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if isClearing {
            return true
        }

        if let currentText = textField.text, let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            searchTextDidChangeTrigger.send(updatedText)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
