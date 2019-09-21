//
//  OptionsView.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 08/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class ModalWindow {
  /// Controller for add self view
  private(set) weak var rootController: UIViewController?

  /// Container view controller
  private(set) weak var childController: UIViewController?

  /// Complete event handler
  public var completeHandler: (() -> Void)?

  /// Button for close modal window
  private var _closeButton: UIButton?
  public var closeButton: UIButton {
    guard let button = self._closeButton else {
      let button = UIButton(frame: .zero)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setBackgroundImage(UIImage(named: "close-modal"), for: .normal)
      button.addTarget(self, action: #selector(touchButtonClose(sender:)), for: .touchUpInside)
      _closeButton = button
      return button
    }
    return button
  }

  /// Background for modal
  private var _backgroundView: UIView?
  public var backgroundView: UIView {
    guard let view = self._backgroundView else {
      let view = UIView(frame: .zero)
      view.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
      _backgroundView = view
      return view
    }
    return view
  }

  /// Container modal
  private var _containerView: UIView?
  public var containerView: UIView {
    guard let view = self._containerView else {
      let view = UIView(frame: .zero)
      view.translatesAutoresizingMaskIntoConstraints = false
      view.backgroundColor = UIColor.clear
      _containerView = view
      return view
    }
    return view
  }

  /// State visible of modal view
  public var isShow: Bool = false {
    didSet {
      if isShow { show() }
      else { hide() }
    }
  }

  public init(root: UIViewController, child: UIViewController, isShowClose: Bool = true) {
    rootController = root
    childController = child
    setupViews()
    setupConstraints()
    closeButton.isHidden = !isShowClose
  }

  /// Setups for self view and add loading indicator
  private func setupViews() {
    guard let rootController = self.rootController,
      let childController = self.childController,
      let rootView = rootController.view,
      let childView = childController.view else { return }

    // Main views
    backgroundView.isHidden = true
    backgroundView.alpha = 0
    backgroundView.addSubview(containerView)
    containerView.addSubview(childView)
    containerView.addSubview(closeButton)

    // Root and child controllers
    childView.translatesAutoresizingMaskIntoConstraints = false
    childView.clipsToBounds = true
    childView.cornerRadius = 6.0
    rootController.addChild(childController)
    rootView.addSubview(backgroundView)
  }

  /// Setting constraints for subviews
  private func setupConstraints() {
    guard let rootView = self.rootController?.view,
      let childView = self.childController?.view else { return }

    let constraints: [NSLayoutConstraint] = [
      //
      self.backgroundView.topAnchor.constraint(equalTo: rootView.topAnchor),
      self.backgroundView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
      self.backgroundView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      self.backgroundView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      //
      self.containerView.topAnchor.constraint(equalTo: self.backgroundView.topAnchor, constant: 60),
      self.containerView.bottomAnchor.constraint(equalTo: self.backgroundView.bottomAnchor, constant: -60),
      self.containerView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor, constant: 20),
      self.containerView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor, constant: -20),
      //
      childView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
      childView.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor),
      childView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
      childView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor),
      //
      self.closeButton.widthAnchor.constraint(equalToConstant: 30),
      self.closeButton.heightAnchor.constraint(equalToConstant: 30),
      self.closeButton.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 6),
      self.closeButton.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor, constant: -6),
    ]

    NSLayoutConstraint.activate(constraints)
  }

  /// Target event for close button
  @objc public func touchButtonClose(sender _: UIButton) {
    isShow = false
  }

  /// Show modal
  private func show() {
    guard childController != nil else { return }

    backgroundView.isHidden = false
    backgroundView.alpha = 0
    UIView.animate(withDuration: 0.25, animations: {
      self.backgroundView.alpha = 1
    })
  }

  /// Hide modal
  private func hide() {
    guard childController != nil else { return }

    UIView.animate(withDuration: 0.25, animations: {
      self.backgroundView.alpha = 0
    }) { _ in
      self.backgroundView.isHidden = true
      // Call complete handler
      if let completeHandler = self.completeHandler {
        completeHandler()
      }
    }
  }
}
