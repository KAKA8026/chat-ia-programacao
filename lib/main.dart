import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Chat IA',
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.dark),
        home: const ChatPage(),
      );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> convs = [];
  int cur = 0;
  final ctrl = TextEditingController();
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    final s = prefs!.getString('convs');
    if (s != null) convs = jsonDecode(s);
    if (convs.isEmpty) {
      newConv();
    } else {
      cur = 0;
      setState(() {});
    }
  }

  void save() => prefs?.setString('convs', jsonEncode(convs));

  void newConv() {
    convs.insert(0, {'title': 'Nova conversa', 'msgs': []});
    cur = 0;
    save();
    setState(() {});
  }

  void delConv(int i) {
    convs.removeAt(i);
    if (convs.isEmpty) {
      newConv();
      return;
    }
    cur = 0;
    save();
    setState(() {});
  }

  void send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    final c = convs[cur];
    final List msgs = c['msgs'];
    msgs.add({'role': 'user', 'text': t});
    if (msgs.length == 1) {
      c['title'] = t.length > 30 ? t.substring(0, 30) : t;
    }
    msgs.add({'role': 'ai', 'text': '(IA ainda nÃ£o conectada) VocÃª disse: $t'});
    ctrl.clear();
    save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List msgs = convs.isEmpty ? [] : convs[cur]['msgs'];
    return Scaffold(
      appBar: AppBar(title: const Text('Chat IA')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nova conversa'),
              onTap: () {
                newConv();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: convs.length,
                itemBuilder: (_, i) => ListTile(
                  selected: i == cur,
                  title: Text(convs[i]['title'], maxLines: 1),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => delConv(i)),
                  onTap: () {
                    setState(() => cur = i);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final user = m['role'] == 'user';
              return Align(
                alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: user ? Colors.indigo : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(m['text']),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder()),
                ),
              ),
              IconButton(onPressed: send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
