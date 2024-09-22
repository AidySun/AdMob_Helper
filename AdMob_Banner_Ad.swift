//
//  AdMob_Banner_Ad.swift
//
//
//  Created on 01/17/18.
//  Copyright © 2018 Aidy. All rights reserved.
//

/*
v6.0:
  - remove default interval time value, rename timeInterval to intervalSeconds to make unit more clear
v5.0:
  - add `public func show(in vc: UIViewController)` to support change view controller when showing
v4.0:
  - add `bannerViewDidReceiveAd(_ bannerView: GADBannerView)`, adViewDidReceiveAd() doesn't work anymore
v3.0:
  - always show ads bar
  - test with sdk 7.64
v2.0:
  - sdk 7.56, in Info.plist add GADIsAdManagerApp, GADApplicationIdentifier and "App Transport Security Settings" items.
  - set auto fresh on Admob management
  - use test unit ID for testing
 v1.0:
 - sdk 7.31, initialize version
*/

#if !targetEnvironment(macCatalyst)

import UIKit
import GoogleMobileAds

class AdMob_Banner_Ad: NSObject {

    // MARK: - Properties

    fileprivate let previewImagesNames = [
        "localAdsTalkingNum",
        "localAdsAMClock"
    ]


    fileprivate let appURLs = [
        "https://apps.apple.com/app/id1501166219", // Talking Numbers
        "https://apps.apple.com/app/id1314360935" // AMClock
    ]


    fileprivate var localAdsIndex: Int = 0

    // banner ad position in parent view
    enum Position {case top, bottom}
    // portrait or landscape
    enum Orientation {case portrait, landscape}

    fileprivate var vc: UIViewController!

    var bannerView: GADBannerView!
    fileprivate var view: UIView!

    fileprivate var hasAdsReceived = false
    fileprivate var localAdsView = UIImageView()

    fileprivate var position = Position.top
    fileprivate var showOnReceive = true
    fileprivate var timer: Timer!

    // interval for  switch show/hide status of banner view , 0 to always show
    fileprivate var intervalSeconds: TimeInterval = 10


    fileprivate var shouldHideBannerAd = false

    // MARK: - start Ads SDK
    /* This should be called as early as possible the app starts,
       e.g. in didFinishLaunchingWithOptions() of AppDelegate
     */
    class func startSDK() {
        // Initialize Google Mobile Ads SDK
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["b37ec2debc0c40ce8abb3b202f685a36"]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loggingPrint("[Ads] initialization finished.")
    }

    // MARK: - init and deinit

    private override init() {}

    convenience init(adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     withOrientation orientation: Orientation) {
        self.init()

        self.initEverything(adUnitID: adUnitID,
                            toViewController: rootViewController,
                            withOrientation: orientation)
    }

    convenience init(adUnitID: String,
                     toViewController rootViewController: UIViewController,
                     at position: Position,
                     withOrientation orientation: Orientation,
                     withVolumeRatio volume: Float,
                     intervalSeconds seconds: TimeInterval,
                     showOnReceive: Bool) {

        self.init()

        // use default 10 forever ***
        intervalSeconds = seconds
        loggingPrint("intervalSeconds = \(intervalSeconds)")

        self.showOnReceive = showOnReceive
        self.position = position
        GADMobileAds.sharedInstance().applicationVolume = volume

        self.initEverything(adUnitID: adUnitID,
                            toViewController: rootViewController,
                            withOrientation: orientation)
    }

    fileprivate func initEverything(adUnitID: String,
                                    toViewController rootViewController: UIViewController,
                                    withOrientation orientation: Orientation) {
        updateRootViewController(rootViewController)

        self.initAdsView(adUnitID: adUnitID,
                         withOrientation: orientation)
    }

    fileprivate func initLocalAdsView(withOrientation orientation: Orientation) {
        localAdsView.isHidden = true

        let size = (orientation == .portrait) ? kGADAdSizeSmartBannerPortrait.size : kGADAdSizeSmartBannerLandscape.size
        self.localAdsView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size:size)
        self.localAdsView.contentMode = .scaleAspectFit
        self.localAdsView.backgroundColor = .black

        self.localAdsView.isUserInteractionEnabled = true
        self.localAdsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(adsViewClicked)))
    }

    fileprivate func initAdsView(adUnitID: String,
                                withOrientation orientation: Orientation) {

        // disable crash and purchase reporting, enable them if you want
        GADMobileAds.sharedInstance().disableSDKCrashReporting()

        let adSize = (orientation == .portrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape
        bannerView = GADBannerView(adSize: adSize)
        loggingPrint("[Ads] banner view size is \(bannerView.frame), ads size is \(bannerView.adSize)")

        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self.vc
        bannerView.delegate = self

        setStatuesOfBannerView()
    }

    func setStatuesOfBannerView() {

        loggingPrint("[Ads] set banner view show hide with time interval value ( \(self.intervalSeconds) ) ")

        if self.intervalSeconds > 0 {
            startTimer()
        } else {
            self.bannerView.isHidden = false
        }
    }

    deinit {
        invalidateTimer()
    }

    fileprivate func invalidateTimer() {
        if nil != timer {
            timer.invalidate()
        }
    }

    fileprivate func updateRootViewController(_ rootViewController: UIViewController) {
        self.vc = rootViewController
        self.view = rootViewController.view
    }

    // MARK: - public functions

    public func load() {
        bannerView.load(GADRequest())
    }

    // show online ads if received, else show local ads view
    public func show() {

        localAdsView.isHidden = true
        bannerView.isHidden = shouldHideBannerAd || !hasAdsReceived

        self.localAdsView.isUserInteractionEnabled = false
        let adsView: UIView = hasAdsReceived ? bannerView : localAdsView

        addAdsView(adsView, toPosition: position)
    }

    public func show(in vc: UIViewController) {
        updateRootViewController(vc)

        show()
    }

    public func stop() {
        DispatchQueue.main.async {
            self.bannerView.isHidden = true
            self.invalidateTimer()
            self.bannerView.isHidden = true
        }
    }

    public func setIsHidden(_ b: Bool) {
        self.shouldHideBannerAd = b
    }

    // MARK: - private functions

    private func startTimer() {
        if nil == self.timer && intervalSeconds > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: intervalSeconds,
                                              target: self,
                                              selector: #selector(switchBannerStatusForTimer),
                                              userInfo: nil,
                                              repeats: true)
        }
    }


    @objc private func switchBannerStatusForTimer() {
        localAdsView.isHidden = true
        bannerView.isHidden = !hasAdsReceived || shouldHideBannerAd
        localAdsIndex += 1


        shouldHideBannerAd = !shouldHideBannerAd

        self.localAdsView.image = nil
        if !hasAdsReceived {
            // let img =  UIImage(named: previewImagesNames[localAdsIndex/2])
            // self.localAdsView.image = img
        }

        if localAdsIndex >= 3 {
            localAdsIndex = 0
        }
    }

    @objc private func adsViewClicked() {
        loggingPrint("[Ads] adsViewClicked... \(appURLs[localAdsIndex])")
        UIApplication.shared.open(URL(string: appURLs[localAdsIndex])!)
    }

    // MARK: - Positioning Ad Banner
    private func addAdsView(_ adsView: UIView, toPosition position: Position) {
        adsView.removeFromSuperview()

        adsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adsView)

        switch position {
        case .top:
            positionBannerViewFullWidthAtTopOfSafeArea(adsView)
        default:
            positionBannerViewFullWidthAtBottomOfSafeArea(adsView)
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


}

// MARK: - Delegation

extension AdMob_Banner_Ad: GADBannerViewDelegate {

    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        loggingPrint("[Ads] \(#function)")

        self.hasAdsReceived = true

        if showOnReceive {
            show()
        }
    }

    // added on 20230228 to fix online AD bar not shown on device
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        loggingPrint("[Ads] bannerViewDidReceiveAd")

        self.hasAdsReceived = true

        if showOnReceive {
            show()
        }
    }

    /// Tells the delegate an ad request failed.
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        loggingPrint("[Ads] \(#function): desc: \(error.localizedDescription)")

        self.hasAdsReceived = false

        DispatchQueue.main.asyncAfter(deadline: .now()+5) { [weak self] in
            loggingPrint("reload after failed")
            self?.load()
        }


        /// Note: If your ad fails to load, you don't need to explicitly request another one as long as you've configured your ad unit to refresh; the Google Mobile Ads SDK respects any refresh rate you specified in the AdMob UI.
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        loggingPrint("[Ads] \(#function)")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        loggingPrint(#function)
   }

    /// Tells the delegate that the full-screen view has been dismissed.
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        loggingPrint(#function)
        DispatchQueue.main.asyncAfter(deadline: .now() + intervalSeconds) { [weak self] in
            loggingPrint("reload after dismiss")
            self?.load()
        }
    }
}


/* Usage sample:


 // ad app id is configured in Info.plist
 var bannerAd = AdMob_Banner_Ad(adUnitID: "ca-app-pub-3940256099942544/2934735716",  // test id
                               toViewController: self,
                               at: .bottom,
                               withOrientation: .landscape,
                               withVolumeRatio: 0.1,
                               intervalSeconds: 60,
                               showOnReceive: true)
bannerAd.load()
bannerAd.show()

*/


#endif
