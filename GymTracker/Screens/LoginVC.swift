//
//  LoginVC.swift
//  GymTracker
//
//  Created by Ben Huggins on 1/1/23.
//

import UIKit
import AuthenticationServices

class LoginVC: UIViewController {
    
    private let appleSignInButton = ASAuthorizationAppleIDButton()
    let countrySelectionVC = MainMapVC()
    
	let logoImageView: UIImageView = {
		let logoImage = UIImageView()
		logoImage.image = UIImage(named: "logo_transparent_background")
		logoImage.translatesAutoresizingMaskIntoConstraints = false
		logoImage.contentMode = .scaleAspectFit
		return logoImage
	}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        view.addSubview(appleSignInButton)
        view.addSubview(logoImageView)
        appleSignInButton.addTarget(self, action: #selector(didTapSignInButton), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }
    
    func appleSignInButtonConstraints() {
        appleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        appleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        appleSignInButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 100).isActive = true
        appleSignInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2).isActive = true
        appleSignInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2).isActive = true
        appleSignInButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    func logoImageViewConstraints() {
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        logoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        logoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        logoImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
    }

    @objc func didTapSignInButton() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoImageViewConstraints()
        appleSignInButtonConstraints()
    }

    func performExistingAccountSetupFlows() {
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension LoginVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
		let userIdentifier = appleIDCredential.user
			_ = appleIDCredential.fullName
			_ = appleIDCredential.email
		self.saveUserInKeychain(userIdentifier)
	   
		let vc1 = UINavigationController(rootViewController: MainMapVC())
		vc1.title = "Map"
		vc1.modalPresentationStyle = .fullScreen
		present(vc1, animated: true)

        case let passwordCredential as ASPasswordCredential:
	
		// Sign in using an existing iCloud Keychain credential.
		let username = passwordCredential.user
		let password = passwordCredential.password
		
		DispatchQueue.main.async {
			self.showPasswordCredentialAlert(username: username, password: password)
		}
        default:
            break
        }
    }
    
    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.benhuggins.GymTracker", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
    
    private func showResultViewController(userIdentifier: String, fullName: PersonNameComponents?, email: String?) {
        guard let viewController = self.presentingViewController as? MainMapVC
            else { return }
        
        DispatchQueue.main.async {
            viewController.userIdentifierLabel = userIdentifier
            if let givenName = fullName?.givenName {
                viewController.givenNameLabel = givenName
            }
            if let familyName = fullName?.familyName {
                viewController.familyNameLabel = familyName
            }
            if let email = email {
                viewController.emailLabel = email
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		showAlert(withTitle: "Auth Error!", message: "Error: \(error)")
    }
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension UIViewController {
    func showLoginViewController() {
        let loginViewController = LoginVC()
        loginViewController.modalPresentationStyle = .fullScreen
        present(loginViewController, animated: true)
        }
    }


