// Tests de base pour Notilus Browser
// 
// Note: Les tests nécessitent une initialisation complète de l'application
// avec tous les providers et services. Pour l'instant, ce fichier contient
// un test basique qui sera étendu dans le futur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Notilus Browser - Test basique', (WidgetTester tester) async {
    // Test basique pour vérifier que Flutter fonctionne
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Notilus Browser'),
          ),
        ),
      ),
    );

    // Vérifier que le texte est présent
    expect(find.text('Notilus Browser'), findsOneWidget);
  });
}
