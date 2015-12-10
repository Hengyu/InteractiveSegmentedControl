//
//  ViewController.swift
//  InteractiveSegmentedControlDemo
//
//  Created by hengyu on 15/12/10.
//  Copyright © 2015年 hengyu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let swipe = UIPanGestureRecognizer(target: nil, action: nil)
        view.addGestureRecognizer(swipe)
        
        let seg = InteractiveSegmentedControl(items: ["a", "b", "c"])
        seg.selectedSegmentIndex = 1
        seg.frame = CGRectMake(100, 100, 100, 44)
        seg.interactiveGesture = swipe
        view.addSubview(seg)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

