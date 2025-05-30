import UIKit

// MARK: - Custom Popup View Class
public class CustomPopupView: UIView {

    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("OK", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton? = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3) // Light gray
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Actions
    var okButtonAction: (() -> Void)?
    var cancelButtonAction: (() -> Void)?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupActions()
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5) // Semi-transparent background
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(okButton)
        if let cancelButton = cancelButton {
            buttonStackView.addArrangedSubview(cancelButton)
        }
    }

    // MARK: - Constraints Setup
    private func setupConstraints() {
        // Center the container view
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 300), // Max width for the popup
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 250), // Minimum width
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            buttonStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            okButton.heightAnchor.constraint(equalToConstant: 40), // Consistent button height
            
        ])
        if let cancelButton = cancelButton{
             NSLayoutConstraint.activate([cancelButton.heightAnchor.constraint(equalToConstant: 40)])
        }
       
    }
    
    // MARK: - Setup Actions
     private func setupActions() {
        okButton.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        if let cancelButton = cancelButton {
            cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        }
    }

    // MARK: - Configuration
     func configure(title: String, message: String, okButtonTitle: String = "OK", cancelButtonTitle: String? = "Cancel") {
        titleLabel.text = title
        messageLabel.text = message
        okButton.setTitle(okButtonTitle, for: .normal)
        if let cancelButtonTitle = cancelButtonTitle, let cancelButton = cancelButton {
            cancelButton.setTitle(cancelButtonTitle, for: .normal)
        }else{
            if let cancelButton = cancelButton{
                cancelButton.removeFromSuperview()
            }
          }
      }

    // MARK: - Button Actions
    @objc private func okButtonTapped() {
        okButtonAction?()
        removeFromSuperview() // Dismiss the popup
    }

    @objc private func cancelButtonTapped() {
        cancelButtonAction?()
        removeFromSuperview() // Dismiss the popup
    }
    func remove() {
        removeFromSuperview() 
    }
    // MARK: - Show Popup
    func show(in window: UIWindow) {
        self.alpha = 0.0
        window.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false;
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: window.topAnchor),
            self.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: window.trailingAnchor),
        ])
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }
}


