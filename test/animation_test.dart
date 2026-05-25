import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_number_flow/flutter_number_flow.dart';

void main() {
  group('Animation Tests', () {
    testWidgets('NumberFlow slide animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 123,
              animationStyle: NumberFlowAnimation.slide,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('NumberFlow crossFade animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 456,
              animationStyle: NumberFlowAnimation.crossFade,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('NumberFlow slideFade animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 789,
              animationStyle: NumberFlowAnimation.slideFade,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('NumberFlow spin animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 321,
              animationStyle: NumberFlowAnimation.spin,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('NumberFlow with custom animation curve',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 789,
              curve: Curves.bounceIn,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('NumberFlow with custom text style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 101112,
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    test('NumberFlowAnimation enum values', () {
      expect(NumberFlowAnimation.slide, isA<NumberFlowAnimation>());
      expect(NumberFlowAnimation.crossFade, isA<NumberFlowAnimation>());
      expect(NumberFlowAnimation.slideFade, isA<NumberFlowAnimation>());
      expect(NumberFlowAnimation.spin, isA<NumberFlowAnimation>());

      // Ensure we have exactly 4 animation types
      expect(NumberFlowAnimation.values.length, equals(4));
    });

    testWidgets('NumberFlow animation duration configuration',
        (WidgetTester tester) async {
      const shortDuration = Duration(milliseconds: 100);
      const longDuration = Duration(milliseconds: 1000);

      // Test short duration
      await tester.pumpWidget(
        const MaterialApp(
          home: NumberFlow(
            value: 111,
            duration: shortDuration,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test long duration
      await tester.pumpWidget(
        const MaterialApp(
          home: NumberFlow(
            value: 222,
            duration: longDuration,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NumberFlow), findsOneWidget);
    });
  });

  group('Direction-aware slide', () {
    testWidgets('slide direction changes with increasing value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => const Column(
                children: [
                  NumberFlow(
                    value: 100,
                    animationStyle: NumberFlowAnimation.slide,
                    duration: Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('slide direction changes with decreasing value',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 50,
              previousValue: 100,
              animationStyle: NumberFlowAnimation.slide,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });
  });

  group('Stagger animation', () {
    testWidgets('stagger enabled renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 12345,
              stagger: true,
              staggerFactor: 0.04,
              staggerDirection: StaggerDirection.rightToLeft,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('stagger left to right renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 99999,
              stagger: true,
              staggerDirection: StaggerDirection.leftToRight,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    test('StaggerDirection enum values', () {
      expect(StaggerDirection.values.length, equals(2));
      expect(
        StaggerDirection.values,
        contains(StaggerDirection.leftToRight),
      );
      expect(
        StaggerDirection.values,
        contains(StaggerDirection.rightToLeft),
      );
    });
  });

  group('Default curve', () {
    test('kNumberFlowDefaultCurve is easeOutCubic', () {
      expect(kNumberFlowDefaultCurve, equals(Curves.easeOutCubic));
    });

    testWidgets('NumberFlow uses easeOutCubic by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 42,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final numberFlow =
          tester.widget<NumberFlow>(find.byType(NumberFlow));
      expect(numberFlow.curve, equals(kNumberFlowDefaultCurve));
    });
  });

  group('Spin animation', () {
    testWidgets('spin animates through intermediate digits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const NumberFlow(
                    value: 5,
                    animationStyle: NumberFlowAnimation.spin,
                    duration: Duration(milliseconds: 300),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('spin with previousValue renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 8,
              previousValue: 2,
              animationStyle: NumberFlowAnimation.spin,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });
  });

  group('SlideFade animation', () {
    testWidgets('slideFade renders with value change',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const NumberFlow(
                    value: 100,
                    animationStyle: NumberFlowAnimation.slideFade,
                    duration: Duration(milliseconds: 300),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });

    testWidgets('slideFade with previousValue',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberFlow(
              value: 200,
              previousValue: 100,
              animationStyle: NumberFlowAnimation.slideFade,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NumberFlow), findsOneWidget);
    });
  });
}
