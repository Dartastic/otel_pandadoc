// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_pandadoc_suppression.dart';

const _tracerName = 'dartastic_otel_libs_pandadoc';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class PandadocResult {
  /// Creates a result.
  const PandadocResult({
    this.itemCount,
    this.documentId,
    this.status,
    this.templateUsed,
    this.recipientCount,
    this.tier,
    this.workspaceId,
    this.paymentEnabled,
    this.amountTotalMinor,
    this.currency,
    this.requestId,
    this.statusCode,
  });

  /// Items in `results`.
  final int? itemCount;

  /// `id` of the document.
  final String? documentId;

  /// `document.uploaded` / `document.draft` / `document.sent` /
  /// `document.viewed` / `document.completed` / `document.declined` /
  /// `document.voided` / `document.error` / `payment.paid`.
  final String? status;

  /// `template_uuid` was provided.
  final bool? templateUsed;

  /// `recipients.length` on the document.
  final int? recipientCount;

  /// `essentials` / `business` / `enterprise` / `api`.
  final String? tier;

  /// `workspace_id`.
  final String? workspaceId;

  /// `payment` block included — PandaDoc charges for the payments
  /// feature separately.
  final bool? paymentEnabled;

  /// Payment total in minor units.
  final int? amountTotalMinor;

  /// ISO 4217.
  final String? currency;

  /// `X-Request-Id` (when present).
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class PandadocCallResult<T> {
  /// Creates a call result.
  const PandadocCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final PandadocResult? result;
}

/// Wraps a PandaDoc API call in a CLIENT span. [operation] is one of
/// `documents.list`, `documents.get`, `documents.create`,
/// `documents.create_from_template`, `documents.send`,
/// `documents.transfer_ownership`, `documents.status`,
/// `documents.download`, `documents.attachments.list`,
/// `templates.list`, `templates.get`, `content_library_items.list`,
/// `workspaces.list`, `webhooks.list`, `webhooks.create`,
/// `oauth.token`, `payment.update`.
Future<T> tracedPandadoc<T>({
  required String operation,
  required Future<PandadocCallResult<T>> Function() invoke,
}) async {
  if (pandadocInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'pandadoc',
    'rpc.method': operation,
    'pandadoc.operation': operation,
  };

  final span = _tracer().startSpan(
    'pandadoc $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'pandadoc.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.documentId != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.document.id',
          r.result!.documentId!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.document.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'document.declined' ||
            r.result!.status == 'document.voided' ||
            r.result!.status == 'document.error') {
          span.setStatus(
            SpanStatusCode.Error,
            'PandaDoc ${r.result!.status}',
          );
        }
      }
      if (r.result!.templateUsed != null) {
        extras.add(OTelAPI.attributeBool(
          'pandadoc.template.used',
          r.result!.templateUsed!,
        ));
      }
      if (r.result!.recipientCount != null) {
        extras.add(OTelAPI.attributeInt(
          'pandadoc.recipient_count',
          r.result!.recipientCount!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.tier',
          r.result!.tier!,
        ));
      }
      if (r.result!.workspaceId != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.workspace.id',
          r.result!.workspaceId!,
        ));
      }
      if (r.result!.paymentEnabled != null) {
        extras.add(OTelAPI.attributeBool(
          'pandadoc.payment.enabled',
          r.result!.paymentEnabled!,
        ));
      }
      if (r.result!.amountTotalMinor != null) {
        extras.add(OTelAPI.attributeInt(
          'pandadoc.amount.total.minor',
          r.result!.amountTotalMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'pandadoc.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'PandaDoc HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
