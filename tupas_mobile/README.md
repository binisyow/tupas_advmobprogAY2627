# Tupas, Vince Arnel S.

## INF 233 MWA

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advanced topics, including mobile-to-web transactions.

## Lab Activity Instance

## Lab Activity 2: Discussion

`ProductService` calls the API, `Product` converts the JSON response into a Dart object, and the screen asks the service for data and displays it. The screen does not call HTTP directly. This follows the Repository/Service pattern because the service layer is placed between the UI and the API. If the product endpoint changes, only `ProductService` needs to be updated.

## Lab Activity 3: Discussion

`Cart` and `CartProduct` convert cart JSON into Dart objects, while `CartService` handles the API requests. `CartScreen` gets one user's cart using `GET /carts/user/5` and displays it through `CartProvider`. When a cart item is tapped, the app uses `ProductService.getProductById()` and opens the same `ProductDetailScreen`, so there is no duplicate detail screen. The Add to Cart button sends the product ID, quantity, and user ID to `POST /carts/add`; since DummyJSON only simulates this request, `CartProvider` updates the cart locally so the screen refreshes immediately. `getCartById()` uses `GET /carts/{id}` for one specific cart. Lastly, Chat was changed from a bottom-navigation item into a FloatingActionButton, and it is hidden on the Cart screen.
