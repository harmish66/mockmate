import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/src/views/request_detail_view.dart';
import 'package:mockmate_flutter/src/widgets/status_badge.dart';

/// Request history explorer with search and filters.
class RequestsView extends StatefulWidget {
  const RequestsView({
    super.key,
    required this.mockMate,
  });

  final MockMate mockMate;

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  String _searchQuery = '';
  HttpMethod? _selectedMethod;
  bool _onlyErrors = false;
  RecordedTransaction? _selectedTransaction;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.mockMate.recorder.filter(
      query: _searchQuery,
      method: _selectedMethod,
      onlyErrors: _onlyErrors,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth > 800;

        Widget listWidget = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search path, URL, or method...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('ALL'),
                          selected: _selectedMethod == null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          onSelected: (_) =>
                              setState(() => _selectedMethod = null),
                        ),
                        const SizedBox(width: 6),
                        ...HttpMethod.values.map((method) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(method.toVerb()),
                              selected: _selectedMethod == method,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              onSelected: (_) =>
                                  setState(() => _selectedMethod = method),
                            ),
                          );
                        }),
                        FilterChip(
                          label: const Text('Errors Only'),
                          selected: _onlyErrors,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          onSelected: (val) =>
                              setState(() => _onlyErrors = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 48, color: Theme.of(context).disabledColor),
                          const SizedBox(height: 12),
                          const Text('No recorded requests matching filters'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isSelected = _selectedTransaction?.id == tx.id;

                        return ListTile(
                          selected: isSelected,
                          leading: HttpMethodBadge(
                              method: tx.request.method.toVerb()),
                          title: Text(
                            tx.request.path,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${tx.duration.inMilliseconds}ms • ${tx.recordedAt.hour.toString().padLeft(2, '0')}:${tx.recordedAt.minute.toString().padLeft(2, '0')}:${tx.recordedAt.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: StatusCodeBadge(
                            statusCode: tx.statusCode,
                            statusMessage: tx.response?.statusMessage,
                          ),
                          onTap: () {
                            if (isSplit) {
                              setState(() => _selectedTransaction = tx);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => Scaffold(
                                    appBar:
                                        AppBar(title: Text(tx.request.path)),
                                    body: RequestDetailView(transaction: tx),
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );

        if (!isSplit) {
          return listWidget;
        }

        return Row(
          children: [
            SizedBox(width: 360, child: listWidget),
            const VerticalDivider(width: 1),
            Expanded(
              child: _selectedTransaction == null
                  ? Center(
                      child: Text(
                        'Select a request to inspect details',
                        style:
                            TextStyle(color: Theme.of(context).disabledColor),
                      ),
                    )
                  : RequestDetailView(transaction: _selectedTransaction!),
            ),
          ],
        );
      },
    );
  }
}
