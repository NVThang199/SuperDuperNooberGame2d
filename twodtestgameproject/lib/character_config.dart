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

final dudeConfig = CharacterConfig(
  id: 'dude',
  displayName: 'Dude',
  basePath: 'characters/dude_monster',
  idleFile: 'Dude_Monster_Idle_4.png',
  walkFile: 'Dude_Monster_Walk_6.png',
  runFile: 'Dude_Monster_Run_6.png',
  walkRunPushDustFile: 'Walk_Run_Push_Dust_6.png',
  walkAttackFile: 'Dude_Monster_Walk+Attack_6.png',
  throwFile: 'Dude_Monster_Throw_4.png',
  attack1File: 'Dude_Monster_Attack1_4.png',
  attack2File: 'Dude_Monster_Attack2_6.png',
  jumpFile: 'Dude_Monster_Jump_8.png',
  pushFile: 'Dude_Monster_Push_6.png',
  deathFile: 'Dude_Monster_Death_8.png',
  hurtFile: 'Dude_Monster_Hurt_4.png',
  doubleJumpDustFile: 'Double_Jump_Dust_5.png',
  idleAmount: 4,
  walkAmount: 6,
  runAmount: 6,
  walkRunPushDustAmount: 6,
  walkAttackAmount: 6,
  throwAmount: 4,
  attack1Amount: 4,
  attack2Amount: 6,
  jumpAmount: 8,
  pushAmount: 6,
  deathAmount: 8,
  hurtAmount: 4,
  doubleJumpDustAmount: 5,
  textureSize: _ts,
  idleStepTime: 0.2,
  walkStepTime: 0.1,
  runStepTime: 0.08,
  walkRunPushDustStepTime: 0.1,
  walkAttackStepTime: 0.1,
  throwStepTime: 0.1,
  attack1StepTime: 0.12,
  attack2StepTime: 0.1,
  jumpStepTime: 0.1,
  pushStepTime: 0.12,
  deathStepTime: 0.12,
  hurtStepTime: 0.1,
  doubleJumpDustStepTime: 0.08,
);

final owletConfig = CharacterConfig(
  id: 'owlet',
  displayName: 'Owlet',
  basePath: 'characters/owlet_monster',
  idleFile: 'Owlet_Monster_Idle_4.png',
  walkFile: 'Owlet_Monster_Walk_6.png',
  runFile: 'Owlet_Monster_Run_6.png',
  walkRunPushDustFile: 'Walk_Run_Push_Dust_6.png',
  walkAttackFile: 'Owlet_Monster_Walk+Attack_6.png',
  throwFile: 'Owlet_Monster_Throw_4.png',
  attack1File: 'Owlet_Monster_Attack1_4.png',
  attack2File: 'Owlet_Monster_Attack2_6.png',
  jumpFile: 'Owlet_Monster_Jump_8.png',
  pushFile: 'Owlet_Monster_Push_6.png',
  deathFile: 'Owlet_Monster_Death_8.png',
  hurtFile: 'Owlet_Monster_Hurt_4.png',
  doubleJumpDustFile: 'Double_Jump_Dust_5.png',
  idleAmount: 4,
  walkAmount: 6,
  runAmount: 6,
  walkRunPushDustAmount: 6,
  walkAttackAmount: 6,
  throwAmount: 4,
  attack1Amount: 4,
  attack2Amount: 6,
  jumpAmount: 8,
  pushAmount: 6,
  deathAmount: 8,
  hurtAmount: 4,
  doubleJumpDustAmount: 5,
  textureSize: _ts,
  idleStepTime: 0.2,
  walkStepTime: 0.1,
  runStepTime: 0.08,
  walkRunPushDustStepTime: 0.1,
  walkAttackStepTime: 0.1,
  throwStepTime: 0.1,
  attack1StepTime: 0.12,
  attack2StepTime: 0.1,
  jumpStepTime: 0.1,
  pushStepTime: 0.12,
  deathStepTime: 0.12,
  hurtStepTime: 0.1,
  doubleJumpDustStepTime: 0.08,
);

final pinkConfig = CharacterConfig(
  id: 'pink',
  displayName: 'Pink',
  basePath: 'characters/pink_monster',
  idleFile: 'Pink_Monster_Idle_4.png',
  walkFile: 'Pink_Monster_Walk_6.png',
  runFile: 'Pink_Monster_Run_6.png',
  walkRunPushDustFile: 'Walk_Run_Push_Dust_6.png',
  walkAttackFile: 'Pink_Monster_Walk+Attack_6.png',
  throwFile: 'Pink_Monster_Throw_4.png',
  attack1File: 'Pink_Monster_Attack1_4.png',
  attack2File: 'Pink_Monster_Attack2_6.png',
  jumpFile: 'Pink_Monster_Jump_8.png',
  pushFile: 'Pink_Monster_Push_6.png',
  deathFile: 'Pink_Monster_Death_8.png',
  hurtFile: 'Pink_Monster_Hurt_4.png',
  doubleJumpDustFile: 'Double_Jump_Dust_5.png',
  idleAmount: 4,
  walkAmount: 6,
  runAmount: 6,
  walkRunPushDustAmount: 6,
  walkAttackAmount: 6,
  throwAmount: 4,
  attack1Amount: 4,
  attack2Amount: 6,
  jumpAmount: 8,
  pushAmount: 6,
  deathAmount: 8,
  hurtAmount: 4,
  doubleJumpDustAmount: 5,
  textureSize: _ts,
  idleStepTime: 0.2,
  walkStepTime: 0.1,
  runStepTime: 0.08,
  walkRunPushDustStepTime: 0.1,
  walkAttackStepTime: 0.1,
  throwStepTime: 0.1,
  attack1StepTime: 0.12,
  attack2StepTime: 0.1,
  jumpStepTime: 0.1,
  pushStepTime: 0.12,
  deathStepTime: 0.12,
  hurtStepTime: 0.1,
  doubleJumpDustStepTime: 0.08,
);

final allCharacters = [dudeConfig, owletConfig, pinkConfig];
