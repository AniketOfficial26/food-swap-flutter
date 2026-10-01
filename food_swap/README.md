# FoodSwap

FoodSwap is a Flutter application that helps users make better decisions when choosing packaged foods.

Instead of simply displaying nutritional information, FoodSwap converts product nutrition data into an easy-to-understand FoodSwap Score and helps users discover better alternatives.

The application uses the Open Food Facts API for product and nutritional information.

---

## Features

- Food search using the Open Food Facts API
- FoodSwap Score out of 100
- Nutri-Score display (A to E)
- Product details and nutritional information
- Better food recommendations
- Product comparison
- Protein, sugar and other nutrition comparisons
- Product filtering by category
- Sorting by FoodSwap Score
- Filtering by Nutri-Score
- Loading and skeleton states
- API and network error handling
- Product caching for offline/reduced-network usage
- Light and dark themes
- Responsive layout for different screen sizes and orientations
- In-app information explaining FoodSwap Score and Nutri-Score

---

## How It Works

The application follows this general flow:

1. The user searches for a packaged food.
2. FoodSwap sends the search request to the Open Food Facts API.
3. Product information is retrieved.
4. The application processes the nutritional information.
5. A FoodSwap Score is calculated.
6. Matching products are displayed.
7. The user can open a product to view detailed nutritional information.
8. FoodSwap can find alternative products with better nutritional characteristics.
9. The alternatives are presented with a comparison of important metrics.

---

## FoodSwap Score

FoodSwap Score is a simplified scoring system designed to make food comparison easier.

The score ranges from 0 to 100.

- A higher score represents a relatively better nutritional profile.
- A lower score represents a relatively less favorable nutritional profile.

The score is intended as a comparison and decision-support tool. It is not a medical or dietary recommendation.

---

## Nutri-Score

FoodSwap also displays the Nutri-Score provided through the Open Food Facts product data.

The Nutri-Score uses five categories:

- A - Better nutritional profile
- B
- C
- D
- E - Less favorable nutritional profile

FoodSwap uses Nutri-Score together with its own FoodSwap Score when comparing products.

---

## Better Swaps

The Better Swaps feature helps users find alternative products that may have a better nutritional profile than the selected product.

Alternatives are compared using metrics such as:

- FoodSwap Score
- Protein
- Sugar
- Nutri-Score

The comparison screen also explains why an alternative is considered better.

---

## Product Details

The product details screen provides information such as:

- Product name
- Brand
- Product image
- FoodSwap Score
- Nutri-Score
- Calories
- Protein
- Carbohydrates
- Sugar
- Fat
- Saturated fat
- Salt

---

## Filtering and Sorting

Search results can be organized using:

- FoodSwap Score
- Product category
- Nutri-Score

This allows users to narrow down products according to their preferences.

---

## Caching and Offline Support

FoodSwap uses local product caching to reduce unnecessary API requests and provide access to previously retrieved product information.

When network connectivity is unavailable, cached information can be used where applicable.

This also helps improve the responsiveness of the application for previously accessed products.

---

## Error Handling

The application provides user-friendly states for common problems such as:

- Network connectivity problems
- API errors
- Product search failures
- Similar-product search failures
- Empty search results
- Missing product information

Loading and skeleton states are also provided while data is being retrieved.

---

## Dark and Light Themes

FoodSwap supports both dark and light themes.

The interface has been designed to maintain consistent colors, typography and readability across the application's main screens.

---

## Responsive Design

The application is designed to work across different screen sizes and orientations.

The UI adapts to:

- Portrait orientation
- Landscape orientation
- Different device screen sizes

---

## Architecture

FoodSwap follows a layered Flutter architecture.

### UI Layer

Responsible for displaying the application interface and handling user interaction.

Main screens include:

- Home Screen
- Product Details
- Better Swaps

### Provider Layer

Responsible for application state management and connecting the UI with the underlying data layers.

### Repository Layer

Responsible for coordinating data access between the application and services.

### Service Layer

Contains the main application services, including:

- Open Food Facts API communication
- Product caching
- Product filtering and sorting
- Food recommendation logic

### Data Flow

The overall data flow is:

UI -> Providers -> Repositories -> Services -> Open Food Facts API

---

## Project Structure

```text
lib/
├── models/
│
├── providers/
│
├── repositories/
│   └── food_repository.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── better_swaps_screen.dart
│   └── product_details.dart
│
├── services/
│   ├── openfood_service.dart
│   ├── product_cache.dart
│   ├── product_filter_sort_service.dart
│   └── recommendation_service.dart
│
└── main.dart
```
### Technologies Used
Flutter
Dart
Riverpod
Open Food Facts API
HTTP
Local caching
Flutter testing
API

FoodSwap uses the Open Food Facts API to retrieve publicly available product information.

## The application uses data such as:

Product name
Brand
Product image
Categories
Product identifier
Nutritional values
Nutri-Score

The retrieved data is processed by the application before being presented to the user.

Getting Started
Prerequisites

### Make sure the following are installed:

Flutter SDK
Dart SDK
Android Studio / Android SDK
Android emulator or physical Android device
Clone the Repository
git clone https://github.com/YOUR_USERNAME/food-swap-flutter.git
Navigate to the Project
cd food-swap-flutter
Install Dependencies
flutter pub get
Run the Application
flutter run
Running Tests

Run static analysis:

flutter analyze

Run automated tests:

flutter test
Building the APK

To create a release APK:

flutter build apk --release

The generated APK will be available at:

build/app/outputs/flutter-apk/app-release.apk
Future Improvements

### Possible future improvements include:

Barcode scanning
Personalized dietary preferences
Allergen-based filtering
Vegetarian and vegan filtering
More advanced food recommendation algorithms
Expanded offline functionality
User accounts and personalized food history
Additional nutritional insights
Project Purpose

### FoodSwap was developed around a simple goal:

Make nutritional information easier to understand and turn it into a practical food choice.

Instead of requiring users to interpret multiple nutritional values independently, FoodSwap presents product information through scores, comparisons and alternative recommendations.
