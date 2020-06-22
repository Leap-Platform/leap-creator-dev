//
//  SearchHotelViewController.swift
//  JinySampleApp
//
//  Created by Aravind GS on 13/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

class SearchHotelViewController: UIViewController {
    
    @IBOutlet weak var destination:UIButton!
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "places" {
            guard let place = segue.destination as? PlaceViewController else { return }
            place.delegate = self
        }
    }

}

extension SearchHotelViewController:PlacesDelegate {
    
    func placeSelected(_ place: String, _ isSource: Bool) {
        destination.setTitle(place, for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dateOfJourney.resignFirstResponder()
    }
    
}

