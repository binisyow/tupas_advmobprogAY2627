import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import '../providers/cart_provider.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const int _userId = 5;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCartByUserId(_userId);
    });
  }

  Future<void> _openProduct(int productId) async {
    try {
      final Product product = await ProductService().getProductById(productId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open product: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    if (cartProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cartProvider.error != null) {
      return Center(child: Text('Error: ${cartProvider.error}'));
    }
    final cart = cartProvider.cart;
    if (cart == null) {
      return const Center(child: Text('This user has no cart.'));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: cart.products.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) => _cartItem(cart.products[index]),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Total (${cart.totalQuantity} items)',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              CustomText(
                text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartItem(CartProduct item) => Card(
    child: InkWell(
      // Enhancement 1: a cart item opens the same reusable product detail screen.
      onTap: () => _openProduct(item.id),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Row(
          children: [
            SizedBox(
              width: 74.w,
              height: 74.w,
              child: CachedNetworkImage(
                imageUrl: item.thumbnail,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const Icon(Icons.image),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  CustomText(
                    text:
                        '\$${item.price.toStringAsFixed(2)}  ×  ${item.quantity}',
                    fontSize: 13.sp,
                  ),
                  SizedBox(height: 5.h),
                  CustomText(
                    text:
                        'Subtotal: \$${item.discountedTotal.toStringAsFixed(2)}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () =>
                      context.read<CartProvider>().increaseQuantity(item.id),
                  icon: const Icon(Icons.add),
                ),
                CustomText(
                  text: '${item.quantity}',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  onPressed: () =>
                      context.read<CartProvider>().decreaseQuantity(item.id),
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
            Icon(Icons.chevron_right, size: 20.sp),
          ],
        ),
      ),
    ),
  );
}
