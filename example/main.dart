// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_pandadoc/otel_pandadoc.dart';

/// Traces PandaDoc calls with OpenTelemetry.
///
/// `otel_pandadoc` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each PandaDoc call in
/// [tracedPandadoc]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'pandadoc-example');

  // Wraps a PandaDoc API call in a CLIENT span.
  final pandadocId = await tracedPandadoc<String>(
    operation: 'documents.create',
    invoke: () async {
      // Make the PandaDoc call here, then report what it returned.
      const id = 'pandadoc_8f3a2c';
      return const PandadocCallResult(
          value: id,
          result: PandadocResult(
              itemCount: 3,
              documentId: 'document_8f3a2c',
              status: 'document.uploaded',
              templateUsed: true,
              recipientCount: 3,
              tier: 'essentials',
              workspaceId: 'workspace_id',
              paymentEnabled: true,
              amountTotalMinor: 1999,
              currency: 'usd',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedPandadoc documents.create returned $pandadocId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPandadocInstrumentationAsync.
  await runWithoutPandadocInstrumentationAsync(
    () => tracedPandadoc<String>(
      operation: 'documents.create',
      invoke: () async {
        const id = 'pandadoc_8f3a2c';
        return const PandadocCallResult(
            value: id,
            result: PandadocResult(
                itemCount: 3,
                documentId: 'document_8f3a2c',
                status: 'document.uploaded',
                templateUsed: true,
                recipientCount: 3,
                tier: 'essentials',
                workspaceId: 'workspace_id',
                paymentEnabled: true,
                amountTotalMinor: 1999,
                currency: 'usd',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
