import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asset_inventory/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AssetInventoryApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}