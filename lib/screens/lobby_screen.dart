import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_token.dart';
import '../services/room_service.dart';
import '../services/firebase_service.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String gameId;
  final PlayerToken player;

  const LobbyScreen({super.key, required this.gameId, required this.player});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final RoomService _roomService = RoomService();
  late Stream<DocumentSnapshot> roomStream;

  @override
  void initState() {
    super.initState();
    roomStream = _roomService.listenToRoom(widget.gameId);
  }

  void startGame() async {
    await _roomService.updateGameState(widget.gameId, {
      'started': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garrison Lobby')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final tokens = (data['tokens'] as List)
              .map((e) => PlayerToken.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          final started = data['started'] ?? false;

          if (started) {
            return GameScreen(gameId: widget.gameId, playerToken: widget.player);
          }

          final isHost = data['createdBy'] == FirebaseService.currentUserId;

          return Column(
            children: [
              const SizedBox(height: 20),
              Text('Waiting for players...', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: tokens.length,
                  itemBuilder: (_, index) {
                    final t = tokens[index];
                    final isMe = t.id == widget.player.id;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: t.color),
                      title: Text("Player ${index + 1}"),
                      subtitle: Text(isMe ? "You - ${t.roles.join()}" : t.roles.join()),
                      trailing: isMe
                          ? const Icon(Icons.visibility, color: Colors.green)
                          : const Icon(Icons.hourglass_empty),
                    );
                  },
                ),
              ),
              if (isHost)
                ElevatedButton.icon(
                  onPressed: startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Game"),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
