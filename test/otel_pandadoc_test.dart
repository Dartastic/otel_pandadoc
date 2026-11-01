// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_pandadoc/otel_pandadoc.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_pandadoc-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('documents.send records template + payment + tier', () async {
    await tracedPandadoc<String>(
      operation: 'documents.send',
      invoke: () async => const PandadocCallResult(
        value: 'ok',
        result: PandadocResult(
          documentId: 'd-1',
          status: 'document.sent',
          templateUsed: true,
          recipientCount: 2,
          tier: 'business',
          workspaceId: 'ws-1',
          paymentEnabled: true,
          amountTotalMinor: 199900,
          currency: 'USD',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('pandadoc documents.send')!);
    expect(a['pandadoc.document.id'], 'd-1');
    expect(a['pandadoc.template.used'], true);
    expect(a['pandadoc.payment.enabled'], true);
    expect(a['pandadoc.tier'], 'business');
    expect(a['pandadoc.amount.total.minor'], 199900);
  });

  test('declined sets span error', () async {
    await tracedPandadoc<String>(
      operation: 'documents.status',
      invoke: () async => const PandadocCallResult(
        value: 'ok',
        result: PandadocResult(status: 'document.declined'),
      ),
    );
    expect(
      spans.findSpanByName('pandadoc documents.status')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutPandadocInstrumentationAsync(() async {
      await tracedPandadoc<String>(
        operation: 'documents.list',
        invoke: () async => const PandadocCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('pandadoc '), isEmpty);
  });
}
