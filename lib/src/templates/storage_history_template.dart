import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 09: Storage History & File Manager
class StorageHistoryTemplatePage extends StatefulWidget {
  final String title;

  const StorageHistoryTemplatePage({
    super.key,
    this.title = '09. Storage History Manager',
  });

  @override
  State<StorageHistoryTemplatePage> createState() => _StorageHistoryTemplatePageState();
}

class _StorageHistoryTemplatePageState extends State<StorageHistoryTemplatePage> {
  List<DownloadTask> _allHistory = [];
  late StreamSubscription<DownloadTask> _statusSub;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _statusSub = NativeDownloadManager().statusStream.listen((_) => _loadHistory());
  }

  @override
  void dispose() {
    _statusSub.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final tasks = await NativeDownloadManager().downloads();
    if (mounted) setState(() => _allHistory = tasks);
  }

  void _clearAllHistory() async {
    await NativeDownloadManager().clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            tooltip: 'Clear History',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body: _allHistory.isEmpty
          ? const Center(child: Text('History is empty.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allHistory.length,
              itemBuilder: (context, index) {
                final task = _allHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(task.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Status: ${task.status.name.toUpperCase()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () async {
                        await task.delete(deleteFile: true);
                        _loadHistory();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
