//
//  ATCycleView.swift
//  Pods
//
//  Created by 凯文马 on 2017/11/16.
//

import UIKit
import ATTimer

@objc public protocol ATCycleViewDelegate : NSObjectProtocol {
    
    @objc func numberOfItems(in cycleView: ATCycleView) -> Int
    
    @objc func cycleView(_ cycleView: ATCycleView, viewAtIndex index:Int,reuseView : UIView?) -> UIView
    
    @objc optional func cycleView(_ cycleView: ATCycleView,didSelectIndex index:Int) -> Void

    @objc optional func cycleView(_ cycleView: ATCycleView,didScrollToIndex index:Int) -> Void

}

open class ATCycleView: UIView {

    /// config the view by delegate method
    open var delegate : ATCycleViewDelegate?

    /// change the pageControl when display more than a half of view, default is true
    open var changePageControlWhenHalf : Bool = true
    
    /// auto scroll interval , if do not want to scroll auto,set to 0, default is 0
    open var autoSrcollTimeInterval : TimeInterval = 0 {
        willSet {
            self.endTimer()
        }
        didSet {
            if autoSrcollTimeInterval != 0 {
                self.startTimer()
            }
        }
    }
    
    open var autoScrollAnimateInterval : TimeInterval = 0.3
    
    open var index : Int {
        set { _index = newValue }
        get { return _index }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    open func reloadData() -> Void {
        _scrollView?.frame = bounds

        for view in _displayViews {
            view.removeFromSuperview()
            view.transform = CGAffineTransform.identity
            _cacheViews.insert(view)
        }
        _displayViews.removeAll()
        
        let count = self.delegate?.numberOfItems(in: self) ?? 0
        _pageCount = count
        _pageControl?.numberOfPages = count
        _needCount = count
        if _needCount < 3 {
            _needCount = _needCount == 1 ? 3 :  4
        }
        for index in 0..<_needCount {
            let reuseView = _cacheViews.first
            let view = self.delegate!.cycleView(self, viewAtIndex: index % count, reuseView: reuseView)
            if reuseView == view {
                _cacheViews.removeFirst()
            }
            _displayViews.append(view)
        }

        if (_index >= _pageCount) {
            _index = 0
        } else {
            let idx = _index
            _index = idx
        }
    }

    open func configPageControl<ATPageControl>(pageControl : ATPageControl) where ATPageControl : UIView, ATPageControl : ATCycleViewPageControl  {
        _pageControl = pageControl
        _pageControl?.numberOfPages = _pageCount
        self.addSubview(pageControl)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if _scrollView != nil {
            _scrollView!.frame = self.bounds
            _scrollView!.contentSize = CGSize.init(width: (_scrollView?.frame.width)! * 3, height: 0)
            _scrollView?.contentOffset = CGPoint.init(x: _scrollView!.frame.width, y: 0)
        }
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            reloadData()
        }
    }
    
    private func setupView() {
        _scrollView = UIScrollView()
        _scrollView?.delegate = self
        _scrollView?.bounces = false
        _scrollView?.showsVerticalScrollIndicator = false
        _scrollView?.showsHorizontalScrollIndicator = false
        _scrollView?.isPagingEnabled = true
        addSubview(_scrollView!)
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
        
        let pageControl = UIPageControl.init(frame: CGRect.init(x: 0, y: self.frame.size.height - 40, width: self.frame.size.width, height: 40))
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        self.configPageControl(pageControl: pageControl)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapAction() {
        self.delegate?.cycleView?(self, didSelectIndex: _index)
    }
    
    private func scrollIndexUp() {
        let i = (_index + 2 + _pageCount) % _pageCount
        let v = _displayViews[i]
        v.isHidden = true
        UIView.animate(withDuration: autoScrollAnimateInterval, animations: {
            self._scrollView?.contentOffset = CGPoint.init(x: (self._scrollView?.contentOffset.x)! + (self._scrollView?.frame.size.width)!, y: 0)
        }, completion: { (finish) in
            v.isHidden = false
        })
    }
    
    private func scrollIndexDown() {
        let i = (_index - 2 + _pageCount) % _pageCount
        let v = _displayViews[i]
        v.isHidden = true
        UIView.animate(withDuration: autoScrollAnimateInterval, animations: {
            self._scrollView?.contentOffset = CGPoint.init(x: (self._scrollView?.contentOffset.x)! - (self._scrollView?.frame.size.width)!, y: 0)
        }, completion: { (finish) in
            v.isHidden = false
        })
    }

    private func startTimer() {
        _timer = ATTimer.init(interval: autoSrcollTimeInterval, repeatTimes: UInt.max, queue: .main, handler: { [weak self] (timer, times) in
            self?.scrollIndexUp()
        })
        _timer?.fire()
    }
    
    private func endTimer() {
        _timer = nil
    }
    
    private var _scrollView : UIScrollView?
    private var _displayViews : [UIView] = []
    private var _pageCount : Int = 0
    private var _cacheViews : Set<UIView> = []
    private var _pageControl : ATCycleViewPageControl?
    private var _needCount : Int = 3 ///
    private var _timer : ATTimer?
    private var _isDragging = false

    private var _index : Int = 0 {
        didSet {
            if _pageCount == 0 || _index < 0 || _index >= _pageCount {
                return
            }
            var left = (_index - 1) % _needCount
            if (left < 0) {
                left = left + _needCount
            }
            let leftView = self._displayViews[left]
            leftView.transform = CGAffineTransform.init(translationX: 0, y: 0)
            self._scrollView?.addSubview(leftView)
            
            let mid = self._index % self._needCount
            let midView = self._displayViews[mid]
            midView.transform = CGAffineTransform.init(translationX: self.frame.size.width, y: 0)
            self._scrollView?.addSubview(midView)
            
            let right = (self._index + 1) % self._needCount
            let rightView = self._displayViews[right]
            rightView.transform = CGAffineTransform.init(translationX: self.frame.size.width * 2, y: 0)
            self._scrollView?.addSubview(rightView)
            
            _pageControl?.currentPage = index
            self.delegate?.cycleView?(self, didScrollToIndex: index)
        }
    }
    
}

extension ATCycleView : UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let defaultX = scrollView.frame.width
        if scrollView.contentOffset.x == 2 * defaultX {
            _index = (_index + _pageCount + 1) % _pageCount
            scrollView.contentOffset = CGPoint.init(x: defaultX, y: 0)
        } else if scrollView.contentOffset.x == 0 {
            _index = (_index + _pageCount - 1) % _pageCount
            scrollView.contentOffset = CGPoint.init(x: defaultX, y: 0)
        }
        // adjust page control
        if _pageControl == nil && changePageControlWhenHalf { return }
        let centerX = scrollView.contentOffset.x + defaultX * 0.5

        if centerX < defaultX {
            let i = (_index - 1 + _pageCount) % _pageCount;
            if (i != self._pageControl?.currentPage) {
                self._pageControl?.currentPage = i;
            }
        } else if centerX > defaultX * 2 {
            let i = (_index + 1 + _pageCount) % _pageCount;
            if (i != self._pageControl?.currentPage) {
                self._pageControl?.currentPage = i;
            }
        } else {
            let i = _index;
            if (i != self._pageControl?.currentPage) {
                self._pageControl?.currentPage = i;
            }
        }
        
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _isDragging = true
        endTimer()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        _isDragging = false
        startTimer()
    }
}


extension UIPageControl : ATCycleViewPageControl {
    
}
