//
//  ViewController.swift
//  ATCycleView
//
//  Created by devkevinma@gmail.com on 11/16/2017.
//  Copyright (c) 2017 devkevinma@gmail.com. All rights reserved.
//

import UIKit
import ATCycleView

class ViewController: UIViewController,ATCycleViewDelegate {
    let colors = [UIColor.red,UIColor.blue,UIColor.yellow,UIColor.purple]
    func numberOfItems(in cycleView: ATCycleView) -> Int {
        return 4
    }
    
    func cycleView(_ cycleView: ATCycleView, viewAtIndex index: Int, reuseView: UIView?) -> UIView {
        var view : UIView?
        if reuseView != nil {
            view = reuseView
        } else {
            view = UIView.init(frame: cycleView.bounds)
            view?.backgroundColor = colors[index]
        }
        
        return view!
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let v = ATCycleView.init(frame: CGRect.init(x: 0, y: 100, width: view.frame.width, height: 200))
        v.delegate = self
        v.pageMode = true
        view.addSubview(v)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
}

