import 'package:flame/components.dart';

class CharacterConfig {
  final String id;
  final String displayName;
  final String basePath;
  final String idleFile;
  final String walkFile;
  final String runFile;
  final String walkRunPushDustFile;
  final String walkAttackFile;
  final String throwFile;
  final String attack1File;
  final String attack2File;
  final String jumpFile;
  final String pushFile;
  final String deathFile;
  final String hurtFile;
  final String doubleJumpDustFile;
  final int idleAmount;
  final int walkAmount;
  final int runAmount;
  final int walkRunPushDustAmount;
  final int walkAttackAmount;
  final int throwAmount;
  final int attack1Amount;
  final int attack2Amount;
  final int jumpAmount;
  final int pushAmount;
  final int deathAmount;
  final int hurtAmount;
  final int doubleJumpDustAmount;
  final Vector2 textureSize;
  final double idleStepTime;
  final double walkStepTime;
  final double runStepTime;
  final double walkRunPushDustStepTime;
  final double walkAttackStepTime;
  final double throwStepTime;
  final double attack1StepTime;
  final double attack2StepTime;
  final double jumpStepTime;
  final double pushStepTime;
  final double deathStepTime;
  final double hurtStepTime;
  final double doubleJumpDustStepTime;

  const CharacterConfig({
    required this.id,
    required this.displayName,
    required this.basePath,
    required this.idleFile,
    required this.walkFile,
    required this.runFile,
    required this.walkRunPushDustFile,
    required this.walkAttackFile,
    required this.throwFile,
    required this.attack1File,
    required this.attack2File,
    required this.jumpFile,
    required this.pushFile,
    required this.deathFile,
    required this.hurtFile,
    required this.doubleJumpDustFile,
    required this.idleAmount,
    required this.walkAmount,
    required this.runAmount,
    required this.walkRunPushDustAmount,
    required this.walkAttackAmount,
    required this.throwAmount,
    required this.attack1Amount,
    required this.attack2Amount,
    required this.jumpAmount,
    required this.pushAmount,
    required this.deathAmount,
    required this.hurtAmount,
    required this.doubleJumpDustAmount,
    required this.textureSize,
    required this.idleStepTime,
    required this.walkStepTime,
    required this.runStepTime,
    required this.walkRunPushDustStepTime,
    required this.walkAttackStepTime,
    required this.throwStepTime,
    required this.attack1StepTime,
    required this.attack2StepTime,
    required this.jumpStepTime,
    required this.pushStepTime,
    required this.deathStepTime,
    required this.hurtStepTime,
    required this.doubleJumpDustStepTime,
  });

  String get idlePath => '$basePath/$idleFile';
  String get walkPath => '$basePath/$walkFile';
  String get runPath => '$basePath/$runFile';
  String get walkRunPushDustPath => '$basePath/$walkRunPushDustFile';
  String get walkAttackPath => '$basePath/$walkAttackFile';
  String get throwPath => '$basePath/$throwFile';
  String get attack1Path => '$basePath/$attack1File';
  String get attack2Path => '$basePath/$attack2File';
  String get jumpPath => '$basePath/$jumpFile';
  String get pushPath => '$basePath/$pushFile';
  String get deathPath => '$basePath/$deathFile';
  String get hurtPath => '$basePath/$hurtFile';
  String get doubleJumpDustPath => '$basePath/$doubleJumpDustFile';
}

final Vector2 _ts = Vector2(32, 32);

CharacterConfig createConfig(
  String id,
  String displayName,
  String basePath, {
  required int idleAmount,
  required int walkAmount,
  required int runAmount,
  required int walkRunPushDustAmount,
  required int walkAttackAmount,
  required int throwAmount,
  required int attack1Amount,
  required int attack2Amount,
  required int jumpAmount,
  required int pushAmount,
  required int deathAmount,
  required int hurtAmount,
  required int doubleJumpDustAmount,
  required double idleStepTime,
  required double walkStepTime,
  required double runStepTime,
  required double walkRunPushDustStepTime,
  required double walkAttackStepTime,
  required double throwStepTime,
  required double attack1StepTime,
  required double attack2StepTime,
  required double jumpStepTime,
  required double pushStepTime,
  required double deathStepTime,
  required double hurtStepTime,
  required double doubleJumpDustStepTime,
}) {
  final cap = id[0].toUpperCase() + id.substring(1);
  return CharacterConfig(
    id: id,
    displayName: displayName,
    basePath: basePath,
    idleFile: '${cap}_Monster_Idle_$idleAmount.png',
    walkFile: '${cap}_Monster_Walk_$walkAmount.png',
    runFile: '${cap}_Monster_Run_$runAmount.png',
    walkRunPushDustFile: 'Walk_Run_Push_Dust_$walkRunPushDustAmount.png',
    walkAttackFile: '${cap}_Monster_Walk+Attack_$walkAttackAmount.png',
    throwFile: '${cap}_Monster_Throw_$throwAmount.png',
    attack1File: '${cap}_Monster_Attack1_$attack1Amount.png',
    attack2File: '${cap}_Monster_Attack2_$attack2Amount.png',
    jumpFile: '${cap}_Monster_Jump_$jumpAmount.png',
    pushFile: '${cap}_Monster_Push_$pushAmount.png',
    deathFile: '${cap}_Monster_Death_$deathAmount.png',
    hurtFile: '${cap}_Monster_Hurt_$hurtAmount.png',
    doubleJumpDustFile: 'Double_Jump_Dust_$doubleJumpDustAmount.png',
    idleAmount: idleAmount,
    walkAmount: walkAmount,
    runAmount: runAmount,
    walkRunPushDustAmount: walkRunPushDustAmount,
    walkAttackAmount: walkAttackAmount,
    throwAmount: throwAmount,
    attack1Amount: attack1Amount,
    attack2Amount: attack2Amount,
    jumpAmount: jumpAmount,
    pushAmount: pushAmount,
    deathAmount: deathAmount,
    hurtAmount: hurtAmount,
    doubleJumpDustAmount: doubleJumpDustAmount,
    textureSize: _ts,
    idleStepTime: idleStepTime,
    walkStepTime: walkStepTime,
    runStepTime: runStepTime,
    walkRunPushDustStepTime: walkRunPushDustStepTime,
    walkAttackStepTime: walkAttackStepTime,
    throwStepTime: throwStepTime,
    attack1StepTime: attack1StepTime,
    attack2StepTime: attack2StepTime,
    jumpStepTime: jumpStepTime,
    pushStepTime: pushStepTime,
    deathStepTime: deathStepTime,
    hurtStepTime: hurtStepTime,
    doubleJumpDustStepTime: doubleJumpDustStepTime,
  );
}


CharacterConfig _create(String id, String displayName) => createConfig(
  id, displayName, 'characters/${id}_monster',
  idleAmount: 4, walkAmount: 6, runAmount: 6, walkRunPushDustAmount: 6,
  walkAttackAmount: 6, throwAmount: 4, attack1Amount: 4, attack2Amount: 6,
  jumpAmount: 8, pushAmount: 6, deathAmount: 8, hurtAmount: 4, doubleJumpDustAmount: 5,
  idleStepTime: 0.2, walkStepTime: 0.1, runStepTime: 0.08, walkRunPushDustStepTime: 0.1,
  walkAttackStepTime: 0.1, throwStepTime: 0.1, attack1StepTime: 0.12, attack2StepTime: 0.1,
  jumpStepTime: 0.1, pushStepTime: 0.12, deathStepTime: 0.12, hurtStepTime: 0.1, doubleJumpDustStepTime: 0.08,
);

final dudeConfig = _create('dude', 'Dude');
final owletConfig = _create('owlet', 'Owlet');
final pinkConfig = _create('pink', 'Pink');

final freeKnightConfig = CharacterConfig(
  id: 'free_knight',
  displayName: 'Free Knight',
  basePath: 'characters/free_knight',
  idleFile: '_Idle.png',
  walkFile: '_Run.png',
  runFile: '_Run.png',
  walkRunPushDustFile: 'Walk_Run_Push_Dust_6.png',
  walkAttackFile: 'Walk_Run_Push_Dust_6.png',
  throwFile: 'Walk_Run_Push_Dust_6.png',
  attack1File: '_Attack.png',
  attack2File: '_Attack2.png',
  jumpFile: '_Jump.png',
  pushFile: 'Walk_Run_Push_Dust_6.png',
  deathFile: '_DeathNoMovement.png',
  hurtFile: '_Hit.png',
  doubleJumpDustFile: 'Double_Jump_Dust_5.png',
  idleAmount: 10,
  walkAmount: 10,
  runAmount: 10,
  walkRunPushDustAmount: 6,
  walkAttackAmount: 6,
  throwAmount: 4,
  attack1Amount: 4,
  attack2Amount: 6,
  jumpAmount: 3,
  pushAmount: 6,
  deathAmount: 10,
  hurtAmount: 1,
  doubleJumpDustAmount: 5,
  textureSize: Vector2(120, 80),
  idleStepTime: 0.15,
  walkStepTime: 0.08,
  runStepTime: 0.08,
  walkRunPushDustStepTime: 0.1,
  walkAttackStepTime: 0.1,
  throwStepTime: 0.1,
  attack1StepTime: 0.1,
  attack2StepTime: 0.1,
  jumpStepTime: 0.1,
  pushStepTime: 0.12,
  deathStepTime: 0.1,
  hurtStepTime: 0.2,
  doubleJumpDustStepTime: 0.08,
);

