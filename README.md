# VINCE ARNEL S. TUPAS  
## INF 233 MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 2: discussion

This activity uses the DummyJSON products endpoint to display product data in the Flutter application. The application separates its data, API, and presentation responsibilities into three parts: the model, service, and screens.

### Model

The `Product` model represents one product returned by the API. Its `Product.fromJson` factory converts raw JSON into a type-safe Dart object, including nested dimensions, reviews, and metadata. This gives screens predictable properties such as `title`, `price`, `thumbnail`, and `reviews` instead of requiring them to read JSON maps directly.

### Service

`ProductService` is responsible for communicating with the API. Its `getAllProducts()` method sends an HTTP GET request to the products endpoint, decodes the response, extracts the `products` list, and converts every item into a `Product` object. It also throws an exception when the request is unsuccessful. Keeping networking code in the service prevents HTTP and JSON logic from being repeated in the user interface.

### Screens and rendering flow

`ProductScreen` starts the request in `initState()` by storing `ProductService().getAllProducts()` in a `Future<List<Product>>`. A `FutureBuilder` watches that future and renders a loading indicator while the request is pending, an error message when it fails, or a grid of product cards when data arrives. Each card displays model values such as the image, title, and price. When a user taps a card, the selected `Product` object is passed to `ProductDetailScreen`, which renders its complete details, images, specifications, and reviews.

### Design pattern

This activity uses the Service Layer pattern, also commonly described as a Repository-style separation. The UI screens do not call `http` or parse JSON; they request ready-to-use `Product` objects from `ProductService`. The model owns data conversion, the service owns API access, and the screens own presentation and user interaction. This separation improves readability, testing, and maintenance because API changes are localized to the service and model rather than every screen.

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes.
