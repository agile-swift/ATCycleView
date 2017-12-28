//
//  ATCycleView.swift
//  Pods
//
//  Created by 凯文马 on 2017/11/16.
//

import UIKit
import ATTimer

/// the delegate of cycleView
@objc public protocol ATCycleViewDelegate : NSObjectProtocol {
    
    /// get item count of cycleView
    ///
    /// - Parameter cycleView: current cycleView
    /// - Returns: item count
    @objc func numberOfItems(in cycleView: ATCycleView) -> Int
    
    /// get the view will display in cycleView with index
    ///
    /// - Parameters:
    ///   - cycleView: current cycleView
    ///   - index: index of page
    ///   - reuseView: reuse view, you will get that from second reload data
    /// - Returns: display view
    @objc func cycleView(_ cycleView: ATCycleView, viewAtIndex index:Int,reuseView : UIView?) -> UIView
    
    /// optional, callback after item view clicked
    ///
    /// - Parameters:
    ///   - cycleView: current cycleView
    ///   - index: view index that clicked
    @objc optional func cycleView(_ cycleView: ATCycleView,didSelectIndex index:Int) -> Void

    /// optional, callback after cycly scrolled to index
    ///
    /// - Parameters:
    ///   - cycleView: current cycleView
    ///   - index: view index that scrolled to
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
            self.startTimer()
        }
    }
    
    /// animate interval of auto scroll
    open var autoScrollAnimateInterval : TimeInterval = 0.3
    
    /// current index
    open var index : Int {
        set {
            _realIndex = newValue
        }
        get { return _index }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    /// reload data, the delegate methods will call after reload
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
            _realIndex = 0
        } else {
            _realIndex = _index
        }
    }

    /// config page control, if you do not want to use default please call this method
    ///
    /// - Parameter pageControl: the new page control you need display
    open func configPageControl<ATPageControl>(pageControl : ATPageControl) where ATPageControl : UIView, ATPageControl : ATCycleViewPageControl  {
        if let defaultPageControl : UIView = _defaultPageControl {
            if defaultPageControl != pageControl {
                _defaultPageControl?.removeFromSuperview()
                _defaultPageControl = nil
            }
        }
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
        guard let defaultPageControl : UIView = _defaultPageControl,
            let pageControl = _pageControl as? UIView,
            defaultPageControl == pageControl else {
            return
        }
        _defaultPageControl?.frame = CGRect.init(x: 0, y: self.frame.size.height - 40, width: self.frame.size.width, height: 40)
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
        self.configPageControl(pageControl: _defaultPageControl!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapAction() {
        self.delegate?.cycleView?(self, didSelectIndex: _index)
    }
    
    private func scrollIndexUp() {
        var i : Int?
        i = (_realIndex + 2 + _needCount) % _needCount
        let v = _displayViews[i!]
        v.isHidden = true
        UIView.animate(withDuration: autoScrollAnimateInterval, animations: {
            self._scrollView?.contentOffset.x = (self._scrollView?.contentOffset.x)! + (self._scrollView?.frame.size.width)!
        }, completion: { (finish) in
            v.isHidden = false
        })
    }

    private func startTimer() {
        if autoSrcollTimeInterval == 0 { return }
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
    /// 需要最少页数
    private var _needCount : Int = 3
    /// 按照需要页数计算的索引
    private var _realIndex : Int = 0 {
        didSet {
            _index = _realIndex % _pageCount
        }
    }
    private var _timer : ATTimer?
    private var _isDragging = false

    private var _index : Int = 0 {
        didSet {
            if _pageCount == 0 || _index < 0 || _index >= _pageCount {
                return
            }
            var left = (_realIndex - 1) % _needCount
            if (left < 0) {
                left = left + _needCount
            }
            let leftView = self._displayViews[left]
            leftView.transform = CGAffineTransform.init(translationX: 0, y: 0)
            self._scrollView?.addSubview(leftView)
            
            let mid = self._realIndex % self._needCount
            let midView = self._displayViews[mid]
            midView.transform = CGAffineTransform.init(translationX: self.frame.size.width, y: 0)
            self._scrollView?.addSubview(midView)
            
            let right = (self._realIndex + 1) % self._needCount
            let rightView = self._displayViews[right]
            rightView.transform = CGAffineTransform.init(translationX: self.frame.size.width * 2, y: 0)
            self._scrollView?.addSubview(rightView)
            
            _pageControl?.currentPage = index
            self.delegate?.cycleView?(self, didScrollToIndex: index)
        }
    }
    
    private lazy var _defaultPageControl : UIPageControl? = { ()-> UIPageControl in
        let pageControl = UIPageControl.init()
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
}

extension ATCycleView : UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let defaultX = scrollView.frame.width
        if scrollView.contentOffset.x == 2 * defaultX {
            _realIndex = (_realIndex + _needCount + 1) % _needCount
            scrollView.contentOffset = CGPoint.init(x: defaultX, y: 0)
        } else if scrollView.contentOffset.x == 0 {
            _realIndex = (_realIndex + _needCount - 1) % _needCount
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
