import 'package:flutter/material.dart';

/// A single, bounded horizontal list for cards inside a vertically scrolling
/// dashboard. Nesting a horizontal ListView in another horizontal ListView
/// gives the inner viewport unbounded width when records are returned.
class Care360HorizontalCards extends StatelessWidget {
  const Care360HorizontalCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => ListView.builder(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
}
