import '../framework/framework.dart';

/// Main class for initializing the jaspr framework.
///
/// Call [Jaspr.initializeApp()] at the start of your app, before any calls to [runApp].
class Jaspr {
  static void initializeApp({JasprOptions options = const JasprOptions(), bool useIsolates = true}) {
    _options = options;
    _useIsolates = useIsolates;
  }

  static bool get isInitialized => _options != null;

  static JasprOptions get options => _options ?? JasprOptions();
  static JasprOptions? _options;

  static bool get useIsolates => _useIsolates;
  static bool _useIsolates = true;
}

/// Global options for configuring jaspr. DO NOT USE DIRECTLY.
/// Use the generated [defaultJasprOptions] instead.
class JasprOptions {
  const JasprOptions({this.targets = const {}});

  final Map<Type, ClientTarget> targets;
}

/// The target configuration for a @client component. DO NOT USE DIRECTLY.
/// Use the generated [defaultJasprOptions] instead.
class ClientTarget<T extends Component> {
  final String name;
  final Map<String, dynamic> Function(T component)? params;

  const ClientTarget(this.name, {this.params});

  Map<String, dynamic> encode(T component) {
    return {'name': name, if (params != null) 'params': params!(component)};
  }
}
