

import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    @State private var availableWidth: CGFloat = 0
    @State private var isLoaded = false

    var body: some View {
        ZStack {
            if availableWidth > 0 {
                let adSize = largeAnchoredAdaptiveBanner(width: availableWidth)
                BannerViewContainer(adSize: adSize, adUnitID: AdConfig.bannerUnitID) { loaded in
                    withAnimation(.easeOut(duration: 0.3)) {
                        isLoaded = loaded
                    }
                }
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(height: isLoaded ? adSize.size.height : 0, alignment: .top)
                .clipped()
                .opacity(isLoaded ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            if abs(newWidth - availableWidth) > 1 {
                availableWidth = newWidth
            }
        }
        .accessibilityElement(children: .contain)
    }
}


private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String
    var onLoadChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadChange: onLoadChange)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        context.coordinator.onLoadChange = onLoadChange
        if uiView.adSize.size != adSize.size {
            uiView.adSize = adSize
            uiView.load(Request())
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var onLoadChange: (Bool) -> Void

        init(onLoadChange: @escaping (Bool) -> Void) {
            self.onLoadChange = onLoadChange
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onLoadChange(true)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
            onLoadChange(false)
        }
    }
}
