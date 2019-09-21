//
//  StoreController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 25/10/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class StoreController: UIViewController {
  /// Presenter
  private(set) lazy var storePresenter = StorePresenter()

  /// Modal window
  private(set) var loaderModal: ModalWindow?

  /// UI
  @IBOutlet var tableStore: UITableView!
  @IBOutlet var buttonApplyPet: UIButton!

  /// Event apply pet
  @IBAction func buttonApplyPet(_: UIButton) {
    guard let loaderModal = self.loaderModal else { return }

    // Apply selected pet
    storePresenter.applySelectedPet()

    // Show loading modal and bind handler
    loaderModal.isShow = true
    loaderModal.completeHandler = { [weak self] in
      self?.performSegue(withIdentifier: "Scene", sender: self)
    }

    // Close loading modal after 2 seconds
    DispatchQueue.syncTimeoutRun(timeout: 2) {
      loaderModal.isShow = false
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Block apply button
    buttonApplyPet.isAccess = false

    // Set delegate to store presenter
    storePresenter.delegate = self

    // Change setting in table
    tableStore.rowHeight = UITableView.automaticDimension
    tableStore.estimatedRowHeight = 160
    tableStore.reloadData()

    // Setting loader modal window
    if let storyboard = self.storyboard,
      let loaderController = storyboard
      .instantiateViewController(withIdentifier: "LoaderModal") as? LoaderController {
      loaderModal = ModalWindow(root: self, child: loaderController)
      loaderModal?.closeButton.isHidden = true
    }
  }
}

// MARK: - StorePresenterDelegate

extension StoreController: StorePresenterDelegate {
  func petSelected(storePet _: StoreModel) {
    buttonApplyPet.isAccess = true
  }
}

// MARK: - UITableViewDelegate

extension StoreController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 40
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    storePresenter.selectPet(index: indexPath.row)
  }
}

// MARK: - UITableViewDataSource

extension StoreController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return GlobalData.data.petsListInStore.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let storePet = GlobalData.data.petsListInStore[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "StoreCell", for: indexPath)

    // Default init cell
    if let storeCell = cell as? StoreViewCell {
      storeCell.initCell(petName: storePet.visibleName)
    }

    return cell
  }
}
