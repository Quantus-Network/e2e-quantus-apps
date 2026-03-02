// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:polkadart/scale_codec.dart' as _i1;

class Tuple5<T0, T1, T2, T3, T4> {
  const Tuple5(
    this.value0,
    this.value1,
    this.value2,
    this.value3,
    this.value4,
  );

  final T0 value0;

  final T1 value1;

  final T2 value2;

  final T3 value3;

  final T4 value4;
}

class Tuple5Codec<T0, T1, T2, T3, T4>
    with _i1.Codec<Tuple5<T0, T1, T2, T3, T4>> {
  const Tuple5Codec(
    this.codec0,
    this.codec1,
    this.codec2,
    this.codec3,
    this.codec4,
  );

  final _i1.Codec<T0> codec0;

  final _i1.Codec<T1> codec1;

  final _i1.Codec<T2> codec2;

  final _i1.Codec<T3> codec3;

  final _i1.Codec<T4> codec4;

  @override
  void encodeTo(
    Tuple5<T0, T1, T2, T3, T4> tuple,
    _i1.Output output,
  ) {
    codec0.encodeTo(tuple.value0, output);
    codec1.encodeTo(tuple.value1, output);
    codec2.encodeTo(tuple.value2, output);
    codec3.encodeTo(tuple.value3, output);
    codec4.encodeTo(tuple.value4, output);
  }

  @override
  Tuple5<T0, T1, T2, T3, T4> decode(_i1.Input input) {
    return Tuple5(
      codec0.decode(input),
      codec1.decode(input),
      codec2.decode(input),
      codec3.decode(input),
      codec4.decode(input),
    );
  }

  @override
  int sizeHint(Tuple5<T0, T1, T2, T3, T4> tuple) {
    int size = 0;
    size += codec0.sizeHint(tuple.value0);
    size += codec1.sizeHint(tuple.value1);
    size += codec2.sizeHint(tuple.value2);
    size += codec3.sizeHint(tuple.value3);
    size += codec4.sizeHint(tuple.value4);
    return size;
  }
}
