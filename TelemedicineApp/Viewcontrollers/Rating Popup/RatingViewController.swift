//
//  RatingViewController.swift
//  TelemedicineApp
//
//  Created by Bhavik Darji on 05/04/22.
//

import UIKit

class RatingViewController: UIViewController {
    
    // MARK: - Refference outlet and variables

    @IBOutlet var ratingview: FloatRatingView!
    @IBOutlet weak var btnSubmit: UIButton!
    
    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ratingview.backgroundColor = UIColor.clear

        /** Note: With the exception of contentMode, type and delegate,
         all properties can be set directly in Interface Builder **/
        ratingview.delegate = self
//        ratingview.contentMode = UIView.ContentMode.scaleAspectFit
        ratingview.type = .halfRatings
        
//        // Segmented control init
//        ratingSegmentedControl.selectedSegmentIndex = 1
//
//        // Labels init
//        liveLabel.text = String(format: "%.2f", self.floatRatingView.rating)
//        updatedLabel.text = String(format: "%.2f", self.floatRatingView.rating)

        self.btnSubmit.addShadow(offset: CGSize(width: 1.0, height: 1.0), color: .gray, radius: 5.0, opacity: 0.5)
    }
}

// MARK: - IBAction's

extension RatingViewController
{
    @IBAction func btn_Hiddenclick(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btn_Submitclick(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - FloatRatingViewDelegate

extension RatingViewController: FloatRatingViewDelegate {
    func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating: Double)
    {
//        print("\(String(format: "%.2f", self.ratingview.rating))")
    }
    
    func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Double)
    {
        print("\(String(format: "%.2f", self.ratingview.rating))")
    }
}

