import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/src/widgets/json_viewer.dart';
import 'package:mockmate_flutter/src/widgets/status_badge.dart';

/// Request replay tool allowing developers to re-execute and modify past requests.
class ReplayView extends StatefulWidget {
  const ReplayView({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  State<ReplayView> createState() => _ReplayViewState();
}

class _ReplayViewState extends State<ReplayView> {
  RecordedTransaction? _selectedTransaction;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  HttpMethod _selectedMethod = HttpMethod.get;
  ReplayResult? _replayResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _loadTransaction(RecordedTransaction tx) {
    setState(() {
      _selectedTransaction = tx;
      _selectedMethod = tx.request.method;
      _urlController.text = tx.request.uri.toString();
      _bodyController.text = tx.request.bodyAsString ?? '';
      _replayResult = null;
    });
  }

  Future<void> _executeReplay() async {
    if (_selectedTransaction == null) return;

    setState(() => _isLoading = true);

    try {
      final modifiedUri = Uri.parse(_urlController.text);
      dynamic parsedBody;
      if (_bodyController.text.isNotEmpty) {
        try {
          parsedBody = jsonDecode(_bodyController.text);
        } catch (_) {
          parsedBody = _bodyController.text;
        }
      }

      final modifiedReq = MockRequest(
        method: _selectedMethod,
        uri: modifiedUri,
        headers: _selectedTransaction!.request.headers,
        body: parsedBody,
      );

      final result = await widget.mockMate.replayEngine.replay(
        transaction: _selectedTransaction!,
        handler: (req) => widget.mockMate.handleRequest(req),
        modifiedRequest: modifiedReq,
      );

      setState(() {
        _replayResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Replay failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.mockMate.requestHistory;

    return Row(
      children: [
        // Transaction list
        SizedBox(
          width: 280,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Recorded Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          'No history available',
                          style:
                              TextStyle(color: Theme.of(context).disabledColor),
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = history[index];
                          final isSelected = _selectedTransaction?.id == tx.id;
                          return ListTile(
                            selected: isSelected,
                            leading: HttpMethodBadge(
                                method: tx.request.method.toVerb()),
                            title: Text(tx.request.path,
                                style: const TextStyle(fontSize: 12)),
                            trailing:
                                StatusCodeBadge(statusCode: tx.statusCode),
                            onTap: () => _loadTransaction(tx),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Replay workspace
        Expanded(
          child: _selectedTransaction == null
              ? Center(
                  child: Text(
                    'Select a recorded transaction from the left to replay',
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DropdownButton<HttpMethod>(
                            value: _selectedMethod,
                            borderRadius: BorderRadius.circular(8),
                            items: HttpMethod.values.map((m) {
                              return DropdownMenuItem(
                                  value: m, child: Text(m.toVerb()));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMethod = val);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                labelText: 'URL',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Replay Request'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isLoading ? null : _executeReplay,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Request Body (JSON / Text)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bodyController,
                        maxLines: 5,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          hintText: 'Request body...',
                        ),
                      ),
                      if (_replayResult != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text('Replay Results',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Status: ${_replayResult!.replayedResponse?.statusCode ?? "Error"}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Text(
                                'Duration: ${_replayResult!.duration.inMilliseconds}ms'),
                            const SizedBox(width: 16),
                            Text(
                              _replayResult!.isMatch
                                  ? 'Matches Original Status'
                                  : 'Status Differs From Original',
                              style: TextStyle(
                                color: _replayResult!.isMatch
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        JsonViewerWidget(
                            data: _replayResult!.replayedResponse?.body),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
