# Implementation Plan

This document outlines the plan to implement the requested features: refactoring the education feature and enhancing the SACCOs feature.

## 1. Education Feature Refactoring

The goal is to refactor the education feature to have a more organized and modular codebase, and to allow users to view the details of each course.

### 1.1. Create a `Course` Model

-   Create a `course.dart` file in the `lib/models` directory.
-   Define a `Course` class with the following properties:
    -   `title` (String)
    -   `subtitle` (String)
    -   `duration` (String)
    -   `price` (String)
    -   `image` (String)
    -   `color` (Color)
    -   `description` (String)
    -   `modules` (List<String>)

### 1.2. Refactor `LiteracyService`

-   Update the `LiteracyService` in `lib/services/literacy_service.dart`.
-   Instead of returning a `List<Map<String, dynamic>>`, the `popularCourses` getter will return a `List<Course>`.

### 1.3. Create a `CourseDetailScreen`

-   Create a `course_detail_screen.dart` file in the `lib/screens` directory.
-   This screen will display the details of a selected course, including its description and modules.
-   When a user taps on a course card in the `LiteracyScoreScreen`, they will be navigated to this screen.

### 1.4. Update `LiteracyScoreScreen`

-   Update `literacy_score_screen.dart` to use the `Course` model.
-   Add navigation to the `CourseDetailScreen` when a course is tapped.

## 2. SACCOs Feature Enhancement

The goal is to create a more dynamic and interactive experience for the SACCOs feature, similar to a forex exchange system.

### 2.1. Link Home Page Card to Profile

-   **Modify the existing card on `home_dashboard.dart`**: The card at the top of the home screen will be updated to display the current user's profile picture and name.
-   **Fetch user data**: The data will be fetched from a `ProfileService` (to be created).

### 2.2. "Forex-like" SACCOs Page

-   **Enhance `sacco_detail_screen.dart`**:
    -   **Real-time Price Updates**: The price of the SACCO shares will be updated in real-time. We will simulate this with a `Timer` for now.
    -   **Transaction History**: Display a list of recent transactions for the SACCO.
    -   **Buy/Sell Buttons**: Add "Buy" and "Sell" buttons to allow users to trade SACCO shares.
    -   **Order Book**: Display a simplified order book with a list of buy and sell orders.

### 2.3. Create a `Transaction` Model

-   Update the `transaction.dart` file in `lib/models` to include more details, such as:
    -   `type` (e.g., "buy", "sell")
    -   `saccoName` (String)
    -   `numberOfShares` (int)
    -   `pricePerShare` (double)
    -   `timestamp` (DateTime)
