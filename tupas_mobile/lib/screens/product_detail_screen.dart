import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// models
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 2: details page shown when a product card is tapped, displaying
// the full product info (images, price, description, specs, reviews) fetched
// from the API via the Product model.
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imageController = PageController();
  int _imageIndex = 0;
  bool _isAddingToCart = false;
  int _quantity = 1;

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      // Enhancement 3: sends this displayed product ID and its quantity to /carts/add.
      await context.read<CartProvider>().addProduct(
        widget.product,
        _quantity,
        5,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added to cart (simulated API response).'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add product: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isNotEmpty
        ? product.images
        : [product.thumbnail];
    final discountedPrice =
        product.price * (1 - product.discountPercentage / 100);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(images),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.brand.isNotEmpty
                          ? '${product.brand} · ${product.category}'
                          : product.category,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 6.h),
                    CustomText(
                      text: product.title,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        CustomText(
                          text: '\$${discountedPrice.toStringAsFixed(2)}',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        if (product.discountPercentage > 0) ...[
                          SizedBox(width: 8.w),
                          CustomText(
                            text: '\$${product.price.toStringAsFixed(2)}',
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: CustomText(
                              text:
                                  '-${product.discountPercentage.toStringAsFixed(0)}%',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text:
                              '${product.rating.toStringAsFixed(2)} · ${product.reviews.length} reviews',
                          fontSize: 13.sp,
                        ),
                        SizedBox(width: 12.w),
                        CustomText(
                          text: product.availabilityStatus.isNotEmpty
                              ? product.availabilityStatus
                              : (product.stock > 0
                                    ? 'In Stock (${product.stock})'
                                    : 'Out of Stock'),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        const Text('Quantity: '),
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_quantity'),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    CustomText(
                      text: 'Description',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 6.h),
                    CustomText(text: product.description, fontSize: 14.sp),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isAddingToCart ? null : _addToCart,
                        icon: _isAddingToCart
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: Text(
                          _isAddingToCart ? 'Adding...' : 'Add to cart',
                        ),
                      ),
                    ),
                    if (product.tags.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: product.tags
                            .map(
                              (tag) => Chip(
                                label: CustomText(text: tag, fontSize: 12.sp),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    CustomText(
                      text: 'Details',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 6.h),
                    _buildDetailRow('SKU', product.sku),
                    _buildDetailRow('Weight', '${product.weight} g'),
                    _buildDetailRow(
                      'Dimensions',
                      '${product.dimensions.width} x ${product.dimensions.height} x ${product.dimensions.depth} cm',
                    ),
                    _buildDetailRow(
                      'Minimum Order',
                      '${product.minimumOrderQuantity}',
                    ),
                    _buildDetailRow('Warranty', product.warrantyInformation),
                    _buildDetailRow('Shipping', product.shippingInformation),
                    _buildDetailRow('Return Policy', product.returnPolicy),
                    if (product.reviews.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      CustomText(
                        text: 'Reviews',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 8.h),
                      ...product.reviews.map(
                        (review) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    text: review.reviewerName,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  SizedBox(width: 8.w),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        size: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              CustomText(text: review.comment, fontSize: 13.sp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280.h,
          width: double.infinity,
          child: PageView.builder(
            controller: _imageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _imageIndex = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, _, _) =>
                    Center(child: Icon(Icons.image, size: 48.sp)),
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _imageIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
