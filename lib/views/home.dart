import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:voice_assistant/services/ai_service.dart';
import 'package:voice_assistant/views/featured.dart';
import 'package:voice_assistant/utils/pallete.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/views/gemini_chat.dart';
import 'package:voice_assistant/views/audio_control.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  String lastWords = '';

  final OpenAIService openAIService = OpenAIService();

  String? generatedContent;
  String? generatedImageUrl;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  final isListening = ValueNotifier<bool>(false);

  bool isLoading = false;

  Future<void> startListening() async {
    isListening.value = true;
    await speechToText.listen(onResult: onSpeechResult);
    // setState(() {});
  }

  Future<void> stopListening() async {
    isListening.value = false;
    await speechToText.stop();
    // setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
    print(lastWords);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BounceInDown(
          child: const Text('Ayodeji'),
        ),
        leading: const Icon(Icons.menu),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // virtual assistant picture
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Pallete.assistantCircleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    height: 123,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/virtualAssistant.png',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // chat bubble
            FadeInRight(
              child: Visibility(
                visible: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(
                    top: 30,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Pallete.borderColor,
                    ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topLeft: Radius.zero,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Good Morning, what task can I do for you?',
                      style: TextStyle(
                          fontFamily: 'Cera Pro',
                          color: Pallete.mainFontColor,
                          fontSize: 25),
                    ),
                  ),
                ),
              ),
            ),
            SlideInLeft(
              child: Visibility(
                visible: true,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(top: 10, left: 22),
                  child: const Text(
                    'Here are a few features',
                    style: TextStyle(
                      fontFamily: 'Cera Pro',
                      color: Pallete.mainFontColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // features list
            Visibility(
              visible: true,
              child: Column(
                children: [
                  SlideInLeft(
                    delay: const Duration(milliseconds: 3),
                    child: FeatureBox(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GeminiChatScreen()));
                      },
                      color: Pallete.fourthSuggestionBoxColor,
                      headerText: 'Google Gemini',
                      descriptionText:
                          'Chat to supercharge your ideas, write, learn, plan and more.',
                    ),
                  ),
                  SlideInLeft(
                    delay: const Duration(milliseconds: 3),
                    child:  FeatureBox(
                      onTap: (){
                        //  Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => const MyApp()));
                        
                      },
                      color: Pallete.firstSuggestionBoxColor,
                      headerText: 'ChatGPT',
                      descriptionText:
                          'A smarter way to stay organized and informed with ChatGPT',
                    ),
                  ),
                  SlideInLeft(
                    delay: const Duration(milliseconds: 3),
                    child: const FeatureBox(
                      color: Pallete.secondSuggestionBoxColor,
                      headerText: 'Dall-E',
                      descriptionText:
                          'Get inspired and stay creative with your personal assistant powered by Dall-E',
                    ),
                  ),
                  SlideInLeft(
                    delay: const Duration(milliseconds: 5),
                    child: const FeatureBox(
                      color: Pallete.thirdSuggestionBoxColor,
                      headerText: 'Smart Voice Assistant',
                      descriptionText:
                          'Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT',
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: ZoomIn(
        delay: const Duration(milliseconds: 5),
        child: FloatingActionButton(
            backgroundColor: Pallete.firstSuggestionBoxColor,
            onPressed: () async {
              if (await speechToText.hasPermission &&
                  speechToText.isNotListening) {
                print('hello');
                await startListening();
              } else if (speechToText.isListening) {
                final speech = await openAIService.isArtPromptAPI(lastWords);
                if (speech.contains('https')) {
                  generatedImageUrl = speech;
                  generatedContent = null;
                  setState(() {});
                } else {
                  generatedImageUrl = null;
                  generatedContent = speech;
                  setState(() {});
                  // await systemSpeak(speech);
                }
                await stopListening();
              } else {
                print('hellow');
                initSpeechToText();
              }
            },
            child: ValueListenableBuilder(
                valueListenable: isListening,
                builder: (context, value, child) {
                  return Icon(
                    value ? Icons.stop : Icons.mic,
                  );
                })),
      ),
    );
  }
}
