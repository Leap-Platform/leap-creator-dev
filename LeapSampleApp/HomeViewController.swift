//
//  ViewController.swift
//  LeapSampleApp
//
//  Created by Aravind GS on 17/03/20.
//  Copyright © 2020 Leap Inc. All rights reserved.
//

import UIKit


class HomeViewController: UIViewController {
    
    @IBOutlet weak var source: UIButton!
    @IBOutlet weak var destination: UIButton!
    @IBOutlet weak var search: UIButton!
    @IBOutlet weak var dateOfJourney: UITextField!
    
    var datePicker: UIDatePicker!
    var toolBar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        datePicker = UIDatePicker.init()
        datePicker.setDate(Date(), animated: true)
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(updateDateField), for: .valueChanged)
        datePicker.tag = 101
        dateOfJourney.inputView = datePicker
        
        toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onClickDoneButton))
        toolBar.setItems([space, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        toolBar.tag = 102
        dateOfJourney.inputAccessoryView = toolBar
        
        dateOfJourney.text = convertDateToString(Date())
        
    }

    @IBAction func buttonClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "place", sender: sender)
    }
    
    @IBAction func searchButtonClicked(_ sender: UIButton) {
        performSegue(withIdentifier: "signup", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "place" {
            guard let placeVC = segue.destination as? PlaceViewController else {return}
            guard let btn = sender as? UIButton else {return}
            placeVC.delegate = self
            placeVC.isSourceSelection = (btn == source)
        }
    }
    
    @objc func onClickDoneButton() {
        dateOfJourney.resignFirstResponder()
    }
    
    @objc func updateDateField() {
        dateOfJourney.text = convertDateToString(datePicker.date)
    }
    
    func convertDateToString(_ date:Date) -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd,yyyy"
        
        return dateFormatterPrint.string(from: date)
    }
    
}


extension HomeViewController:PlacesDelegate {
    
    func placeSelected(_ place: String, _ isSource: Bool) {
        if isSource {
            source.setTitle(place, for: .normal)
//            LeapAUI.shared.addIdentifier(identifier: "source", value: place)
        }
        else {destination.setTitle(place, for: .normal)}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dateOfJourney.resignFirstResponder()
    }
}

extension HomeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
