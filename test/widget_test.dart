import 'dart:async';
import 'package:message_board/services/board_service.dart';
import 'package:message_board/models/board_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_board/main.dart';
import 'package:message_board/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'alice';
}

class FakeAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => FakeUser();
}

class FakeBoard extends Fake implements BoardService {
  final Stream<List<BoardMessage>> stream;
  FakeBoard(this.stream);
  @override
  Stream<List<BoardMessage>> messageBoard() => stream;
  @override
  Future<Map<String, dynamic>?> pending() async => null;
}

class FakeDb extends Fake implements FirebaseFirestore {}

void main() {
  testWidgets('splash failure shows Retry and retries once', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Splash(
          initializer: () async {
            attempts++;
            throw StateError('Synthetic initialization failure');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
  testWidgets('capture real rendered authentication screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: AuthForm(auth: AuthService(FakeAuth(), FakeDb()))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('evidence/login.png'),
    );
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('evidence/registration.png'),
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter First name'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('evidence/invalid-input.png'),
    );
  });

  testWidgets('registration validates invalid email and mismatch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthForm(auth: AuthService(FakeAuth(), FakeDb()))),
    );
    await tester.tap(find.text('Create an account'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Alice',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Tester',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'bad');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret2',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Passwords must match'), findsOneWidget);
  });
  testWidgets(
    'board cancels its listener on navigation and does not duplicate on rebuild',
    (tester) async {
      var listens = 0, cancels = 0;
      final controller = StreamController<List<BoardMessage>>(
        onListen: () => listens++,
        onCancel: () => cancels++,
      );
      final auth = AuthService(FakeAuth(), FakeDb());
      final service = FakeBoard(controller.stream);
      await tester.pumpWidget(
        MaterialApp(
          home: BoardScreen(
            auth: auth,
            name: 'Alice Tester',
            boardService: service,
          ),
        ),
      );
      await tester.pump();
      controller.add([]);
      await tester.pump();
      expect(find.text('Start the conversation'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: BoardScreen(
            auth: auth,
            name: 'Alice Tester',
            boardService: service,
          ),
        ),
      );
      await tester.pump();
      expect(listens, 1);
      await tester.pumpWidget(const SizedBox());
      expect(cancels, 1);
      await tester.runAsync(() => controller.close());
    },
  );
}
