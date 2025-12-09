# Wellby iOS

A wellbeing companion app designed to support adolescent health through lifestyle resources, mood tracking, HRV biofeedback, and optional health coaching. Built as part of a research study at **RCSI (Royal College of Surgeons in Ireland)**.

Looking for Android? See **[wellby-android](https://github.com/j-laiti/Wellby-Android)**.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
  - [Clone the Repository](#1-clone-the-repository)
  - [Set Up Firebase](#2-set-up-firebase)
  - [Configure Keys](#3-configure-keys)
  - [Run the App](#4-run-the-app)
- [Firebase Structure](#firebase-structure)
  - [Study Codes](#study-codes)
  - [Resources](#resources)
  - [Users](#users)
- [Features in Detail](#features-in-detail)
- [Important Notes for Researchers](#important-notes-for-researchers)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview

Wellby was developed to provide high school students with tools and resources for managing their wellbeing. The app includes:

- Daily mood check-ins with tracking over time
- Curated wellbeing resources (videos and articles) organized by topic
- HRV (Heart Rate Variability) biofeedback via a custom wearable device
- Breath pacing exercises
- An AI chatbot for wellbeing-related questions
- Optional access to human health coaches

The app was built to support research studies, so it includes features like study codes for participant onboarding and engagement tracking.

---

## Features

- **Mood Tracking** – Quick daily check-ins with reflection options
- **Resource Library** – Curated videos and articles on stress, sleep, digital wellbeing, and time management
- **HRV Biofeedback** – Connect to a BLE wearable for heart rate variability monitoring
- **Breath Pacer** – Guided breathing exercises (box breathing and resonant breathing)
- **AI Chat** – Supportive responses to wellbeing questions
- **Health Coaching** – Optional opt-in to message a human health coach
- **Customization** – Personalize app colors and display preferences
- **Daily Quotes** – Rotating motivational quotes on the home screen

---

## Screenshots

Coming soon.

---

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Firebase account
- OpenAI API key (for AI chat feature)
- YouTube Data API key (for video resources)

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/j-laiti/wellby-ios.git
cd wellby-ios
```

### 2. Set Up Firebase

1. Create a new project in the [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your Firebase project
3. Download the `GoogleService-Info.plist` file
4. Add it to the root of your Xcode project (make sure "Copy items if needed" is checked)
5. Enable the following Firebase services:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Cloud Storage** (for resource images)
   - **Cloud Messaging** (for push notifications)

### 3. Configure Keys

Copy the template file to create your keys file:

```bash
cp BeatBalance/PrivateKeysTemplate.swift BeatBalance/PrivateKeys.swift
```

Open `PrivateKeys.swift` and add your API keys:

```swift
enum Secrets {
    static let openAIAPIKey = "your-openai-api-key"
    static let youTubeAPIKey = "your-youtube-api-key"
    static let firebasePPGFunctionURL = "your-firebase-function-url"
    static let firebaseFlaggedMessageFunctionURL = "your-firebase-function-url"
    static let openAIAssistantID = "your-openai-assistant-id"
}
```

> **Note:** `PrivateKeys.swift` is gitignored and will not be committed to the repository.

### 4. Run the App

1. Open `BeatBalance.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (⌘R)

---

## Firebase Structure

### Study Codes

The app uses study codes to manage participant onboarding. To set this up:

1. Create a collection called `studyCodes` in Firestore
2. Add a document called `testCodes` (or whatever suits your study)
3. Add fields for each cohort/role. The field name represents the cohort, and the value is an array of valid codes

Each code follows the format: `[4 digits][letter]`

The letter suffix indicates the participant's role or school:

- `c` - Coach (non-student)
- `g` - Student at School G
- `w` - Student at School W
- `r` - Student at School R
- `t` - Student at School T

You can modify the letter mappings in `AuthManager.swift` under `checkStudyCode()` to suit your study design.

**Example Firestore structure:**

```
studyCodes/
  testCodes/
    gorey: ["1234g", "5678g", ...]
    coach: ["1234c", "5678c", ...]
```

### Resources

Resources are organised by topic in Firestore and Cloud Storage:

**Firestore structure:**

```
resources/
  sleep/
    images/ (collection)
      [document]/
        imageData: "path/to/image/in/storage"
        url: "https://external-article-link.com"
        date: [timestamp]
    playlistId: "YouTube-playlist-ID"
  stress/
    ...
  digital-wellbeing/
    ...
  time-management/
    ...
  other/
    ...
```

**Cloud Storage structure:**

```
resources/
  sleep/
    images/
      image1.png
      image2.png
  stress/
    images/
      ...
```

The app fetches YouTube videos using the playlist ID and displays images stored in Cloud Storage alongside their linked article URLs.

### Users

User data is stored in the `users` collection with the following structure:

```
users/
  [userId]/
    firstName: "..."
    surname: "..."
    username: "..."
    email: "..."
    student: true/false
    school: "..."
    assignedCoach: 1/2/3 (for students) or 0 (for coaches)
    isCoachingOptedIn: true/false
    status: "..." (for coaches)
    checkIns/ (subcollection)
      [checkInId]/
        mood: "😊"
        alertness: 4
        calmness: 3
        moodReason: "..."
        nextAction: "..."
        date: [timestamp]
    HRV-inApp/ (subcollection)
      [sessionId]/
        sdnn: "..."
        rmssd: "..."
        HR_mean: "..."
        sqi: "..."
        timestamp: [timestamp]
    engagement/ (subcollection)
      [documentId]/
        screen_viewed: "..." or feature_clicked: "..."
        timestamp: [timestamp]
```

---

## Features in Detail

### Mood Check-ins

Users can log their mood using an emoji, plus rate their alertness and calmness on a 1-5 scale. The extended check-in allows users to reflect on what's affecting their mood and plan their next action.

Check-in data is stored in Firestore and visualised in a tracker view showing trends over time.

### HRV Biofeedback

The app connects to a custom BLE wearable device for PPG (photoplethysmography) based heart rate variability monitoring.

**Key components:**

- `BluetoothManager.swift` - Handles BLE connection and data streaming
- `HRVDataManager.swift` - Manages HRV data storage and processing
- Raw PPG data is uploaded to Firebase and processed via a Cloud Function

> **Tip:** Recording quality is significantly better when the sensor is placed on the finger rather than the wrist.

**The HRV metrics displayed are:**

- **Calming Response (RMSSD)** - Indicates parasympathetic nervous system activity
- **Return to Balance (SDNN)** - Indicates overall autonomic nervous system balance
- **Average Heart Rate**
- **Signal Quality**

### AI Chat (Wellby AI)

The AI chat feature uses the OpenAI Assistants API to provide supportive responses to wellbeing-related questions. Users can ask about stress management, sleep, digital wellbeing, healthy eating, relationships, and time management.

**Important safeguards:**

- Messages are moderated using OpenAI's Moderation API before being processed
- Messages flagged for self-harm or violence trigger a supportive response and are logged to Firestore
- Flagged messages can optionally trigger a notification via Firebase Cloud Functions

> ⚠️ **Researcher Note:** The AI flagging feature is a beta implementation that was not tested with real participants. If you're deploying this in a research context, please ensure proper safeguards, clinical oversight, and ethical approval are in place. AI should not be used as a substitute for professional mental health support.

### Health Coaching

Students can opt-in to access a human health coach through the app. The coaching feature includes:

- Real-time messaging between students and coaches
- Coach status updates (so students know when coaches are available)
- Ability to report objectionable content or block users
- Coaches can message all assigned students at once

Coach assignment is automatic based on the first letter of the student's name (to distribute load), but this logic can be modified in `AuthManager.swift`.

### Resources

Curated resources are organised into five topics:

- Stress Management
- Sleep
- Digital Wellbeing
- Time Management
- Other

Each topic displays YouTube videos (fetched via the YouTube Data API) and images/articles (stored in Firebase). Users can save resources to their personal library for later reference.

---

## Important Notes for Researchers

If you're adapting Wellby for your own research study:

- **Study Codes** - Modify the code suffix meanings in `AuthManager.swift` to match your cohorts
- **Ethics** - Ensure you have appropriate ethical approval for collecting wellbeing data from minors
- **AI Safety** - The AI chat feature requires careful consideration. The current flagging system is basic and should be enhanced with proper clinical oversight
- **Data Storage** - All data is stored in Firebase. Review Firebase security rules and ensure compliance with your institution's data protection requirements
- **Engagement Tracking** - The app logs screen views and feature clicks for research purposes. Make sure participants are informed about this in your consent process
- **Wearable Device** - The HRV feature requires a specific BLE wearable. Contact us if you need details on the hardware setup. This will soon be published open-source as well.

---

## Contributing

Contributions are welcome! If you'd like to improve Wellby:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

Please make sure to:

- Never commit API keys or secrets
- Test your changes on a real device if possible
- Update documentation as needed

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The app icon was created by Andrei Marius (https://andreimarius.com/icons) who gave permission for this to be used as part of this app.

---

## Contact

This project was developed as part of research at RCSI. For questions about the app or research collaboration:

**Email:** justinlaiti22@rcsi.com

**Wellby: Your Well-being Buddy 🌱**
