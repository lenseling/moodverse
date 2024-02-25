import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

const appScheme = 'flutterdemo';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'MoodVerse',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0x5302E3)),
          textTheme: GoogleFonts.latoTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  final _openAI = OpenAI.instance
      .build(token: "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");

  var current = "";

  Future<void> getNext() async {
    await getPrompt(); // Fetch the prompt before updating the current variable
    notifyListeners();
  }

  Future<void> getPrompt() async {
    final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: [
          {
            "role": "user",
            "content":
                "generate a 1 journaling prompt to promote emotional wellness."
          }
        ],
        maxToken: 200);
    final response = await _openAI.onChatCompletion(request: request);
    print("Response: $response");
    for (var element in response!.choices) {
      if (element.message != null) {
        current = element.message!.content;
      }
    }
  }

  var favorites = <String>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  var journalEntries = <JournalEntry>[];

  void addJournalEntry(JournalEntry entry) {
    journalEntries.add(entry);
    notifyListeners();
  }

  void removeJournalEntry(int index) {
    journalEntries.removeAt(index);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = LandingPage();
      case 1:
        page = FavoritesPage();
      case 2:
        page = MyJournalPage();
      case 3:
        page = GeneratorPage();
      case 4:
        page = SettingsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.create),
                    label: Text('My Journal'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.help),
                    label: Text('Prompts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  _GeneratorPageState createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  @override
  void initState() {
    super.initState();
    // Fetch the prompt when the page is first loaded
    context.read<MyAppState>().getNext();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pair.isNotEmpty ? pair : "Loading prompt...",
            textAlign: TextAlign.center,
            style: TextStyle(
              // Text color
              fontSize: 18, // Font size
              fontWeight: FontWeight.bold, // Font weight
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

// ...

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair),
          ),
      ],
    );
  }
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 130.0, // Only top padding is set to 20.0
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
        ),
        child: Column(
          children: [
            Image.asset(
              './assets/logo-transparent.png',
              width: 300,
              height: 300,
              // Adjust width and height as needed
            ),
            Text(
              'Your mood, your universe <3',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Add your sign-in logic here
              },
              child: Text('Sign In'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class MyJournalPage extends StatefulWidget {
  @override
  _MyJournalPageState createState() => _MyJournalPageState();
}

class _MyJournalPageState extends State<MyJournalPage> {
  String _journalEntry = '';
  List<JournalEntry> _savedEntries = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            tabs: [
              Tab(text: 'Write Entry'),
              Tab(text: 'Saved Entries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'My Journal - ${DateTime.now().toString().substring(0, 10)}',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: SingleChildScrollView(
                          child: TextField(
                            maxLines: null,
                            onChanged: (text) {
                              setState(() {
                                _journalEntry = text;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Write your journal entry here...',
                              contentPadding: EdgeInsets.all(16.0),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _savedEntries.add(JournalEntry(
                            entry: _journalEntry, date: DateTime.now()));
                        _journalEntry = '';
                      });
                    },
                    child: Text('Save Entry'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/astrobear.png',
                          width: 100,
                          height: 100,
                        ),
                        Text(
                          'How was your day?',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SavedEntriesTab(savedEntries: _savedEntries),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 217, 206, 243),
      ),
    );
  }
}

class SavedEntriesTab extends StatefulWidget {
  final List<JournalEntry> savedEntries;

  SavedEntriesTab({required this.savedEntries});

  @override
  _SavedEntriesTabState createState() => _SavedEntriesTabState();
}

class _SavedEntriesTabState extends State<SavedEntriesTab> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.savedEntries.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(widget.savedEntries[index].entry),
          subtitle: Text(
              'Date: ${widget.savedEntries[index].date.toString().substring(0, 10)}'),
          trailing: IconButton(
            icon: Icon(widget.savedEntries[index].isFavorite
                ? Icons.favorite
                : Icons.favorite_border),
            onPressed: () {
              setState(() {
                widget.savedEntries[index].toggleFavorite();
              });
            },
          ),
        );
      },
    );
  }
}

class JournalEntry {
  final String entry;
  final DateTime date;
  bool isFavorite;

  JournalEntry(
      {required this.entry, required this.date, this.isFavorite = false});

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class colorPreset {
  final Color color;
  final String presetName;

  colorPreset({required this.color, required this.presetName});
}

class _SettingsPageState extends State<SettingsPage> {
  // Define variables to store user selections
  colorPreset? selectedColor;
  String? selectedFont;

  // Define a list of colors and fonts for dropdown menus

  List<colorPreset> colors = [
    colorPreset(color: Colors.red, presetName: "Red"),
    colorPreset(color: Colors.blue, presetName: "Blue"),
    colorPreset(color: Colors.green, presetName: "Green"),
    colorPreset(color: Colors.yellow, presetName: "Yellow"),
  ];

  List<String> fonts = [
    'Arial',
    'Roboto',
    'Times New Roman',
    'Courier New',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Background Color:',
              style: TextStyle(fontSize: 18),
            ),
            DropdownButton<colorPreset>(
              value: selectedColor,
              onChanged: (colorPreset? color) {
                setState(() {
                  selectedColor = color;
                });
              },
              items: colors.map((colorPreset color) {
                return DropdownMenuItem<colorPreset>(
                  value: color,
                  child: Text(color.presetName),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'Select Text Font:',
              style: TextStyle(fontSize: 18),
            ),
            DropdownButton<String>(
              value: selectedFont,
              onChanged: (String? font) {
                setState(() {
                  selectedFont = font;
                });
              },
              items: fonts.map((String font) {
                return DropdownMenuItem<String>(
                  value: font,
                  child: Text(font),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Apply selected settings (e.g., update background color and text font)
                // You can implement this logic based on your app's requirements
              },
              child: Text('Apply Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
