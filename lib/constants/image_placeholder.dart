import 'package:flutter/widgets.dart';

const String kImagePlaceholderUrl =
    "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=";
const AssetImage ImagePlaceholderPhoto = AssetImage("placeholderImage.png");

Widget _buildProductImage(String imageUrl) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset("assets/placeholderImage.jpg", fit: BoxFit.cover);
      },
    ),
  );
}

// import 'package:flutter/widgets.dart';

// /// Your placeholder asset (make sure pubspec.yaml contains it)
// const AssetImage ImagePlaceholderPhoto = AssetImage(
//   "assets/placeholderImage.png",
// );

// /// If you still want to keep this URL placeholder
// const String kImagePlaceholderUrl =
//     "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=";

// /// ----------------------------------------------------------------
// /// Custom ImageProvider that automatically falls back to local asset
// /// ----------------------------------------------------------------
// class FallbackNetworkImage extends ImageProvider<FallbackNetworkImage> {
//   final String url;

//   const FallbackNetworkImage(this.url);

//   @override
//   Future<FallbackNetworkImage> obtainKey(ImageConfiguration configuration) {
//     return SynchronousFuture<FallbackNetworkImage>(this);
//   }

//   @override
//   ImageStreamCompleter load(FallbackNetworkImage key, DecoderCallback decode) {
//     final Uri? resolved = Uri.tryParse(url);

//     // If URL is invalid → return local asset immediately
//     if (resolved == null) {
//       return ImagePlaceholderPhoto.load(ImagePlaceholderPhoto, decode);
//     }

//     // Try loading network image
//     final networkImage = NetworkImage(url);

//     return networkImage.load(networkImage, decode)
//       // If FAILED → return local asset
//       ..addErrorListener((error) {
//         // ignore
//       });
//   }

//   @override
//   bool operator ==(Object other) =>
//       other is FallbackNetworkImage && other.url == url;

//   @override
//   int get hashCode => url.hashCode;
// }
