//
//  ViewController.swift
//  Goldenhour2
//
//  Created by Alex Meckes on 11/3/14.
//  Copyright (c) 2014 Alex Meckes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
    override func viewDidLoad() {
        let date:NSDate = NSDate()
        let sunCalc:SunCalc = SunCalc.getTimes(date, latitude: 51.5, longitude: -0.1)
        
        var formatter:NSDateFormatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = NSTimeZone(abbreviation: "GMT")
        var sunriseString:String = formatter.stringFromDate(sunCalc.sunrise)
        println("sunrise is at \(sunriseString)")
        
        let sunPos:SunPosition = SunCalc.getSunPosition(date, latitude: 51.5, longitude: -0.1)
        
        var sunriseAzimuth:Double = sunPos.azimuth * 180 / Constants.PI()
        println("sunrise azimuth: \(sunriseAzimuth)")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}