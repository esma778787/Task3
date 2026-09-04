import 'package:flame/components.dart'; // Vector2, TextComponent, PositionComponent
import 'package:flame/game.dart';       // FlameGame sınıfı
import 'package:flutter/material.dart'; // Color gibi Flutter widget’ları
import 'package:erasmus_simulasyon/models/simulation_data.dart'; // Kullanıcı verisi için model

// Karakterinizi temsil eden component
class PlayerCharacter extends PositionComponent {
  final Color color;
  Vector2 initialPosition;
  int currentLevel = 0;
  late TextComponent levelText;

  PlayerCharacter({required this.color, required this.initialPosition})
      : super(
          size: Vector2.all(64),
          position: initialPosition,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Karakterin seviyesini göstermek için metin bileşeni
    levelText = TextComponent(
      text: '$currentLevel',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
    add(levelText);
  }

  void climb() {
    currentLevel++;
    position.y -= 50; // Her adımda yukarı çık
    levelText.text = '$currentLevel';
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
  }
}

// Dağ arka planı bileşeni
class MountainBackground extends Component with HasGameRef<FlameGame> {
  final Paint _paint = Paint()..color = Colors.brown.shade800;
  final Paint _snowPaint = Paint()..color = Colors.white;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, gameRef.size.y / 2, gameRef.size.x, gameRef.size.y / 2),
      _paint,
    );
    final Path snowPath = Path()
      ..moveTo(gameRef.size.x / 2, gameRef.size.y / 2 - 200)
      ..lineTo(gameRef.size.x / 2 - 100, gameRef.size.y / 2)
      ..lineTo(gameRef.size.x / 2 + 100, gameRef.size.y / 2)
      ..close();
    canvas.drawPath(snowPath, _snowPaint);
  }
}

// Ana oyun sınıfı
class MountainClimbGame extends FlameGame {
  late PlayerCharacter playerCharacter;
  late final SimulationData simulationData; // Oyun içinde kullanılabilir

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Arka plan ekle
    add(MountainBackground());

    // Oyuncu karakterini oluştur ve ekle
    playerCharacter = PlayerCharacter(
      color: Colors.blueAccent,
      initialPosition: Vector2(size.x / 2, size.y - 100),
    );
    add(playerCharacter);

    // Kamera karakteri takip etsin
    camera.follow(playerCharacter);
  }
}
