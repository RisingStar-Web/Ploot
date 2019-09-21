//
//  PetMenuController.swift
//  Ploot
//
//  Created by Aleksey Pleshkov on 09/11/2018.
//  Copyright © 2018 Aleksey Pleshkov. All rights reserved.
//

import UIKit

class PetMenuController: UIViewController {
  /// Pet presenter, set from Pet Controller
  public var petPresenter: PetPresenter?

  /// Core data manager
  private(set) lazy var coreDataManager = CoreDataManager.data

  /// Decorations product list
  public var decorationsList: [ProductModel] = []
  private var alertResetPet: UIAlertController?

  /// UI
  @IBOutlet var tableProducts: UITableView!
  @IBOutlet var labelLeftDays: UILabel!
  @IBOutlet var labelLevelPet: UILabel!
  @IBOutlet var labelPoints: UILabel!
  @IBOutlet var buttonBuyDecotaion: UIButton!

  /// Reset pet in core data
  @IBAction func resetPet(sender _: UIButton) {
    guard let alertResetPet = self.alertResetPet else { return }

    present(alertResetPet, animated: true, completion: nil)
  }

  /// Buy selected decoration
  @IBAction func buyDecoration(_: UIButton) {
    guard let petPresenter = self.petPresenter,
      let indexSelected = self.tableProducts.indexPathForSelectedRow else { return }

    petPresenter.placeDecoration(index: indexSelected.row)
    updateUIData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupAlertResetPet()
  }

  /// Update UI data
  public func updateUIData() {
    guard let activePet = self.petPresenter?.activePet else {
      return
    }

    // Set count birth days pet
    buttonBuyDecotaion.isAccess = false
    labelLeftDays.text = "\(activePet.daysFromBirth)"
    labelLevelPet.text = "\(activePet.level)"
    labelPoints.text = "\(activePet.points)"

    // Update products list
    decorationsList = GlobalData.data.productsListInPetMenu.filter { product in
      !activePet.decorationsList.contains(product.name)
    }

    // Update table of products
    tableProducts.reloadData()

    // Logger
    Logger.info("UpdateUIData", from: self)
  }

  /// Setting alert message about reset pet
  private func setupAlertResetPet() {
    guard let petPresenter = self.petPresenter else { return }

    // Reset pet
    func resetPet(_: UIAlertAction) {
      petPresenter.clearPet()
      coreDataManager.clearData()
      performSegue(withIdentifier: "Store", sender: self)
    }

    // Alert localization
    let alertTitle = NSLocalizedString("Reset pet", comment: "PetMenu reset pet alert")
    let alertDesc = NSLocalizedString("Do you really want to reset your pet data?", comment: "PetMenu reset pet alert")
    let alertActionYesTitle = NSLocalizedString("Yes", comment: "PetMenu reset pet alert action yes")
    let alertActionCancelTitle = NSLocalizedString("Cancel", comment: "PetMenu reset pet alert action cancel")

    // Alert setting
    let alert = UIAlertController(title: alertTitle, message: alertDesc, preferredStyle: .alert)
    let alertActionYes = UIAlertAction(title: alertActionYesTitle, style: .default, handler: resetPet)
    let alertActionCancel = UIAlertAction(title: alertActionCancelTitle, style: .cancel, handler: nil)

    alert.addAction(alertActionYes)
    alert.addAction(alertActionCancel)
    alertResetPet = alert
  }
}

// MARK: - UITableViewDelegate

extension PetMenuController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 40
  }

  func tableView(_: UITableView, didSelectRowAt _: IndexPath) {
    buttonBuyDecotaion.isAccess = true
  }

  func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard let activePet = self.petPresenter?.activePet else { return nil }
    let product = decorationsList[indexPath.row]

    return activePet.points >= product.price ? indexPath : nil
  }
}

// MARK: - UITableViewDataSource

extension PetMenuController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return decorationsList.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let product = decorationsList[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)

    // Init cell with product patams
    if let productCell = cell as? ProductViewCell {
      productCell.initCell(product: product)
    }

    return cell
  }
}
