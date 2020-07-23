import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opus_flutter/opus_dart.dart';
import 'package:audiostream/audiostream.dart';

void main() {
  initOpus();
  Audiostream.initialize(
    rate: 48000,
    channels: 2,
    bufferSeconds: 0,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future play() async {
    // sample.raw is 48000 pcm_s16le
    print('sending from sample.raw');
    var data = await rootBundle.load('assets/sample-48000-s16le.raw');
    await Audiostream.write(data.buffer);

    print('waiting 2 seconds');
    await Future.delayed(Duration(seconds: 2));
    var decoder = SimpleOpusDecoder(sampleRate: 48000, channels: 2);
    var encoder = SimpleOpusEncoder(
      sampleRate: 48000,
      channels: 2,
      application: Application.audio,
    );

    // will encode the audio data, decode the audio,
    // and put it into a pcmdata array for later playing
    var offset = 0;
    var opusFrameSize = 1920; // in samples
    List<int> pcmdata = [];
    Int16List samples = data.buffer.asInt16List();
    while ((samples.length - offset) >= opusFrameSize) {
      var toEncode = samples.sublist(offset, offset + opusFrameSize);
      var packet = encoder.encode(input: toEncode);
      pcmdata.addAll(decoder.decode(input: packet));
      offset += opusFrameSize;
    }
    await Audiostream.write(Int16List.fromList(pcmdata).buffer);
    encoder.destroy();
    decoder.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: RaisedButton(
        onPressed: () => play(),
        child: Text('Play Test'),
      ),
    ));
  }
}
