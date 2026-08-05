import 'package:flutter/material.dart';
import 'package:native_download_manager/native_download_manager.dart';

/// Template 07: Network & Power Constraint Manager
class ConstraintsTemplatePage extends StatefulWidget {
  final String title;
  final String? sampleUrl;
  final String? sampleFileName;
  final bool initialWifiOnly;
  final bool initialChargingOnly;
  final bool initialBatteryNotLow;

  const ConstraintsTemplatePage({
    super.key,
    this.title = '07. Constraints Manager',
    this.sampleUrl,
    this.sampleFileName,
    this.initialWifiOnly = true,
    this.initialChargingOnly = false,
    this.initialBatteryNotLow = false,
  });

  @override
  State<ConstraintsTemplatePage> createState() => _ConstraintsTemplatePageState();
}

class _ConstraintsTemplatePageState extends State<ConstraintsTemplatePage> {
  late bool _wifiOnly;
  late bool _chargingOnly;
  late bool _batteryNotLow;

  @override
  void initState() {
    super.initState();
    _wifiOnly = widget.initialWifiOnly;
    _chargingOnly = widget.initialChargingOnly;
    _batteryNotLow = widget.initialBatteryNotLow;
  }

  void _downloadWithConstraints() async {
    final constraints = <NetworkConstraint>[];
    if (_wifiOnly) constraints.add(NetworkConstraint.wifiOnly);
    if (_chargingOnly) constraints.add(NetworkConstraint.chargingOnly);
    if (_batteryNotLow) constraints.add(NetworkConstraint.cellularRestricted);

    await NativeDownloadManager.download(
      url: widget.sampleUrl ?? 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      fileName: widget.sampleFileName ?? 'constrained_media.mp4',
      networkConstraints: constraints,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download scheduled with system constraints!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('WiFi Only Download'),
                      subtitle: const Text('Pauses automatically if device switches to cellular network'),
                      value: _wifiOnly,
                      onChanged: (v) => setState(() => _wifiOnly = v),
                    ),
                    SwitchListTile(
                      title: const Text('Charging Only Download'),
                      subtitle: const Text('Executes only when charger is plugged in'),
                      value: _chargingOnly,
                      onChanged: (v) => setState(() => _chargingOnly = v),
                    ),
                    SwitchListTile(
                      title: const Text('Battery Not Low'),
                      subtitle: const Text('Pauses when battery drops below 20%'),
                      value: _batteryNotLow,
                      onChanged: (v) => setState(() => _batteryNotLow = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _downloadWithConstraints,
                      icon: const Icon(Icons.network_check_rounded),
                      label: const Text('Download with Constraints'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
