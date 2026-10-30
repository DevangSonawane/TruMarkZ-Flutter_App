import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../data/verification_repository.dart';

/// Opens verification report links (automatic `/verification/documents/{id}/view`
/// and manual `/verification/manual/reports/{id}/view/{i}`) — Secure
/// Certificate Access §18C.
///
/// For `holder_approval` batches those URLs return 403 to anything without
/// the organization's `Authorization: Bearer` session — an external browser,
/// URL launcher or WebView sends none. So TruMarkZ API links are always
/// downloaded with the app's authenticated client and the bytes opened
/// locally; this works for public batches too, so callers don't need to know
/// the batch's mode. Links on any other host keep opening in the browser.
class ReportLinkOpener {
  ReportLinkOpener._();

  static final Set<String> _inFlight = <String>{};

  /// A report URL as embedded in certificate QR codes and `report_url`.
  static bool isReportLink(String raw) {
    final Uri? uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https') return false;
    final String path = uri.path;
    return RegExp(r'/verification/documents/[^/]+/view/?$').hasMatch(path) ||
        RegExp(
          r'/verification/manual/reports/[^/]+/view/[^/]+/?$',
        ).hasMatch(path);
  }

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    String rawUrl, {
    String? title,
  }) async {
    final Uri? uri = Uri.tryParse(rawUrl.trim());
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This report is not openable in the app.'),
        ),
      );
      return;
    }

    final VerificationRepository repo = ref.read(
      verificationRepositoryProvider,
    );
    if (!repo.isApiReportUrl(uri)) {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unable to open report.')),
        );
      }
      return;
    }

    final String key = uri.toString();
    if (!_inFlight.add(key)) return;
    final Rect? shareOrigin = _shareOrigin(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Opening report…'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final VerificationBinaryResponse res = await repo.downloadReport(uri);
      if (res.bytes.isEmpty) {
        throw const ApiException(
          statusCode: null,
          message: 'The report is empty.',
        );
      }
      final String fileName = _fileName(uri, res);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(res.bytes, flush: true);
      messenger.hideCurrentSnackBar();
      await Share.shareXFiles(
        <XFile>[XFile(file.path, name: fileName, mimeType: _mime(res))],
        subject: title,
        sharePositionOrigin: shareOrigin,
      );
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 403
                  ? e.message
                  : 'Unable to open report. ${e.message}',
            ),
          ),
        );
    } catch (e) {
      debugPrint('[ReportLinkOpener] open failed: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Unable to open report.')));
    } finally {
      _inFlight.remove(key);
    }
  }

  /// iPad share sheets need an anchor rect or they throw.
  static Rect? _shareOrigin(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static String _mime(VerificationBinaryResponse res) {
    final String type = (res.contentType ?? '').split(';').first.trim();
    return type.isEmpty ? 'application/pdf' : type;
  }

  static String _fileName(Uri uri, VerificationBinaryResponse res) {
    final String? fromHeader = res.dispositionFilename;
    final String raw = fromHeader ?? _fallbackName(uri, _mime(res));
    return raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static String _fallbackName(Uri uri, String mime) {
    final String ext = switch (mime) {
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/webp' => 'webp',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' =>
        'xlsx',
      _ => 'pdf',
    };
    final List<String> segments = uri.pathSegments
        .where((String s) => s.isNotEmpty && s != 'view')
        .toList();
    // Manual links end in `{request_id}/view/{file_index}`; keep both parts.
    final Iterable<String> tail = segments.length >= 2
        ? segments.sublist(segments.length - 2)
        : segments;
    final String id = tail
        .map((String s) => s.length > 12 ? s.substring(0, 12) : s)
        .join('_');
    return 'report_${id.isEmpty ? 'file' : id}.$ext';
  }
}
