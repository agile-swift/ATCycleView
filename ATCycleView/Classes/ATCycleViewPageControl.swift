//
//  ATCycleViewPageControl.swift
//  Alamofire
//
//  Created by 凯文马 on 2017/11/16.
//

import Foundation

public protocol ATCycleViewPageControl : NSObjectProtocol {
    
    var numberOfPages : Int {set get}
    
    var currentPage : Int {set get}
    
    
}
