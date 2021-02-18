//
//  PlaceViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 27/04/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol PlacesDelegate {
    
    func placeSelected(_ place: String, _ isSource:Bool)
}

class PlaceViewController: UIViewController {

    var places = ["Bengaluru", "New Delhi", "Mumbai", "Kolkata", "Chennai", "Pune"]
    var delegate:PlacesDelegate?
    
    var isSourceSelection:Bool = true
    @IBOutlet weak var placeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension PlaceViewController:UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "place", for: indexPath)
        cell.textLabel?.text = places[indexPath.row]
        return cell
    }
}

extension PlaceViewController:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.placeSelected(places[indexPath.row], isSourceSelection)
        navigationController?.popViewController(animated: true)
    }
}
