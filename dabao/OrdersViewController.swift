import UIKit

final class OrdersDataSource: UITableViewDiffableDataSource<Section, Order.ID> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sectionIdentifier(for: section) {
        case .drinks: "Drinks"
        case .food: "Food"
        case nil: nil
        }
    }
}

final class OrdersViewController: UIViewController , AddOrderDelegate {
    private let tableView = UITableView()
    
    private var orders: [Order] = [
        Order(dish: "Chicken rice", quantity: 1, isDrink: false),
        Order(dish: "Teh peng", quantity: 2, isDrink: true),
        Order(dish: "Roti prata", quantity: 3, isDrink: false)
    ]
    
    private var dataSource: OrdersDataSource!
    private let fileURL = URL.documentsDirectory.appending(path: "orders.json")
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(orders)
            try data.write(to: fileURL)
            
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([Order].self, from: data) else { return }
        orders = saved
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Orders"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add,
            primaryAction: UIAction { [weak self] _ in self?.showAddOrder() }
        )
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        
        dataSource = OrdersDataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            // The snapshot only holds IDs, so always read the latest order from `orders`.
            guard let self, let order = self.orders.first(where: { $0.id == id }) else { return cell }
            var content = cell.defaultContentConfiguration()
            content.text = order.dish
            content.secondaryText = "x\(order.quantity)"
            cell.contentConfiguration = content
            self.configureQuantityStepper(in: cell, for: order)
            return cell
        }
        dataSource.defaultRowAnimation = .fade
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .add, primaryAction: UIAction { [weak self] _ in self?.showAdd() })
        load()
        applySnapshot()
        print(fileURL)
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Order.ID>()
        snapshot.appendSections([.drinks, .food])
        snapshot.appendItems(orders.filter { $0.isDrink }.map(\.id), toSection: .drinks)
        snapshot.appendItems(orders.filter { !$0.isDrink }.map(\.id), toSection: .food)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func showAddOrder() {
        let addOrder = AddOrderViewController()
        // Step 6: sign up as the delegate before showing the form.
        addOrder.delegate = self
        present(UINavigationController(rootViewController: addOrder), animated: true)
    }
    
    private func showAdd() {
        let addVC = AddOrderViewController()
        addVC.delegate = self
        present(UINavigationController(rootViewController: addVC), animated: true)
    }
    
    func didAdd(_ order: Order) {
        orders.append(order)
        save()
        applySnapshot()
    }
}

extension OrdersViewController {
    private static let quantityActionID = UIAction.Identifier("quantity")

    // Reuses the cell's existing stepper so reconfiguring doesn't swap it out mid-tap.
    private func configureQuantityStepper(in cell: UITableViewCell, for order: Order) {
        let stepper: UIStepper
        if let existing = cell.accessoryView as? UIStepper {
            stepper = existing
        } else {
            stepper = UIStepper()
            stepper.minimumValue = 1
            cell.accessoryView = stepper
        }
        stepper.value = Double(order.quantity)
        // Same identifier replaces the action from this cell's previous order.
        stepper.addAction(UIAction(identifier: Self.quantityActionID) { [weak self] action in
            guard let stepper = action.sender as? UIStepper else { return }
            self?.changeQuantity(of: order.id, to: Int(stepper.value))
        }, for: .valueChanged)
    }

    private func changeQuantity(of id: Order.ID, to quantity: Int) {
        guard let index = orders.firstIndex(where: { $0.id == id }) else { return }
        orders[index].quantity = quantity
        save()
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([id])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self, let id = self.dataSource.itemIdentifier(for: indexPath) else {
                completion(false)
                return
            }
            self.orders.removeAll { $0.id == id }
            self.save()
            self.applySnapshot()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}