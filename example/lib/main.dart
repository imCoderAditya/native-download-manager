import 'package:flutter/material.dart';
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
      debugShowCheckedModeBanner: false,
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
      home: const HomePage(),
    );
  }
}

/// Main Home Screen featuring Download Buttons calling the package functions
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Download Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_rounded),
            tooltip: 'Recent Downloads',
            onPressed: () {
              // ⚡ Call function to show Active & Past downloads dialog
              AppDownloadService.showDownloadsDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.cloud_download_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Native Download Manager',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'High-performance background downloads with live progress dialogs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // 🔴 BUTTON 1: Download Catbox PDF (In-Page Progress UI)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // ⚡ Call startDownload function on button press!
                    AppDownloadService.startDownload(
                      url: 'https://files.catbox.moe/vxirfe.pdf',
                      fileName: 'vxirfe_document1.pdf',
                      overwrite: false,
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Start Download (In-Page Progress)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🌟 Live Active Download Progress Card on Home Screen (Called via AppDownloadService helper function)
              AppDownloadService.currentDownloadWidget(),

              const SizedBox(height: 10),

              // 🔵 BUTTON 2: View Active & Recent Downloads Dialog
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // ⚡ Call showDownloadsDialog function on button press!
                    AppDownloadService.showDownloadsDialog(context);
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Active & Recent Downloads'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 🟣 BUTTON 3: Open 10 Templates Catalog
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NativeDownloadTemplateSuite(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Explore All 10 Templates Catalog'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example Catalog Menu Runner (Lives in example app, not in package core).
class NativeDownloadTemplateSuite extends StatefulWidget {
  const NativeDownloadTemplateSuite({super.key});

  @override
  State<NativeDownloadTemplateSuite> createState() =>
      _NativeDownloadTemplateSuiteState();
}

class _NativeDownloadTemplateSuiteState
    extends State<NativeDownloadTemplateSuite> {
  final List<Map<String, dynamic>> _templateCatalog = const [
    {
      'id': '01',
      'title': 'Instant Auto-Start PDF Download',
      'subtitle':
          'Pass PDF URL and autoStart: true to launch instant download & progress dialog on page load.',
      'icon': Icons.bolt_rounded,
      'color': Colors.teal,
      'widget': PdfInvoiceTemplatePage(
        title: 'Instant Catbox PDF Download',
        url: 'https://files.catbox.moe/vxirfe.pdf',
        fileName: 'vxirfe_document.pdf',
        autoStart: true,
      ),
    },
    {
      'id': '02',
      'title': 'Downloads Dashboard & Hub',
      'subtitle':
          'Real-time analytics cards, active task counters, live speed gauges, & quick download request form.',
      'icon': Icons.dashboard_rounded,
      'color': Colors.blue,
      'widget': DashboardTemplatePage(
        defaultUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        defaultFileName: 'sample_video.mp4',
      ),
    },
    {
      'id': '03',
      'title': 'PDF & Invoice Downloader List',
      'subtitle':
          'Invoices, receipts, & document downloads with progress dialog overlay & active/recent downloads list.',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Colors.redAccent,
      'widget': PdfInvoiceTemplatePage(
        invoices: [
          {
            'id': 'PDF-2026-CATBOX',
            'title': 'Catbox PDF Document',
            'url': 'https://files.catbox.moe/vxirfe.pdf',
            'filename': 'vxirfe_document.pdf',
            'size': 'Direct Link PDF',
          },
          {
            'id': 'INV-2026-001',
            'title': 'Monthly Subscription Invoice',
            'url':
                'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'filename': 'Invoice_INV-2026-001.pdf',
            'size': '1.2 MB',
          },
        ],
      ),
    },
    {
      'id': '04',
      'title': 'Media & Video Stream Downloader',
      'subtitle':
          'Large video files (100MB+), speed tracking, ETA calculation, pause, resume, & cancel controls.',
      'icon': Icons.video_library_rounded,
      'color': Colors.purple,
      'widget': MediaVideoTemplatePage(
        videos: [
          {
            'title': 'Big Buck Bunny (158 MB)',
            'url':
                'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            'filename': 'big_buck_bunny_large.mp4',
          },
          {
            'title': 'Elephant\'s Dream (109 MB)',
            'url':
                'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            'filename': 'elephants_dream_large.mp4',
          },
        ],
      ),
    },
    {
      'id': '05',
      'title': 'Batch & Concurrency Queue Manager',
      'subtitle':
          'Multi-file parallel downloads with dynamic queue concurrency limits (1 to 5 parallel downloads).',
      'icon': Icons.dynamic_feed_rounded,
      'color': Colors.teal,
      'widget': BatchDownloadTemplatePage(
        urls: [
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        ],
      ),
    },
    {
      'id': '06',
      'title': 'Auth Header & API Security',
      'subtitle':
          'Protected downloads with Bearer Auth Tokens, API Client Keys, Cookies, & Custom HTTP Headers.',
      'icon': Icons.security_rounded,
      'color': Colors.amber,
      'widget': AuthHeaderTemplatePage(
        protectedUrl:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileName: 'Protected_Report.pdf',
      ),
    },
    {
      'id': '07',
      'title': 'Priority Queue Scheduler',
      'subtitle':
          'Task scheduling with HIGH, NORMAL, and LOW system execution priorities.',
      'icon': Icons.low_priority_rounded,
      'color': Colors.indigo,
      'widget': PriorityQueueTemplatePage(
        sampleUrl:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      ),
    },
    {
      'id': '08',
      'title': 'Network & Power Constraints',
      'subtitle':
          'WiFi-only, Charging-only, & Battery-not-low automated download rules.',
      'icon': Icons.network_check_rounded,
      'color': Colors.deepOrange,
      'widget': ConstraintsTemplatePage(
        sampleUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ),
    },
    {
      'id': '09',
      'title': 'Checksum Integrity Verifier',
      'subtitle':
          'Automated file integrity verification using MD5 and SHA-256 hash validation.',
      'icon': Icons.verified_user_rounded,
      'color': Colors.green,
      'widget': ChecksumVerifierTemplatePage(
        sampleUrl:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      ),
    },
    {
      'id': '10',
      'title': 'Storage History Manager',
      'subtitle':
          'Storage space analyzer, downloaded files manager, history clearing, & local file deletion.',
      'icon': Icons.folder_special_rounded,
      'color': Colors.blueGrey,
      'widget': StorageHistoryTemplatePage(),
    },
    {
      'id': '11',
      'title': 'Notifications & Drawer Actions',
      'subtitle':
          'Interactive Android Notification Drawer buttons (Pause, Resume, Cancel, & Retry).',
      'icon': Icons.notifications_active_rounded,
      'color': Colors.pink,
      'widget': NotificationCustomUiTemplatePage(
        sampleUrl:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      ),
    },
  ];

  void _openTemplateScreen(Widget templateWidget) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => templateWidget));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Templates Catalog'),
        elevation: 2,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templateCatalog.length,
        itemBuilder: (context, index) {
          final item = _templateCatalog[index];
          final color = item['color'] as Color;
          final icon = item['icon'] as IconData;
          final widgetPage = item['widget'] as Widget;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () => _openTemplateScreen(widgetPage),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${item['id']}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
