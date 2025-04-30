import 'package:flutter/material.dart';

class ResponsiveButtonsGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxCrossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const ResponsiveButtonsGrid({
    Key? key,
    required this.children,
    this.maxCrossAxisCount = 3,
    this.childAspectRatio = 3.0,
    this.padding = const EdgeInsets.all(0),
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the available width
    final width = MediaQuery.of(context).size.width;
    
    // Calculate the appropriate number of columns
    int crossAxisCount = 1;
    if (width > 600) {
      crossAxisCount = 3;
    } else if (width > 400) {
      crossAxisCount = 2;
    }
    
    // Limit to max columns
    crossAxisCount = crossAxisCount > maxCrossAxisCount 
        ? maxCrossAxisCount 
        : crossAxisCount;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}