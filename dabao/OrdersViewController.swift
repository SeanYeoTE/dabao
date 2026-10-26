import UIKit

final class OrdersDataSource: UITableViewDiffableDataSource<Section, Order> {
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
        
        dataSource = OrdersDataSource(tableView: tableView) { [weak self] tableView, indexPath, order in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = order.dish
            content.secondaryText = "x\(order.quantity)"
            cell.contentConfiguration = content
            cell.accessoryView = self?.makeQuantityStepper(for: order)
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, Order>()
        snapshot.appendSections([.drinks, .food])
        snapshot.appendItems(orders.filter { $0.isDrink }, toSection: .drinks)
        snapshot.appendItems(orders.filter { !$0.isDrink }, toSection: .food)
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
    private func makeQuantityStepper(for order: Order) -> UIStepper {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.value = Double(order.quantity)
        stepper.addAction(UIAction { [weak self] action in
            guard let stepper = action.sender as? UIStepper else { return }
            self?.changeQuantity(of: order.id, to: Int(stepper.value))
        }, for: .valueChanged)
        return stepper
    }

    private func changeQuantity(of id: UUID, to quantity: Int) {
        guard let index = orders.firstIndex(where: { $0.id == id }) else { return }
        orders[index].quantity = quantity
        save()
        applySnapshot()
    }
}


extension OrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self, let order = self.dataSource.itemIdentifier(for: indexPath) else {
                completion(false)
                return
            }
            self.orders.removeAll { $0.id == order.id }
            self.save()
            self.applySnapshot()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}