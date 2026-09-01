import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/utils/ascii_utils.dart';
import 'spam_ml_feature_schema.dart';

enum ModelHealth {
  uninitialized,
  gbtActive,
  lrActive,
  degradedToLr,
  parseFailed,
  defaults,
}

class GbtTree {
  final Int32List feature;
  final Float64List threshold;
  final Int32List childrenLeft;
  final Int32List childrenRight;
  final Float64List value;

  GbtTree({
    required this.feature,
    required this.threshold,
    required this.childrenLeft,
    required this.childrenRight,
    required this.value,
  });

  double evaluate(Float64List features) {
    int node = 0;
    while (true) {
      final fIdx = feature[node];
      if (fIdx == -2) {
        // Leaf node
        return value[node];
      }
      final thresh = threshold[node];
      if (features[fIdx] <= thresh) {
        node = childrenLeft[node];
      } else {
        node = childrenRight[node];
      }
      if (node < 0 || node >= feature.length) {
        return 0.0;
      }
    }
  }
}

class SpamMLScorer {
  static final SpamMLScorer instance = SpamMLScorer();

  static const Set<String> tollFreePrefixes = {'800', '888', '877', '866', '855', '844', '833'};
  static const Set<String> highSpamNpas = {
    '800', '888', '877', '866', '855', '844', '833',
    '202', '213', '310', '323', '347', '404', '415',
    '512', '617', '646', '702', '713', '718', '786',
    '813', '832', '917', '929',
  };

  static const Set<String> highSpamVoipNpanxx = {
    '202555', '213226', '213555', '310555', '310400',
    '323555', '347555', '404555', '404430', '415555',
    '503555', '512555', '617555', '646555', '702555',
    '713555', '718555', '786555', '813555', '832555',
    '917555', '929555', '206455', '312454', '415523',
    '617286', '646397', '713291', '720420', '720660',
  };

  static const int referenceNpa = 312;

  bool _useGbt = false;
  List<GbtTree>? _gbtTrees;
  double _gbtLearningRate = 0.1;
  double _gbtInitialScore = 0.0;
  Float64List? _lrWeights;
  double _lrBias = -2.5;
  double _threshold = 0.7;
  ModelHealth _health = ModelHealth.uninitialized;

  ModelHealth get health => _health;
  double get threshold => _threshold;

  SpamMLScorer() {
    _loadDefaultModel();
  }

  void _loadDefaultModel() {
    _useGbt = false;
    _gbtTrees = null;
    _lrWeights = Float64List.fromList([
      1.2, 0.8, 1.8, 1.5, 0.6, 2.1, 1.4, 0.9, 2.0, 1.2,
      1.8, 0.5, 1.0, 1.5, 0.8, 0.3, 0.3, 0.6, 1.0, 0.1,
    ]);
    _lrBias = -2.5;
    _threshold = 0.7;
    _health = ModelHealth.defaults;
  }

  Future<void> loadBundledAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/spam_model_weights.json');
      loadFromJson(jsonString);
    } catch (_) {
      _loadDefaultModel();
    }
  }

  bool loadFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final int version = data['version'] as int? ?? 2;
      final String modelType = data['model_type'] as String? ?? '';
      final double thresh = (data['threshold'] as num?)?.toDouble() ?? 0.7;
      final double initScore = (data['initial_score'] as num?)?.toDouble() ?? 0.0;

      _threshold = thresh;

      if (version >= 3 && modelType == 'gbt' && data['trees'] is List) {
        final treeList = <GbtTree>[];
        for (final rawTree in data['trees'] as List) {
          final t = rawTree as Map<String, dynamic>;
          final featList = (t['feature'] as List).map((e) => (e as num).toInt()).toList();
          final threshList = (t['threshold'] as List).map((e) => (e as num).toDouble()).toList();
          final leftList = (t['children_left'] as List).map((e) => (e as num).toInt()).toList();
          final rightList = (t['children_right'] as List).map((e) => (e as num).toInt()).toList();
          final valList = (t['value'] as List).map((e) => (e as num).toDouble()).toList();

          treeList.add(GbtTree(
            feature: Int32List.fromList(featList),
            threshold: Float64List.fromList(threshList),
            childrenLeft: Int32List.fromList(leftList),
            childrenRight: Int32List.fromList(rightList),
            value: Float64List.fromList(valList),
          ));
        }

        _useGbt = true;
        _gbtTrees = treeList;
        _gbtLearningRate = (data['learning_rate'] as num?)?.toDouble() ?? 0.1;
        _gbtInitialScore = initScore;
        _health = ModelHealth.gbtActive;
        return true;
      }

      // Fallback to LR
      if (data['fallback_weights'] is Map) {
        final fbMap = data['fallback_weights'] as Map<String, dynamic>;
        final weights = <double>[];
        for (final name in SpamMLFeatureSchema.featureNames) {
          weights.add((fbMap[name] as num?)?.toDouble() ?? 0.0);
        }
        _useGbt = false;
        _lrWeights = Float64List.fromList(weights);
        _lrBias = (data['fallback_bias'] as num?)?.toDouble() ?? -2.5;
        _health = version >= 3 ? ModelHealth.degradedToLr : ModelHealth.lrActive;
        return true;
      }

      _loadDefaultModel();
      _health = ModelHealth.parseFailed;
      return false;
    } catch (_) {
      _loadDefaultModel();
      _health = ModelHealth.parseFailed;
      return false;
    }
  }

  Float64List extractFeatures(String number, [int? hourOfDay]) {
    final digits = AsciiUtils.filterAsciiDigitsLast(number, 10);
    final is10Digit = digits.length == 10;

    final npa = is10Digit ? digits.substring(0, 3) : '';
    final nxx = is10Digit ? digits.substring(3, 6) : '';
    final sub = is10Digit ? digits.substring(6, 10) : '';
    final npanxx = is10Digit ? digits.substring(0, 6) : '';

    final tollFree = tollFreePrefixes.contains(npa) ? 1.0 : 0.0;
    final highSpamNpa = highSpamNpas.contains(npa) ? 1.0 : 0.0;
    final voipRange = highSpamVoipNpanxx.contains(npanxx) ? 1.0 : 0.0;

    final plusOnePrefix = number.trim().startsWith('+1') ? 1.0 : 0.0;
    final shortNumber = AsciiUtils.filterAsciiDigits(number).length < 7 ? 1.0 : 0.0;

    if (!is10Digit) {
      final hour = (hourOfDay ?? DateTime.now().hour).clamp(0, 23);
      final timeAngle = 2.0 * pi * hour / 24.0;
      return Float64List.fromList([
        tollFree, highSpamNpa, voipRange, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, sin(timeAngle), cos(timeAngle), 0.0,
        shortNumber, plusOnePrefix,
      ]);
    }

    final digitCounts = <String, int>{};
    for (int i = 0; i < 10; i++) {
      final ch = digits[i];
      digitCounts[ch] = (digitCounts[ch] ?? 0) + 1;
    }
    final maxFreq = digitCounts.values.reduce(max);
    final repeatedRatio = maxFreq / 10.0;

    int seqAsc = 0;
    int seqDesc = 0;
    for (int i = 0; i < 9; i++) {
      final curr = digits.codeUnitAt(i) - 0x30;
      final next = digits.codeUnitAt(i + 1) - 0x30;
      if (next == curr + 1) seqAsc++;
      if (next == curr - 1) seqDesc++;
    }
    final seqAscRatio = seqAsc / 9.0;
    final seqDescRatio = seqDesc / 9.0;

    final allSame = digitCounts.length == 1 ? 1.0 : 0.0;
    final is555 = nxx == '555' ? 1.0 : 0.0;
    final last4Zero = sub == '0000' ? 1.0 : 0.0;

    final invalidNxx = (nxx.startsWith('0') || nxx.startsWith('1')) ? 1.0 : 0.0;
    final subAllSame = (sub.isNotEmpty && sub.runes.toSet().length == 1) ? 1.0 : 0.0;

    final evenSet = {digits[0], digits[2], digits[4], digits[6], digits[8]};
    final oddSet = {digits[1], digits[3], digits[5], digits[7], digits[9]};
    final alternating = (evenSet.length == 1 && oddSet.length == 1 && evenSet.first != oddSet.first) ? 1.0 : 0.0;

    final nxxInt = int.tryParse(nxx) ?? 0;
    final nxxBelow200 = nxxInt < 200 ? 1.0 : 0.0;
    final lowEntropy = digitCounts.length < 4 ? 1.0 : 0.0;

    int subAscCount = 0;
    int subDescCount = 0;
    for (int i = 0; i < 3; i++) {
      final c = sub.codeUnitAt(i) - 0x30;
      final n = sub.codeUnitAt(i + 1) - 0x30;
      if (n == c + 1) subAscCount++;
      if (n == c - 1) subDescCount++;
    }
    final subSeq = (subAscCount == 3 || subDescCount == 3) ? 1.0 : 0.0;

    final hour = (hourOfDay ?? DateTime.now().hour).clamp(0, 23);
    final timeAngle = 2.0 * pi * hour / 24.0;
    final timeSin = sin(timeAngle);
    final timeCos = cos(timeAngle);

    final callerNpaInt = int.tryParse(npa) ?? 0;
    final geoDist = (callerNpaInt - referenceNpa).abs() > 200 ? 1.0 : 0.0;

    return Float64List.fromList([
      tollFree,
      highSpamNpa,
      voipRange,
      repeatedRatio,
      seqAscRatio,
      allSame,
      is555,
      last4Zero,
      invalidNxx,
      subAllSame,
      alternating,
      seqDescRatio,
      nxxBelow200,
      lowEntropy,
      subSeq,
      timeSin,
      timeCos,
      geoDist,
      shortNumber,
      plusOnePrefix,
    ]);
  }

  double score(String number, [int? hourOfDay]) {
    final features = extractFeatures(number, hourOfDay);

    if (_useGbt && _gbtTrees != null && _gbtTrees!.isNotEmpty) {
      double raw = _gbtInitialScore;
      for (final tree in _gbtTrees!) {
        raw += _gbtLearningRate * tree.evaluate(features);
      }
      return _sigmoid(raw);
    }

    if (_lrWeights != null) {
      double dot = _lrBias;
      for (int i = 0; i < min(features.length, _lrWeights!.length); i++) {
        dot += features[i] * _lrWeights![i];
      }
      return _sigmoid(dot);
    }

    return 0.0;
  }

  bool isSpam(String number, [int? hourOfDay]) {
    return score(number, hourOfDay) >= _threshold;
  }

  int confidence(String number, [int? hourOfDay]) {
    return (score(number, hourOfDay) * 100.0).round().clamp(0, 100);
  }

  double _sigmoid(double x) {
    if (x >= 0) {
      return 1.0 / (1.0 + exp(-x));
    } else {
      final e = exp(x);
      return e / (1.0 + e);
    }
  }
}
