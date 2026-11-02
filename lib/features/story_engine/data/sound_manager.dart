import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  /// Inicia o som ambiente de chuva em loop contínuo
  static Future<void> playAmbientRain() async {
    try {
      await _ambientPlayer.setSource(
        AssetSource('stories/audio/rain_ambient.wav'),
      );
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setVolume(0.4); // Volume ambiente suave
      await _ambientPlayer.resume();
    } catch (e) {
      // Ignora se o ficheiro de áudio ainda não tiver sido colocado nos assets
    }
  }

  /// Toca um efeito sonoro de clique ou máquina de escrever
  static Future<void> playClickEffect() async {
    try {
      await _sfxPlayer.play(
        AssetSource('stories/audio/typewriter_click.wav'),
      );
    } catch (e) {
      // Ignora se o ficheiro de áudio ainda não tiver sido colocado nos assets
    }
  }

  /// Para todos os sons (ao sair do ecrã ou reiniciar)
  static Future<void> stopAll() async {
    await _ambientPlayer.stop();
    await _sfxPlayer.stop();
  }
}
