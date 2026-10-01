import 'dart:io';
import 'dart:math';

void main() {
  final random = Random();
  final output = StringBuffer();
  output.writeln(
    'id,name,image_path,rarity,type,hp_bonus,mp_bonus,stamina_bonus,dmg_bonus,defense_bonus,description',
  );

  const rarities = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
  const rarityWeights = [50, 25, 15, 8, 2];
  final cumulativeWeights = <int>[];
  var sum = 0;
  for (var w in rarityWeights) {
    sum += w;
    cumulativeWeights.add(sum);
  }

  String pickRarity() {
    final roll = random.nextInt(100);
    for (var i = 0; i < cumulativeWeights.length; i++) {
      if (roll < cumulativeWeights[i]) return rarities[i];
    }
    return rarities.last;
  }

  final statRanges = {
    'common': {
      'hp': [0, 5],
      'mp': [0, 3],
      'stamina': [0, 3],
      'dmg': [0, 3],
      'defense': [0, 2],
    },
    'uncommon': {
      'hp': [4, 10],
      'mp': [3, 7],
      'stamina': [3, 7],
      'dmg': [3, 7],
      'defense': [2, 5],
    },
    'rare': {
      'hp': [9, 15],
      'mp': [7, 12],
      'stamina': [7, 12],
      'dmg': [7, 12],
      'defense': [5, 8],
    },
    'epic': {
      'hp': [14, 20],
      'mp': [12, 18],
      'stamina': [12, 18],
      'dmg': [12, 18],
      'defense': [8, 12],
    },
    'legendary': {
      'hp': [19, 25],
      'mp': [17, 24],
      'stamina': [17, 24],
      'dmg': [17, 24],
      'defense': [12, 16],
    },
  };

  final types = ['weapon', 'armor', 'accessory', 'consumable'];

  for (var i = 1; i <= 2192; i++) {
    final rarity = pickRarity();
    final type = types[random.nextInt(types.length)];
    final ranges = statRanges[rarity]!;

    final hp =
        ranges['hp']![0] +
        random.nextInt(ranges['hp']![1] - ranges['hp']![0] + 1);
    final mp =
        ranges['mp']![0] +
        random.nextInt(ranges['mp']![1] - ranges['mp']![0] + 1);
    final stamina =
        ranges['stamina']![0] +
        random.nextInt(ranges['stamina']![1] - ranges['stamina']![0] + 1);
    final dmg =
        ranges['dmg']![0] +
        random.nextInt(ranges['dmg']![1] - ranges['dmg']![0] + 1);
    final defense =
        ranges['defense']![0] +
        random.nextInt(ranges['defense']![1] - ranges['defense']![0] + 1);

    final name = 'item_$i';
    final imagePath = 'assets/item/64x64/fc$i.png';
    final description = '$rarity $type';

    output.writeln(
      '$i,$name,$imagePath,$rarity,$type,$hp,$mp,$stamina,$dmg,$defense,$description',
    );
  }

  File('assets/item/items.csv').writeAsStringSync(output.toString());
  print('Generated 2192 items in assets/item/items.csv');
}
