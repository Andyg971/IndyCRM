import UIKit

class InvoiceViewController: UIViewController {
    private let invoiceManager = InvoiceManager()
    private let database = InvoiceDatabase.shared
    
    // UI Elements
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "InvoiceCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Nouvelle Facture", for: .normal)
        button.backgroundColor = InvoiceTheme.primaryColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = InvoiceTheme.Style.cornerRadius
        button.addTarget(self, action: #selector(createNewInvoice), for: .touchUpInside)
        return button
    }()
    
    private var invoices: [StoredInvoice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInvoices()
    }
    
    private func setupUI() {
        title = "Factures"
        view.backgroundColor = .white
        
        // Ajouter le tableau
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Ajouter le bouton
        view.addSubview(createButton)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -20),
            
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadInvoices() {
        do {
            invoices = try database.fetchInvoices()
            tableView.reloadData()
        } catch {
            showError("Erreur lors du chargement des factures", error: error)
        }
    }
    
    @objc private func createNewInvoice() {
        // Vérifier si une nouvelle année a commencé
        InvoiceNumberManager.checkAndResetForNewYear()
        
        // Créer une nouvelle facture avec numéro automatique
        let invoiceNumber = InvoiceNumberManager.generateNextInvoiceNumber()
        
        // Présenter le formulaire de création de facture
        let createVC = CreateInvoiceViewController(invoiceNumber: invoiceNumber)
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        present(nav, animated: true)
    }
    
    private func showError(_ message: String, error: Error) {
        let alert = UIAlertController(
            title: "Erreur",
            message: "\(message)\n\(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension InvoiceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invoices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvoiceCell", for: indexPath)
        let invoice = invoices[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "Facture \(invoice.invoiceNumber)"
        content.secondaryText = """
        Client: \(invoice.clientName)
        Date: \(DateFormatterManager.shared.formatDate(invoice.dateIssued, for: .pdf))
        Total: \(DateFormatterManager.shared.formatCurrency(invoice.total))
        """
        
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let invoice = invoices[indexPath.row]
        
        let detailVC = InvoiceDetailViewController(invoice: invoice)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let invoice = invoices[indexPath.row]
        
        // Action de suppression
        let deleteAction = UIContextualAction(style: .destructive, title: "Supprimer") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            do {
                try self.database.deleteInvoice(invoice)
                self.invoices.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            } catch {
                self.showError("Erreur lors de la suppression", error: error)
                completion(false)
            }
        }
        
        // Action de partage
        let shareAction = UIContextualAction(style: .normal, title: "Partager") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            if let pdfData = invoice.pdfData {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(invoice.invoiceNumber).pdf")
                do {
                    try pdfData.write(to: tempURL)
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    self.present(activityVC, animated: true)
                    completion(true)
                } catch {
                    self.showError("Erreur lors du partage", error: error)
                    completion(false)
                }
            }
        }
        
        shareAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}

// MARK: - CreateInvoiceViewControllerDelegate

extension InvoiceViewController: CreateInvoiceViewControllerDelegate {
    func didCreateInvoice(_ invoice: Invoice) {
        // Sauvegarder la facture
        do {
            let pdfData = try invoiceManager.generatePDFData(invoice: invoice)
            let csvString = try invoiceManager.generateCSVString(invoice: invoice)
            let csvData = csvString.data(using: .utf8)
            
            try database.saveInvoice(invoice, pdfData: pdfData, csvData: csvData)
            loadInvoices() // Recharger la liste
        } catch {
            showError("Erreur lors de la sauvegarde", error: error)
        }
    }
} 