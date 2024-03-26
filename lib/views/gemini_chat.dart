import 'dart:typed_data';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/utils/secrets.dart';
import 'package:voice_assistant/views/animated_text.dart';
import 'package:voice_assistant/views/audio_control.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({
    super.key,
  });

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Assistant'),
      ),
      body: const ChatWidget(),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    super.key,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _generatedContent =
      <({Image? image, String? text, bool fromUser})>[];
  bool _loading = false;

  final speechToText = SpeechToText();
  String lastWords = '';

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: geminiKey);
    _visionModel =
        GenerativeModel(model: 'gemini-pro-vision', apiKey: geminiKey);
    _chat = _model.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    print('ssheeee');
    setState(() {
      lastWords = result.recognizedWords;
      _textController.text = result.recognizedWords;
    });
    print('heeee');
    print(lastWords);
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      suffixIcon: FittedBox(
        child: Row(
          children: [
            _textController.text.isEmpty
                ? GestureDetector(
                    onTap: () async {
                      if (await speechToText.hasPermission &&
                          speechToText.isNotListening) {
                        print('hello');
                        await startListening();
                      } else if (speechToText.isListening) {
                        await stopListening();
                      } else {
                        print('No permission');
                      }
                    },
                    child: Icon(
                      speechToText.isListening ? Icons.stop : Icons.mic,
                    ))
                : const SizedBox.shrink(),
            IconButton(
              onPressed: !_loading
                  ? () async {
                      _sendImagePrompt(_textController.text);
                    }
                  : null,
              icon: Icon(
                Icons.image,
                color: _loading
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(25),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: ListView.builder(
            controller: _scrollController,
            itemBuilder: (context, idx) {
              final content = _generatedContent[idx];
              return MessageWidget(
                text: content.text,
                image: content.image,
                isFromUser: content.fromUser,
              );
            },
            itemCount: _generatedContent.length,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                // const SizedBox.square(dimension: 15),

                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      _sendChatMessage(_textController.text);
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendImagePrompt(String message) async {
    setState(() {
      _loading = true;
    });
    try {
      ByteData catBytes = await rootBundle.load('assets/images/cat.jpg');
      ByteData sconeBytes = await rootBundle.load('assets/images/scones.jpg');
      final content = [
        Content.multi([
          TextPart(message),
          // The only accepted mime types are image/*.
          DataPart('image/jpeg', catBytes.buffer.asUint8List()),
          DataPart('image/jpeg', sconeBytes.buffer.asUint8List()),
        ])
      ];
      _generatedContent.add((
        image: Image.asset("assets/images/cat.jpg"),
        text: message,
        fromUser: true
      ));
      _generatedContent.add((
        image: Image.asset("assets/images/scones.jpg"),
        text: null,
        fromUser: true
      ));

      var response = await _visionModel.generateContent(content);
      var text = response.text;
      _generatedContent.add((image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      _generatedContent.add((image: null, text: message, fromUser: true));
      final response = await _chat.sendMessage(
        Content.text(message),
      );
      final text = response.text;
      _generatedContent.add((image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
    final flutterTts = FlutterTts();

      Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }


  @override
  void dispose() {
   flutterTts.stop();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Stack(
          children: [
            Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: widget.isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  if (widget.text case final text?)
                    widget.isFromUser
                        ? MarkdownBody(data: text)
                        : MyAnimatedText(text: text),
                  if (widget.image case final image?) image,
                ])),
            widget.isFromUser
                ? const SizedBox.shrink()
                : Positioned(
                    bottom: 10,
                    right: 0,
                    child: Row(
                      children: [
                        FloatingAudioControl(text: widget.text!,),
                        GestureDetector(
                          onTap: (){
                        
                            systemSpeak(widget.text!);
                            
                          },
                          child: Icon(
                            Icons.volume_up,
                            // color: Colors.red,
                          ),
                        ),
                      ],
                    )),
          ],
        )),
      ],
    );
  }
}
