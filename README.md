# Vince Arnel S. Tupas

## INF 233 MWA

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 1: discussion

setState manages local, temporary state within a single widget by rebuilding its entire UI, whereas Provider manages shared, app-wide state by separating business logic from the UI, allowing any widget across the tree to access data directly and rebuilding only the specific components that depend on it.

## Lab Activity 2: discussion

ProductService calls the API, Product converts the raw JSON into a Dart object, and the screen asks the service for that data and displays it — it never calls http directly. This is the Repository/Service pattern: a service layer sits between the UI and the API so only ProductService needs to change if the API changes.

## Lab Activity 3: discussion

Cart/CartProduct convert carts JSON into Dart objects, CartService is the only class that calls http for cart data, and CartScreen just asks it for data — same Repository/Service pattern as Lab 2, applied to a second endpoint. Since CartProduct only carries a summary (no description, images, reviews), tapping a cart item doesn't open its own cart-detail screen: CartScreen calls ProductService.getProductById(item.id) for the full Product, then pushes the existing DetailScreen — the updated pattern is one screen reused across two entry points instead of duplicated per feature. getProductById (GET /products/{id}) is this activity's "get by id" — the Cart API has its own GET /carts/{id} for a single cart, but since there's no login yet, CartService.getCartsByUser(userId) uses GET /carts/user/{userId} instead, scoping to a fixed demo user rather than a specific cart id.

## Lab Activity 4 : discussion

User is the model, UserService is the only class that talks to the API/SharedPreferences for auth data, and ProfileScreen just asks UserService().getUser() for the signed-in user and displays it — same Repository/Service pattern as Labs 2-3, now applied to /auth/login. The updated pattern adds a persistence layer: UserService saves the login response to SharedPreferences and later reads it back, so the service acts as a local cache in front of the API instead of hitting it on every screen. This saved user id is also what scopes the cart: CartScreen no longer calls CartService.getCartsByUser with a hardcoded demo id like in Lab 3 — it first reads UserService().getUser().id, then passes that real id into getCartsByUser, so the cart shown is always the signed-in user's own cart.

## Lab Activity 5: DummyJSON and Firebase Auth discussion

The app uses one sign-in screen where emails are handled by Firebase and usernames are handled by DummyJSON. DummyJSON supports demo login but does not provide registration or password management, so these features are handled by Firebase. Firebase manages account creation, sessions, token refresh, password changes, recovery, and account deletion. UserService keeps authentication, sessions, provider-specific operations, and profile data under one system so the UI works with both providers. The full profile remains locally cached; the public name and email are additionally synced to Firestore for the chat directory (see Lab Activity 6).

## Lab Activity 6: Firebase Firestore chat discussion

Cloud Firestore stores each Firebase account's public chat profile in the top-level `users` collection, using that account's Firebase Auth UID as the document ID. Each profile contains its UID, display name, and email; a signed-in user's own profile is filtered out of the live, searchable chat directory. When two different users start a conversation, the app creates one deterministic document in `chats` with both UIDs in its `participants` array. Messages are stored in that chat's `messages` subcollection, with sender and receiver UIDs, text, creation time, and delivery/read receipt arrays. This keeps conversations separate while allowing both participants to receive real-time message updates. DummyJSON-only accounts do not have Firebase UIDs and therefore cannot use the Firestore chat feature.

A user cannot start a conversation with themselves: the app rejects matching UIDs before creating a chat, and Firestore rules reject a message whose sender and receiver are the same. The directory is created as Firebase accounts sign up or sign in; older accounts are added the next time they sign in after this change. To initialize Firestore, create a database in the Firebase console (US region, Production mode), then deploy `tupas_mobile/firestore.rules` from the `tupas_mobile` folder with the Firebase CLI (`firebase deploy --only firestore:rules --project advmobprog-firebase-eb9ad`). Do not use globally open `read, write: if true` rules for a chat app: they expose user profiles and private messages to unauthenticated clients.
