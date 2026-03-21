import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let listTileFactory = ListTileNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self, factoryId: "listTile", nativeAdFactory: listTileFactory
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [String: Any]? = nil
  ) -> GADNativeAdView? {
    let nativeAdView = GADNativeAdView(frame: .zero)
    nativeAdView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

    // Icon
    let iconView = UIImageView()
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    iconView.clipsToBounds = true
    iconView.layer.cornerRadius = 8
    iconView.image = nativeAd.icon?.image
    nativeAdView.addSubview(iconView)
    nativeAdView.iconView = iconView

    // Headline
    let headlineLabel = UILabel()
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false
    headlineLabel.text = nativeAd.headline
    headlineLabel.textColor = UIColor(red: 0.94, green: 0.96, blue: 0.97, alpha: 1.0)
    headlineLabel.font = UIFont.boldSystemFont(ofSize: 14)
    headlineLabel.numberOfLines = 1
    nativeAdView.addSubview(headlineLabel)
    nativeAdView.headlineView = headlineLabel

    // Body
    let bodyLabel = UILabel()
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    bodyLabel.text = nativeAd.body
    bodyLabel.textColor = UIColor(red: 0.42, green: 0.48, blue: 0.54, alpha: 1.0)
    bodyLabel.font = UIFont.systemFont(ofSize: 12)
    bodyLabel.numberOfLines = 2
    nativeAdView.addSubview(bodyLabel)
    nativeAdView.bodyView = bodyLabel

    // CTA Button
    let ctaButton = UIButton(type: .system)
    ctaButton.translatesAutoresizingMaskIntoConstraints = false
    ctaButton.setTitle(nativeAd.callToAction, for: .normal)
    ctaButton.setTitleColor(UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0), for: .normal)
    ctaButton.backgroundColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    ctaButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
    ctaButton.layer.cornerRadius = 6
    ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    ctaButton.isUserInteractionEnabled = false
    nativeAdView.addSubview(ctaButton)
    nativeAdView.callToActionView = ctaButton

    // Ad label
    let adLabel = UILabel()
    adLabel.translatesAutoresizingMaskIntoConstraints = false
    adLabel.text = "Ad"
    adLabel.textColor = UIColor(red: 0.42, green: 0.48, blue: 0.54, alpha: 1.0)
    adLabel.font = UIFont.systemFont(ofSize: 10)
    adLabel.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0)
    adLabel.textAlignment = .center
    nativeAdView.addSubview(adLabel)

    // Layout
    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
      iconView.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 48),
      iconView.heightAnchor.constraint(equalToConstant: 48),

      headlineLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 16),
      headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
      headlineLabel.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -12),

      bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
      bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

      ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
      ctaButton.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor),

      adLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 4),
      adLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      adLabel.widthAnchor.constraint(equalToConstant: 20),
    ])

    nativeAdView.nativeAd = nativeAd
    return nativeAdView
  }
}
