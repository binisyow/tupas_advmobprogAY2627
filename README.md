# VINCE ARNEL S. TUPAS  
## INF 233 MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 2: discussion

## Lab Activity 3: discussion

The cart feature follows the same service-layer design pattern. `CartService` owns HTTP requests, while `Cart` and `CartProduct` convert Cart API JSON into typed Dart objects. `CartScreen` renders those objects without calling HTTP directly. It uses `GET /carts/user/5` to render the cart for one user. Tapping a cart item uses `ProductService.getProductById` and opens the same reusable `ProductDetailScreen` as the product list.

`CartService.getCartById(cartId)` implements Cart get-by-id with `GET /carts/{id}` for an individual cart. The Add to cart action sends the selected product ID and quantity to `POST /carts/add`. DummyJSON simulates this write and returns a cart response but does not persist it. Chat is now a FloatingActionButton and is hidden on the cart screen.

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes
