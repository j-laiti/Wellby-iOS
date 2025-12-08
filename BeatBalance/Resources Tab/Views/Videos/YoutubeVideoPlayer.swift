//
//  YoutubeVideoPlayer.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/3/23.
//

import SwiftUI
import WebKit

struct YoutubeVideoPlayer: UIViewRepresentable {
    var video: Video
    
    func makeUIView(context: Context) -> some UIView {
        //create web view
        let view = WKWebView()
        
        //create url for video
        let embedUrlString = Constants.YT_embeded_url + video.videoId
        
        //load video
        let url = URL(string: embedUrlString)
        let request = URLRequest(url: url!)
        view.load(request)
        
        //return webview
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

#Preview {
    YoutubeVideoPlayer(video: Video())
}
