# PhPhotoDemo
camera and photo library

How to use.

init PhPhoto(target: Any) class
target is self ViewController


Demo:

class ViewController: UIViewController, PhPhotoDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let addImageButton = UIButton()
    let button = UIButton()
    let camera = UIButton()
    var photo: PhPhoto?
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    var imageArr: [UIImage]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        photo = PhPhoto(target: self)
        
    }
    
    func setupViews() {
        overrideUserInterfaceStyle = .light
        self.view.backgroundColor = .white
        addImageButton.frame = CGRect(x: 0, y: 40, width: 50, height: 50)
        addImageButton.backgroundColor = .red
        addImageButton.addTarget(self, action: #selector(addImageAction), for: .touchUpInside)
        self.view.addSubview(addImageButton)
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: addImageButton.bottomAnchor).isActive = true
        if #available(iOS 11.0, *) {
            tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    
    @objc func addImageAction() {
        photo?.addImageAction(selectionLimit: 5)
    }
    
    func getImageArrayWith(phPhoto: PhPhoto, sourceType: SourceType, imageArray: [UIImage]?) {
        guard let imageArray = imageArray else { return }
        imageArr = imageArray
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageArr?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.imageView?.image = imageArr?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

