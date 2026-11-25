import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/src/widgets/json_viewer.dart';
import 'package:mockmate_flutter/src/widgets/status_badge.dart';

/// Detailed view of a recorded transaction.
class RequestDetailView extends StatelessWidget {
  const RequestDetailView({
    super.key,
    required this.transaction,
  });

  final RecordedTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HttpMethodBadge(
                        method: transaction.request.method.toVerb(),
                        fontSize: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.request.uri.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusCodeBadge(statusCode: transaction.statusCode),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Latency: ${transaction.duration.inMilliseconds}ms | Route: ${transaction.matchedRoute ?? "Unmatched"} | Scenario: ${transaction.activeScenario ?? "Default"}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Request'),
              Tab(text: 'Response'),
              Tab(text: 'Headers'),
              Tab(text: 'Diagnostics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Request tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Request Body',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      JsonViewerWidget(data: transaction.request.body),
                    ],
                  ),
                ),
                // Response tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Response Body',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      JsonViewerWidget(data: transaction.response?.body),
                    ],
                  ),
                ),
                // Headers tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Request Headers',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _HeadersTable(headers: transaction.request.headers),
                      const SizedBox(height: 16),
                      const Text('Response Headers',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _HeadersTable(
                          headers: transaction.response?.headers ?? {}),
                    ],
                  ),
                ),
                // Diagnostics tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction.errorDetails != null) ...[
                        const Text('Error Details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            transaction.errorDetails!,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('Transaction ID: ${transaction.id}'),
                      Text(
                          'Recorded Timestamp: ${transaction.recordedAt.toIso8601String()}'),
                      Text(
                          'Path Parameters: ${transaction.request.pathParameters}'),
                      Text(
                          'Query Parameters: ${transaction.request.queryParameters}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadersTable extends StatelessWidget {
  const _HeadersTable({required this.headers});

  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) {
      return const Text('No headers',
          style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Table(
      border:
          TableBorder.all(color: Theme.of(context).dividerColor, width: 0.5),
      children: headers.entries.map((e) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(e.key,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(e.value,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
