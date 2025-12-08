//
//  Constants.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 11/30/23.
//

import Foundation

struct Constants {
    static let youtubeAPIKey = PrivateKeys.youTubeAPIKey
    static let listURL = "https://www.googleapis.com/youtube/v3/playlistItems"
    static let YT_embeded_url = "https://www.youtube.com/embed/"
    
    
    enum Topics: String, CaseIterable {
        
        case stress = "Stress Management"
        case sleep = "Sleep"
        case digital = "Digital Wellbeing"
        case time = "Time Management"
        case other = "Other"
        
        func playlistId() -> String {
            switch self {
            case .sleep:
                return "PLcTlyhcb55Dfnc6HqFjiKLj-yHQC3xw-R"
            case .stress:
                return "PLcTlyhcb55DfQJIGP_RM72W8k5D9qk5_T"
            case .digital:
                return "PLcTlyhcb55DeK5gUMhlR0BWJ31m195cWA"
            case .time:
                return "PLcTlyhcb55DdI716jNcXaHReft9V8XUhR"
            case .other:
                return "PLcTlyhcb55DcXe4YwoGPht0z8xQalAfk-"
            }
        }
        
        func imagesPath() -> String {
            switch self {
            case .sleep:
                return "resources/sleep/images"
            case .stress:
                return "resources/stress/images"
            case .digital:
                return "resources/digital-wellbeing/images"
            case .time:
                return "resources/time-management/images"
            case .other:
                return "resources/other/images"
            }
        }
        
        func systemImage() -> String {
            switch self {
                case .sleep:
                    return "moon.zzz.fill"
                case .stress:
                    return "figure.mind.and.body"
                case .digital:
                    return "macbook.and.iphone"
                case .time:
                    return "calendar"
                case .other:
                    return "ellipsis.circle"
            }
        }
        
    }
}
