import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.brand,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String brand;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;


  double get discountedPrice => price * (1 - discountPercentage / 100);

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      price: (json['price'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      stock: json['stock'] as int,
      thumbnail: json['thumbnail'] as String,
    );
  }

  @override
  List<Object?> get props => [id];
}
