import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CurrentTime = DateTime Function();

final clockProvider = Provider<CurrentTime>((ref) => DateTime.now);

String greetingFor(DateTime time) {
  if (time.hour < 12) return 'Bom dia';
  if (time.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
