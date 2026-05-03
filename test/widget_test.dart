import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_pads/main.dart';
import 'package:worship_pads/models/sound_entry.dart';

void main() {
  testWidgets('sound library folders open their collections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WorshipPadsApp());

    final scaffoldState = tester.state<ScaffoldState>(
      find.byType(Scaffold).first,
    );
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final soundLibraryTile = tester.widget<ListTile>(
      find.byKey(const Key('drawer-sound-library')),
    );
    soundLibraryTile.onTap?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Major'), findsWidgets);
    expect(find.text('Minor'), findsWidgets);

    await tester.tap(find.byKey(const Key('sound-library-major')));
    await tester.pumpAndSettle();

    expect(find.text('E'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    await tester.tap(find.text('E'));
    await tester.pumpAndSettle();

    expect(find.text('Major - E'), findsOneWidget);
    expect(find.text('Add Your First Sound'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sound-library-minor')));
    await tester.pumpAndSettle();

    expect(find.text('C#m'), findsOneWidget);
    expect(find.text('D#m'), findsOneWidget);
  });

  testWidgets('tapping the active sound again deselects it', (
    WidgetTester tester,
  ) async {
    const activeSound = SoundEntry(
      name: 'Pad E',
      path: 'C:/sounds/pad-e.mp3',
      sizeInBytes: 1024 * 1024,
    );

    await tester.pumpWidget(
      const WorshipPadsApp(
        initialLibrarySounds: {
          'Major::E': [activeSound],
        },
        initialActiveSoundPaths: {'Major::E': 'C:/sounds/pad-e.mp3'},
      ),
    );

    final scaffoldState = tester.state<ScaffoldState>(
      find.byType(Scaffold).first,
    );
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final soundLibraryTile = tester.widget<ListTile>(
      find.byKey(const Key('drawer-sound-library')),
    );
    soundLibraryTile.onTap?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('sound-library-major')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('E'));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sound-tile-Pad E')));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsNothing);
  });
}
