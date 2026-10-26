# dabao

A small UIKit app for keeping a list of food and drink orders ("dabao" is Singlish for takeaway).

## Features

- **Orders list** grouped into **Drinks** and **Food** sections, built with `UITableViewDiffableDataSource`.
- **Add an order** with the **+** button: enter a dish, set the quantity, and flip the **Drink** switch for drinks.
- **Change quantity** with the stepper on each row.
- **Delete** an order by swiping left on its row.
- **Persistence:** orders are saved as JSON to `orders.json` in the app's Documents directory and loaded on launch.

## Requirements

- Xcode 26 or later
- iOS 26.0 deployment target

## Getting started

```sh
git clone git@github.com:SeanYeoTE/dabao.git
open dabao/dabao.xcodeproj
```

Select an iPhone simulator and press **Run** (⌘R).

## Project structure

| File | Purpose |
| --- | --- |
| `dabao/Order.swift` | `Order` model, `Section` enum, and the hand-written `Codable` conformance |
| `dabao/OrdersViewController.swift` | Orders list: diffable data source, section headers, quantity stepper, swipe to delete, save and load |
| `dabao/AddOrderViewController.swift` | Add Order form and the `AddOrderDelegate` protocol it uses to send new orders back to the list |
| `dabao/SceneDelegate.swift` | Sets up the window with the orders list in a navigation controller |

## How it fits together

- **Delegate pattern:** the Add Order screen doesn't know which screen opened it. It calls `delegate?.didAdd(_:)`, and `OrdersViewController` sets itself as the delegate before presenting the form.
- **Diffable data source:** after every change, `applySnapshot()` rebuilds the snapshot from the `orders` array and splits it into sections by `isDrink`. Rows are looked up with `dataSource.itemIdentifier(for:)` rather than by row number, so sections don't break deletes.
- **Identity:** the snapshot holds `Order.ID` values, not whole orders, and the cell provider looks up the latest `Order` from `orders`. Changing a quantity keeps the same ID, so `changeQuantity` calls `reconfigureItems` to refresh that row in place instead of deleting and reinserting it.
