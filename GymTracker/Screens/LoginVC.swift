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
        view.addSubview(appleSignInButton)
        view.addSubview(logoImageView)
        
        appleSignInButton.addTarget(self, action: #selector(didTapSignInButton), for: .touchUpInside)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
//    }
    
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

    // - Tag: perform_appleid_password_request
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension LoginVC: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // For the purpose of this demo app, store the `userIdentifier` in the keychain.
            self.saveUserInKeychain(userIdentifier)
            
//            // This is where I jump to after logging in.
//            let navController = UINavigationController(rootViewController: countrySelectionVC)
//            navController.modalPresentationStyle = .fullScreen
//           // self.present(navController, animated:true, completion: nil)
//            self.show(navController, sender: nil)
//
//
            
            let tabBar = UITabBarController()
            tabBar.tabBar.barTintColor = .gray
            let vc1 = UINavigationController(rootViewController: MainMapVC())
            vc1.title = "Map"
            
            let vc2 = UINavigationController(rootViewController: AddLocationVC())
            vc2.navigationController?.navigationBar.backgroundColor = .gray
            vc2.title = "Add Location Tracker"
            
            tabBar.setViewControllers([vc1, vc2], animated: false)
            tabBar.modalPresentationStyle = .fullScreen
            tabBar.tabBar.backgroundColor = .darkGray
            tabBar.tabBar.barTintColor = .white
            tabBar.tabBar.tintColor = .systemBlue
            present(tabBar, animated: true)
        
        case let passwordCredential as ASPasswordCredential:
        
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
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
    
    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension UIViewController {
    func showLoginViewController() {
        let loginViewController = LoginVC()
        loginViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.present(loginViewController, animated: true)
        }
    }


