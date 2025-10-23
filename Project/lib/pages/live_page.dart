import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LivePage extends StatefulWidget {
  const LivePage({Key? key}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late final RtcEngine _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _micEnabled = true;
  bool _camEnabled = true;
  String? channelName;
  final String appId = "12731ad67ca947368f11a0d96c711694";

  @override
  void initState() {
    super.initState();
    _setChannelName();
  }

  Future<void> _setChannelName() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'guest';
    setState(() {
      channelName = "live_${username.toLowerCase()}";
    });
    await _initAgoraEngine();
  }

  Future<void> _initAgoraEngine() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _joined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUid = null);
        },
      ),
    );
  }

  Future<void> _startLive() async {
    if (channelName == null) return;
    await _engine.joinChannel(
      token: '', // kosong string jika tidak pakai token
      channelId: channelName!,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _stopLive() async {
    await _engine.leaveChannel();
    await _engine.release();
    setState(() {
      _joined = false;
      _remoteUid = null;
      _micEnabled = true;
      _camEnabled = true;
    });
  }

  void _toggleMic() {
    _micEnabled = !_micEnabled;
    _engine.muteLocalAudioStream(!_micEnabled);
    setState(() {});
  }

  void _toggleCam() {
    _camEnabled = !_camEnabled;
    _engine.muteLocalVideoStream(!_camEnabled);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Live Thrift"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: channelName == null
            ? const Center(child: CircularProgressIndicator())
            : _joined
            ? Stack(
          children: [
            if (_remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: channelName!),
                ),
              )
            else
              const Center(
                child: Text(
                  "Menunggu penonton...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            Positioned(
              top: 20,
              right: 20,
              width: 120,
              height: 160,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _controlButton(
                      Icons.mic,
                      _micEnabled ? Colors.green : Colors.red,
                      _toggleMic),
                  const SizedBox(width: 20),
                  _controlButton(
                      Icons.videocam,
                      _camEnabled ? Colors.green : Colors.red,
                      _toggleCam),
                  const SizedBox(width: 20),
                  _controlButton(Icons.stop, Colors.red, _stopLive),
                ],
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _stopLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Akhiri Live",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        )
            : Center(
          child: ElevatedButton.icon(
            onPressed: _startLive,
            icon: const Icon(Icons.live_tv),
            label: const Text("Mulai Live"),
          ),
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onPressed) {
    return ClipOval(
      child: Material(
        color: Colors.white.withOpacity(0.8),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
              width: 60, height: 60, child: Icon(icon, color: color, size: 30)),
        ),
      ),
    );
  }
}
