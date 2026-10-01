FoodSwap

Make a better food choice.

FoodSwap is a Flutter mobile application that helps users make better decisions when choosing packaged foods. Instead of simply displaying nutritional information, FoodSwap converts that information into an easy-to-understand FoodSwap Score and recommends better alternatives.

The application uses the Open Food Facts API to retrieve product information and allows users to compare products based on nutritional values and Nutri-Score.

Features
🔍 Food Search
Search for packaged food products using the Open Food Facts database.
📊 FoodSwap Score
Converts nutritional information into a simple score out of 100 to make product comparison easier.
🥗 Better Swaps
Find alternative products with better nutritional characteristics.
⚖️ Product Comparison
Compare the current product with alternatives using:
FoodSwap Score
Protein
Sugar
Nutri-Score
Other nutritional information
🏷️ Nutri-Score
Displays the product's Nutri-Score from A to E.
📋 Product Details
View detailed nutritional information including:
Calories
Protein
Carbohydrates
Sugar
Fat
Saturated fat
Salt
🔎 Filtering & Sorting
FoodSwap Score
Product category
Nutri-Score
⚡ Loading & Skeleton States
Provides visual feedback while product data is being loaded.
❌ Error Handling
Handles API failures, unavailable results and other network-related errors gracefully.
💾 Caching / Offline Support
Previously retrieved product information can be accessed through local caching when network connectivity is unavailable.
🌙 Dark & Light Themes
The application supports both dark and light themes.
📱 Responsive UI
The interface adapts to different screen sizes and orientations.
ℹ️ In-App Information
Explains the FoodSwap Score and Nutri-Score system to users.
How FoodSwap Works

The basic flow of the application is:

User searches for a food
        ↓
Open Food Facts API
        ↓
Product information retrieved
        ↓
Nutrition data processed
        ↓
FoodSwap Score calculated
        ↓
Products displayed
        ↓
User selects a product
        ↓
Better alternatives identified
        ↓
Products compared
FoodSwap Score

The FoodSwap Score is a simplified score designed to help users compare packaged foods more easily.

Instead of requiring users to interpret multiple nutritional values independently, FoodSwap combines relevant nutritional information into a score between:

0 ─────────────────────── 100
Poor                    Better

A higher score represents a relatively better nutritional profile according to the scoring criteria implemented in the application.

The score is intended as a comparison tool, rather than a medical or dietary recommendation.

Nutri-Score

FoodSwap also displays the Nutri-Score provided by the Open Food Facts data.

The Nutri-Score scale is:

A → Better nutritional profile
B
C
D
E → Less favorable nutritional profile

FoodSwap uses this information alongside its own scoring system when presenting product comparisons.

Architecture

FoodSwap follows a layered Flutter architecture:

┌─────────────────────────────┐
│          UI / Screens       │
│                             │
│ Home • Product Details      │
│ Better Swaps                │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│          Providers          │
│                             │
│ State Management            │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│        Repositories         │
│                             │
│ Data access & coordination  │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│          Services           │
│                             │
│ API • Caching • Filtering   │
│ Recommendation • Sorting    │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│     Open Food Facts API     │
└─────────────────────────────┘
Main project structure
lib/
├── models/
├── providers/
├── repositories/
│   └── food_repository.dart
├── screens/
│   ├── home_screen.dart
│   ├── better_swaps_screen.dart
│   └── product_details.dart
├── services/
│   ├── openfood_service.dart
│   ├── product_cache.dart
│   ├── product_filter_sort_service.dart
│   └── recommendation_service.dart
└── main.dart
Tech Stack
Technology	Purpose
Flutter	Cross-platform application development
Dart	Application programming language
Open Food Facts API	Product and nutritional data
Riverpod	State management
HTTP	API communication
Local caching	Offline/reduced-network dependency
Flutter testing	Automated application testing
API

FoodSwap uses the Open Food Facts API to retrieve publicly available product information such as:

Product name
Brand
Product image
Categories
Nutritional values
Nutri-Score
Product identifier

The application processes the retrieved data before presenting it to the user.

Error Handling

FoodSwap provides user-facing states for situations such as:

Network unavailable
API errors
Product search failure
Similar-product search failure
Empty search results
Unavailable product information

Previously cached information can also be used where applicable.

Testing

The project can be analyzed and tested using Flutter's standard tools.

Static analysis
flutter analyze
Automated tests
flutter test
Run the application
flutter run
Installation
Prerequisites

Install:

Flutter SDK
Dart SDK
Android Studio / Android SDK
A connected Android device or emulator
Setup

Clone the repository:

git clone https://github.com/YOUR_USERNAME/food-swap-flutter.git

Navigate to the project:

cd food-swap-flutter

Install dependencies:

flutter pub get

Run the application:

flutter run
Building the APK

To generate a release APK:

flutter build apk --release

The generated APK can be found at:

build/app/outputs/flutter-apk/app-release.apk
Project Goals

FoodSwap was designed around a simple idea:

Turn nutritional information into an actionable food decision.

Rather than forcing users to interpret complicated nutrition tables, the application presents product information through scores, comparisons and alternative recommendations.

Future Improvements

Potential future improvements include:

Barcode scanning
Personalized dietary preferences
Vegetarian / vegan filtering
Allergen-based filtering
More advanced recommendation algorithms
Expanded offline capabilities
User accounts and personalized food history
More detailed nutritional insights
License

This project is developed for educational and demonstration purposes.
