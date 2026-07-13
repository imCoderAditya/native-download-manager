import 'package:flutter/material.dart';
import 'dart:async';
import 'package:native_download_manager/native_download_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Download Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const DownloadManagerScreen(),
    );
  }
}

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController(
    text:
        'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  );
  final _fileNameController = TextEditingController(text: 'big_buck_bunny.mp4');

  bool _wifiOnly = false;
  bool _chargingOnly = false;
  bool _overwrite = false;
  DownloadPriority _priority = DownloadPriority.normal;
  int _concurrencyLimit = 3;

  List<DownloadTask> _tasks = [];
  late TabController _tabController;
  late StreamSubscription<DownloadTask> _statusSubscription;
  late StreamSubscription<DownloadProgress> _progressSubscription;

  // Custom pre-configured files for quick testing
  final List<Map<String, String>> _sampleFiles = [
    {
      'name': 'Big Buck Bunny (Video, 158MB)',
      'url':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'filename': 'big_buck_bunny.mp4',
    },
    {
      'name': 'Elephant\'s Dream (Video, 109MB)',
      'url':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'filename': 'elephants_dream.mp4',
    },
    {
      'name': 'Sample PDF Document (1MB)',
      'url':
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      'filename': 'dummy.pdf',
    },
    {
      'name': 'Invalid/Failing URL Test',
      'url': 'https://invalid-domain-that-does-not-exist.com/file.zip',
      'filename': 'failed_file.zip',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set initial concurrency limit
    NativeDownloadManager().setConcurrencyLimit(_concurrencyLimit);

    _refreshTasks();

    // Listen to status & progress changes to update the UI reactively
    _statusSubscription = NativeDownloadManager().statusStream.listen((task) {
      _refreshTasks();
    });

    _progressSubscription = NativeDownloadManager().progressStream.listen((
      progress,
    ) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == progress.taskId);
        if (index != -1) {
          final t = _tasks[index];
          _tasks[index] = DownloadTask(
            id: t.id,
            url: t.url,
            fileName: t.fileName,
            filePath: t.filePath,
            status: t.status,
            progress: progress,
            error: t.error,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _fileNameController.dispose();
    _statusSubscription.cancel();
    _progressSubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    final list = await NativeDownloadManager().downloads();
    setState(() {
      _tasks = list;
    });
  }

  void _startNewDownload() async {
    final url = _urlController.text.trim();
    final name = _fileNameController.text.trim();

    if (url.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out URL and Filename')),
      );
      return;
    }

    final constraints = <NetworkConstraint>[];
    if (_wifiOnly) constraints.add(NetworkConstraint.wifiOnly);
    if (_chargingOnly) constraints.add(NetworkConstraint.chargingOnly);

    try {
      await NativeDownloadManager.download(
        url: url,
        fileName: name,
        priority: _priority,
        networkConstraints: constraints,
        overwrite: _overwrite,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enqueued: $name')));
      _refreshTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _selectSample(Map<String, String> sample) {
    setState(() {
      _urlController.text = sample['url']!;
      _fileNameController.text = sample['filename']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.enqueued ||
              t.status == DownloadStatus.paused,
        )
        .toList();
    final completedTasks = _tasks
        .where(
          (t) =>
              t.status == DownloadStatus.completed ||
              t.status == DownloadStatus.failed ||
              t.status == DownloadStatus.canceled,
        )
        .toList();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Download Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshTasks),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear history',
            onPressed: () async {
              await NativeDownloadManager().clearHistory();
              _refreshTasks();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active (${activeTasks.length})'),
            Tab(text: 'History (${completedTasks.length})'),
          ],
        ),
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel for adding download requests (Web responsive or vertical layout)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Download Request',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildDownloadForm(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Right panel showing downloads list
                Expanded(
                  flex: 3,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(activeTasks),
                      _buildTaskList(completedTasks),
                    ],
                  ),
                ),
              ],
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(activeTasks),
                _buildTaskList(completedTasks),
              ],
            ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: _showNewDownloadSheet,
              icon: const Icon(Icons.add),
              label: const Text('New Download'),
            ),
    );
  }

  void _showNewDownloadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Download Request',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDownloadForm(setSheetState: setSheetState),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadForm({void Function(void Function())? setSheetState}) {
    void updateState(void Function() fn) {
      if (setSheetState != null) {
        setSheetState(fn);
      }
      setState(fn);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Download URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DownloadPriority>(
          initialValue: _priority,
          decoration: const InputDecoration(
            labelText: 'Priority',
            border: OutlineInputBorder(),
          ),
          items: DownloadPriority.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              updateState(() => _priority = val);
            }
          },
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('WiFi Only'),
          value: _wifiOnly,
          onChanged: (val) {
            if (val != null) {
              updateState(() => _wifiOnly = val);
            }
          },
        ),
        CheckboxListTile(
          title: const Text('Charging Only'),
          value: _chargingOnly,
          onChanged: (val) {
            if (val != null) {
              updateState(() => _chargingOnly = val);
            }
          },
        ),
        CheckboxListTile(
          title: const Text('Overwrite if file exists'),
          value: _overwrite,
          onChanged: (val) {
            if (val != null) {
              updateState(() => _overwrite = val);
            }
          },
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Concurrency Limit: $_concurrencyLimit'),
            SizedBox(
              width: double.infinity,
              child: Slider(
                min: 1,
                max: 5,
                divisions: 4,
                label: _concurrencyLimit.toString(),
                value: _concurrencyLimit.toDouble(),
                onChanged: (val) {
                  updateState(() {
                    _concurrencyLimit = val.toInt();
                    NativeDownloadManager().setConcurrencyLimit(
                      _concurrencyLimit,
                    );
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _startNewDownload();
              if (setSheetState != null) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Queue Download'),
          ),
        ),
        const Divider(height: 32),
        Text(
          'Quick Samples',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._sampleFiles.map((sample) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: InkWell(
              onTap: () {
                updateState(() => _selectSample(sample));
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 20,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sample['name']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaskList(List<DownloadTask> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No download tasks'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.url,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (task.status == DownloadStatus.downloading) ...[
                  LinearProgressIndicator(
                    value: task.progress.percentage / 100.0,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task.progress.formattedSizeRatio,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        task.progress.formattedSpeed,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'ETA: ${task.progress.formattedEta}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ] else if (task.status == DownloadStatus.paused) ...[
                  LinearProgressIndicator(
                    value: task.progress.percentage / 100.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${task.progress.percentage.toStringAsFixed(1)}% paused',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        task.progress.formattedSizeRatio,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ] else if (task.status == DownloadStatus.enqueued) ...[
                  const LinearProgressIndicator(value: null),
                  const SizedBox(height: 8),
                  const Text(
                    'Waiting in queue...',
                    style: TextStyle(fontSize: 12),
                  ),
                ] else if (task.status == DownloadStatus.failed) ...[
                  Text(
                    'Error: ${task.error ?? "Unknown error"}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ] else if (task.status == DownloadStatus.completed) ...[
                  Text(
                    'Saved: ${task.filePath ?? "Local path not available"}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (task.status == DownloadStatus.downloading)
                      IconButton(
                        icon: const Icon(Icons.pause),
                        tooltip: 'Pause',
                        onPressed: () => task.pause(),
                      ),
                    if (task.status == DownloadStatus.paused)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Resume',
                        onPressed: () => task.resume(),
                      ),
                    if (task.status == DownloadStatus.downloading ||
                        task.status == DownloadStatus.enqueued ||
                        task.status == DownloadStatus.paused)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Cancel',
                        onPressed: () => task.cancel(),
                      ),
                    if (task.status == DownloadStatus.failed ||
                        task.status == DownloadStatus.canceled)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Retry',
                        onPressed: () => task.retry(),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Remove',
                      onPressed: () => _showDeleteConfirmation(task),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(DownloadStatus status) {
    Color color;
    switch (status) {
      case DownloadStatus.enqueued:
        color = Colors.orange;
        break;
      case DownloadStatus.downloading:
        color = Colors.blue;
        break;
      case DownloadStatus.paused:
        color = Colors.grey;
        break;
      case DownloadStatus.completed:
        color = Colors.green;
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        break;
      case DownloadStatus.canceled:
        color = Colors.purple;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showDeleteConfirmation(DownloadTask task) {
    bool deleteFile = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Download Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Are you sure you want to delete "${task.fileName}"?'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Delete local file from storage'),
                    value: deleteFile,
                    onChanged: (val) {
                      if (val != null) setState(() => deleteFile = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await task.delete(deleteFile: deleteFile);
                    navigator.pop();
                    _refreshTasks();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
