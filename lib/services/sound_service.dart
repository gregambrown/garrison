import 'package:audioplayers/audioplayers.dart';

class SoundFX {
  static final player = AudioPlayer();

  static void play(String filename) {
    player.play(AssetSource('sounds/$filename'));
  }
}
