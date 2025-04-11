import 'package:flutter/material.dart';
import 'package:garrison/screens/singleplayer_gamescreen.dart';
import '../models/player_token.dart';
import '../services/room_service.dart';
import '../services/firebase_service.dart';
import 'choicecardeditor_screen.dart';
import 'lobby_screen.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _joining = false;
  final _roomService = RoomService();

  void createGame() async {
    final userId = FirebaseService.currentUserId;
    final name = _nameCtrl.text.trim().isEmpty ? "Player" : _nameCtrl.text.trim();

    final playerToken = PlayerToken(
      id: userId,
      displayName: name,
      color: Colors.primaries[userId.hashCode % Colors.primaries.length],
      roles: ['Good Youth'],
      position: 0,
    );

    final roomId = await _roomService.createRoom(userId, playerToken);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LobbyScreen(gameId: roomId, player: playerToken),
    ));
  }

  void joinGame() async {
    setState(() => _joining = true);

    final userId = FirebaseService.currentUserId;
    final name = _nameCtrl.text.trim().isEmpty ? "Player" : _nameCtrl.text.trim();

    final playerToken = PlayerToken(
      id: userId,
      displayName: name,
      color: Colors.primaries[userId.hashCode % Colors.primaries.length],
      roles: ['Good Youth'],
      position: 0,
    );

    final roomId = _codeCtrl.text.trim();

    await _roomService.joinRoom(roomId, playerToken);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LobbyScreen(gameId: roomId, player: playerToken),
    ));
  }

  void startSoloMode() {
    final userId = FirebaseService.currentUserId;
    final name = _nameCtrl.text.trim().isEmpty ? "Player" : _nameCtrl.text.trim();

    final playerToken = PlayerToken(
      id: userId,
      displayName: name,
      color: Colors.green,
      roles: ['Good Youth'],
      position: 0,
      isAI: false,
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SinglePlayerGameScreen(player: playerToken),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garrison Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Enter your name'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: createGame,
              child: const Text('Create Game Room'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: startSoloMode,
              icon: const Icon(Icons.person),
              label: const Text("Play Solo"),
            ),
            const Divider(height: 40),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Game Code'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _joining ? null : joinGame,
              child: const Text('Join Game'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("Admin: Edit Cards"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChoiceCardEditorScreen()),
              ),
            )
          ],
        ),
      ),
    );
  }
}
