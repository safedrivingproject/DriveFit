import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OWM_KEY', obfuscate: true)
  static final owmApiKey = _Env.owmApiKey;
}