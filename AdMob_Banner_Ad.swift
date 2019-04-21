//
//  AdMob_Banner_Ad.swift
//
//
//  Created on 01/17/18.
//  Copyright © 2018 Aidy. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdMob_Banner_Ad: NSObject, GADBannerViewDelegate {
    
    // MARK: - Properties
    
    // banner ad position in parent view
    enum Position {case top, bottom}
    // portrait or landscape
    enum Orientation {case portrait, landscape}
    
    fileprivate var vc: UIViewController!
    fileprivate var bannerView: GADBannerView!
    fileprivate var view: UIView!
    
    fileprivate var position = Position.top
    fileprivate var showOnReceive = true
    fileprivate var reloadOnError = true
    fileprivate var timer: Timer!
    
    // interval for 1. seconds to wait before reloading (when error occurred or dismissed)
    //              2. switch show/hide status of banner view
    fileprivate var timeInterval: TimeInterval = 60

    // MARK: - init and deinit
    
    private override init() {}
    
    convenience init(admobAppID: String,
                     adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     withOrientation orientation: Orientation) {
        self.init()
        self.initialize(admobAppID: admobAppID,
                        adUnitID: adUnitID,
                        toViewController: rootViewController,
                        withOrientation: orientation)
    }
    
    convenience init(admobAppID: String,
                     adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     at position: Position,
                     withOrientation orientation: Orientation,
                     withVolumeRatio volume: Float,
                     timeInterval seconds: TimeInterval,
                     showOnReceive: Bool,
                     reloadOnError: Bool) {
        
        self.init()
        
        timeInterval = seconds
        self.showOnReceive = showOnReceive
        self.reloadOnError = reloadOnError
        self.position = position
        GADMobileAds.sharedInstance().applicationVolume = volume
        
        self.initialize(admobAppID: admobAppID,
                        adUnitID: adUnitID,
                        toViewController: rootViewController,
                        withOrientation: orientation)
    }
    
    fileprivate func initialize(admobAppID: String,
                                adUnitID: String,
                                toViewController rootViewController: UIViewController,
                                withOrientation orientation: Orientation) {
        
        GADMobileAds.configure(withApplicationID: admobAppID)
        // disable crash and purchase reporting, enable them if you want
        GADMobileAds.disableSDKCrashReporting()
        GADMobileAds.disableAutomatedInAppPurchaseReporting()

        let adSize = (orientation == .portrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape
        bannerView = GADBannerView(adSize: adSize)
        
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        
        self.vc = rootViewController
        self.view = rootViewController.view
        
        // start timer
        startTimer()
    }

    deinit {
        invalidateTimer()
    }
    
    fileprivate func invalidateTimer() {
        if nil != timer {
            timer.invalidate()
        }
    }
    
    // MARK: - public functions
    
    public func load() {
        bannerView.load(GADRequest())
    }
    
    public func show() {
        addBannerViewToView(bannerView, at: position)
    }
    
    public func stop() {
        self.bannerView.isHidden = true
        invalidateTimer()
        self.bannerView.isHidden = true
    }
    
    // MARK: - private functions
    
    private func startTimer() {
        if nil == self.timer {
            self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(switchBannerStatus), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func switchBannerStatus() {
        self.bannerView.isHidden = !self.bannerView.isHidden
    }
    
    
    // MARK: - Positioning Ad Banner
    
    private func addBannerViewToView(_ bannerView: GADBannerView, at position: Position) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        
        if #available(iOS 11.0, *) {
            switch position {
            case .top: positionBannerViewFullWidthAtTopOfSafeArea(bannerView)
            default  : positionBannerViewFullWidthAtBottomOfSafeArea(bannerView)
            }
        }
        else {
            switch position {
            case .top: positionBannerViewFullWidthAtTopOfView(bannerView)
            default  : positionBannerViewFullWidthAtBottomOfView(bannerView)
            }
        }
    }
    
    
    @available (iOS 11, *)
    private func positionBannerViewFullWidthAtBottomOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Make it constrained to the edges of the safe area.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: bannerView.rightAnchor),
            guide.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor)
            ])
    }
    
    @available (iOS 11, *)
    private func positionBannerViewFullWidthAtTopOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the top of the Safe Area.
        // Make it constrained to the edges of the safe area.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: bannerView.rightAnchor),
            guide.topAnchor.constraint(equalTo: bannerView.topAnchor)
            ])
    }
    
    // @available (iOS 7, *)
    private func positionBannerViewFullWidthAtTopOfView(_ bannerView: UIView) {
        
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: vc.topLayoutGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    private func positionBannerViewFullWidthAtBottomOfView(_ bannerView: UIView) {
        
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: vc.bottomLayoutGuide,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    
    // MARK: - Delegation
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print(#function)
        
        if showOnReceive {
            show()
        }
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("\(#function): \(error.localizedDescription)")
        
        if reloadOnError {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
                print("loading Ad async")
                self?.load()
            }
        }
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        loggingPrint("adViewWillPresentScreen")
        print(#function)
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print(#function)
   }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        loggingPrint("adViewDidDismissScreen")
        print(#function)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            print("re load after dismiss")
            self?.load()
        }
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print(#function)
    }
    
}


/* Usage sample:

 
 var bannerAd = AdMob_Banner_Ad(admobAppID: "ca-app-pub-3940256099942544~1458002511",  // test id
                               adUnitID: "ca-app-pub-3940256099942544/2934735716",  // test id
                               toViewController: self,
                               at: .bottom,
                               withOrientation: .landscape,
                               withVolumeRatio: 0.1,
                               timeInterval: 60,
                               showOnReceive: true,
                               reloadOnError: true)
bannerAd.load()
bannerAd.show()
 
*/


