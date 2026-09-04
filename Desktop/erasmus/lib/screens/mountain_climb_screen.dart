import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MountainClimbScreen extends StatelessWidget {
  const MountainClimbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mountain Climb Challenge')),
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: MountainGame())),
          const Positioned(
            top: 16,
            left: 16,
            child: Text('Dağa Tırmanış Başladı!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class MountainGame extends FlameGame {
  late SpriteAnimationComponent player;
  double _maxY = 0;

  @override
  Future<void> onLoad() async {
    final image = await images.load('Female_spritesheet_run.png');
    final animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 10,
        stepTime: 0.15,
        textureSize: Vector2(45, 411),
      ),
    );

    player = SpriteAnimationComponent()
      ..animation = animation
      ..size = Vector2(45, 90)
      ..position = Vector2(size.x / 2 - 22, size.y);

    add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    player.position.y -= 40 * dt; // tırmanma efekti
    if (player.position.y <= _maxY) {
      player.position.y = _maxY;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _maxY = 20; // ekranın tepe noktası
  }
}
