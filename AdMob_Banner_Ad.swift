//
//  AdMob_Banner_Ad.swift
//
//
//  Created on 01/17/18.
//  Copyright © 2018 Aidy. All rights reserved.
//

/*
v1.0: 
  - sdk 7.31, initialize version
v2.0:
  - sdk 7.56, in Info.plist add GADIsAdManagerApp, GADApplicationIdentifier and "App Transport Security Settings" items.
  - set auto fresh on Admob management
  - use test unit ID for testing
*/

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
    fileprivate var timer: Timer!
    
    // interval for  switch show/hide status of banner view , 0 to always show
    fileprivate var timeInterval: TimeInterval = 45

    // MARK: - start Ads SDK
    class func startSDK() {
        loggingPrint("initializing Ads SDK")
        // Initialize Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loggingPrint("initialization finished. version \(GADRequest.sdkVersion())")
    }
    // MARK: - init and deinit
    
    private override init() {}
    
    convenience init(adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     withOrientation orientation: Orientation) {
        self.init()
        self.initialize(adUnitID: adUnitID,
                        toViewController: rootViewController,
                        withOrientation: orientation)
    }
    
    convenience init(adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     at position: Position,
                     withOrientation orientation: Orientation,
                     withVolumeRatio volume: Float,
                     timeInterval seconds: TimeInterval,
                     showOnReceive: Bool) {
        
        self.init()
        
        timeInterval = seconds
        self.showOnReceive = showOnReceive
        self.position = position
        GADMobileAds.sharedInstance().applicationVolume = volume
        
        self.initialize(adUnitID: adUnitID,
                        toViewController: rootViewController,
                        withOrientation: orientation)
    }
    
    fileprivate func initialize(adUnitID: String,
                                toViewController rootViewController: UIViewController,
                                withOrientation orientation: Orientation) {
        
        loggingPrint("AdMob Banner Ad initialize")
        // disable crash and purchase reporting, enable them if you want
        GADMobileAds.sharedInstance().disableSDKCrashReporting()
        GADMobileAds.sharedInstance().disableAutomatedInAppPurchaseReporting()

        let adSize = (orientation == .portrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape
        bannerView = GADBannerView(adSize: adSize)
        loggingPrint("banner view size is \(bannerView.frame), ads size is \(bannerView.adSize)")
        
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        
        self.vc = rootViewController
        self.view = rootViewController.view
        
        setStatuesOfBannerView()
        
    }
    
    func setStatuesOfBannerView() {
        
        loggingPrint("set banner view show hide with time interval value ( \(self.timeInterval) ) ")
        
        if self.timeInterval > 0 {
            startTimer()
        } else {
         self.bannerView.isHidden = false
        }
    }

    deinit {
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
    
    // MARK: - private functions
    
    private func startTimer() {
        if nil == self.timer {
            self.timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                              target: self,
                                              selector: #selector(switchBannerStatus),
                                              userInfo: nil,
                                              repeats: true)
        }
    }
    
    @objc private func switchBannerStatus() {
        self.bannerView.isHidden = !self.bannerView.isHidden
    }
    
    
    // MARK: - Positioning Ad Banner
    
    private func addBannerViewToView(_ bannerView: GADBannerView, at position: Position) {
        loggingPrint("addBannerViewToView")
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        switch position {
        case .top: positionBannerViewFullWidthAtTopOfSafeArea(bannerView)
        default  : positionBannerViewFullWidthAtBottomOfSafeArea(bannerView)
        }
        
    }
    
    
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
    
    // MARK: - Delegation
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        loggingPrint(#function)
        
        if showOnReceive {
            show()
        }
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        loggingPrint("\(#function): code: \(error.code) , desc: \(error.localizedDescription)")
        
        /// Note: If your ad fails to load, you don't need to explicitly request another one as long as you've configured your ad unit to refresh; the Google Mobile Ads SDK respects any refresh rate you specified in the AdMob UI.
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        loggingPrint(#function)
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        loggingPrint(#function)
   }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        loggingPrint(#function)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            loggingPrint("re load after dismiss")
            self?.load()
        }
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        loggingPrint(#function)
    }
    
}


/* Usage sample:

 
 // ad app id is configured in Info.plist
 var bannerAd = AdMob_Banner_Ad(adUnitID: "ca-app-pub-3940256099942544/2934735716",  // test id
                               toViewController: self,
                               at: .bottom,
                               withOrientation: .landscape,
                               withVolumeRatio: 0.1,
                               timeInterval: 60,
                               showOnReceive: true)
bannerAd.load()
bannerAd.show()
 
*/


