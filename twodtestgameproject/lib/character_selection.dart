import 'package:flutter/material.dart';

import 'character_config.dart';
import 'main.dart';

class CharacterSelection extends StatelessWidget {
  const CharacterSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chọn nhân vật',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final isNarrow = c.maxWidth < 600;
                    final cards = allCharacters
                        .map((ch) => _CharacterCard(character: ch))
                        .toList();
                    if (isNarrow)
                      return Column(
                        children: cards
                            .map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: w,
                              ),
                            )
                            .toList(),
                      );
                    return Row(
                      children: cards
                          .map(
                            (w) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: w,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});
  final CharacterConfig character;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/images/${character.idlePath}';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GameScreen(character: character)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 96,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.error, size: 48),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                character.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(character.id, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
