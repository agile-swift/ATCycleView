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

extension UIPageControl : ATCycleViewPageControl {
    
}

public class CycleViewPageControl : UIPageControl {
//    pageControl.setValue(UIImage.init(named: "dot"), forKeyPath: "pageImage")
//    pageControl.setValue(UIImage.init(named: "dotline"), forKeyPath: "currentPageImage")
    
    private var itemSize = CGSize.init(width: 7, height: 7)
    
    public var indicatorSpacing : CGFloat = 10 {
        didSet {
            layoutIfNeeded()
        }
    }
    
    public func setPageImage(_ image : UIImage, andCurrentImage currentImage: UIImage) {
        super.setValue(image, forKeyPath: "pageImage")
        super.setValue(currentImage, forKeyPath: "currentPageImage")
        itemSize = image.size
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if subviews.count > 0 {
            let y = subviews.first!.frame.origin.y
            let needSize = size(forNumberOfPages: numberOfPages)
            var startX = (self.frame.width - needSize.width) * 0.5
            for index in 0..<subviews.count {
                let view = subviews[index]
                view.frame = CGRect.init(origin: CGPoint.init(x: startX, y: y), size: itemSize)
                startX += (itemSize.width + indicatorSpacing)
            }

        }
    }

    public override func size(forNumberOfPages pageCount: Int) -> CGSize {
        if pageCount > 0 {
            let width = CGFloat(pageCount) * itemSize.width + CGFloat(pageCount - 1) * indicatorSpacing
            return CGSize.init(width: width, height: itemSize.height)
        }
        return super.size(forNumberOfPages: pageCount)
    }
}
