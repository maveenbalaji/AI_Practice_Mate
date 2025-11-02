# AI PracticeLab

An interactive, AI-driven learning assistant that helps learners master programming through intelligent question generation, real-time evaluation, and conversational engagement.

## Features

- **AI Question Generation**: Dynamically generates coding problems based on selected topics and difficulty levels
- **Conversational Interface**: Chat-like environment for interacting with the AI tutor
- **AI Code Evaluation**: Validates user solutions and provides detailed feedback
- **Progressive Learning**: Intelligent difficulty progression that adapts to user performance
- **Topic Progression**: Moves through programming concepts in a logical sequence
- **Gamification**: Motivational feedback and encouragement messages

## Getting Started

### Prerequisites

- Flutter SDK (version 3.9.2 or higher)
- Dart SDK
- Windows, macOS, Linux, iOS, or Android development environment

### Installation

1. Clone the repository:
   ```
   bash
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   bash
   cd learn_ai
   ```

3. Install dependencies:
   ```
   bash
   flutter pub get
   ```

4. Create a `.env` file in the root directory with your API key:
   ```
   bash
   OPENAI_API_KEY=your_api_key_here
   ```

### Running the Application

To run the application on Windows:
```
bash
flutter run -d windows
```
To run on other platforms, replace `windows` with your target platform (`android`, `ios`, `macos`, `linux`).

## Project Structure

```
text
lib/
├── main.dart                 # Entry point of the application
├── models/                   # Data models
│   ├── question.dart         # Question model
│   ├── evaluation_result.dart # Code evaluation result model
│   ├── feedback_message.dart # Feedback message model
│   └── challenge_response.dart # Challenge response model
├── services/                 # Business logic and API services
│   └── ai_service.dart       # AI service for API communication
└── screens/                  # UI screens
    └── chat_screen.dart      # Main chat interface
```

## Progressive Question Flow

The AI PracticeLab implements an intelligent progression system:

1. **Adaptive Difficulty**: Increases challenge difficulty as users succeed
2. **Topic Progression**: Moves through programming concepts in a logical sequence:
   - Loops and Control Statements
   - Functions
   - Lists and Arrays
   - Strings
   - Dictionaries
   - Classes and Objects
   - File Handling
   - Exception Handling
3. **Performance-Based Adjustment**: Reduces difficulty when users struggle
4. **Concept Mastery**: Ensures users master a concept before moving to the next

<img width="1919" height="1006" alt="Screenshot 2025-10-19 190102" src="https://github.com/user-attachments/assets/050fc853-3d92-434c-b523-324104846abb" />


## API Integration

The application uses the Groq API for AI capabilities. The API key should be stored in a `.env` file and accessed through environment variables.

## Dependencies

| Package | Purpose |
|---------|---------|
| flutter | UI toolkit |
| http | For making HTTP requests |
| flutter_dotenv | For loading environment variables |
| shared_preferences | For local data storage (future implementation) |



## Future Enhancements

- Progress tracking and user profiles
- Badge and reward system
- Multiple programming language support
- Voice-based learning
- Real-time leaderboard
- Adaptive difficulty based on user performance
- Code execution sandbox for real code evaluation

## Author

Maveen Balaji CHINTAKRINDI

## Version

1.0.0
```

