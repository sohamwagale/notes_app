// main.dart - The enhanced Flutter notes app

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  final _themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _themeNotifier.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _setThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _isDarkMode = isDark;
      _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _themeNotifier,
      builder: (context, ThemeMode themeMode, _) {
        return MaterialApp(
          title: 'Notes App',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.black),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            primaryColor: Colors.blueAccent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: false,
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardTheme(
              elevation: 2,
              color: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
          home: NotesHomePage(
            toggleTheme: _setThemePreference,
            isDarkMode: _isDarkMode,
          ),
        );
      },
    );
  }
}

enum NoteType { text, todo }

class Note {
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isProtected;
  NoteType type;
  List<TodoItem> todoItems;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isProtected = false,
    this.type = NoteType.text,
    this.todoItems = const [],
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isProtected,
    NoteType? type,
    List<TodoItem>? todoItems,
  }) {
    return Note(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isProtected: isProtected ?? this.isProtected,
      type: type ?? this.type,
      todoItems: todoItems ?? this.todoItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isProtected': isProtected,
      'type': type.index,
      'todoItems': todoItems.map((item) => item.toJson()).toList(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPinned: json['isPinned'] ?? false,
      isProtected: json['isProtected'] ?? false,
      type: NoteType.values[json['type'] ?? 0],
      todoItems: json['todoItems'] != null
          ? List<TodoItem>.from(
              (json['todoItems'] as List).map(
                (item) => TodoItem.fromJson(item),
              ),
            )
          : [],
    );
  }
}

class TodoItem {
  String id;
  String text;
  bool isDone;

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  TodoItem copyWith({
    String? text,
    bool? isDone,
  }) {
    return TodoItem(
      id: this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      isDone: json['isDone'] ?? false,
    );
  }
}

class NotesHomePage extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;

  const NotesHomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> with SingleTickerProviderStateMixin {
  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notes') ?? [];
      
      setState(() {
        _notes = notesJson
            .map((noteStr) => Note.fromJson(jsonDecode(noteStr)))
            .toList();
        _sortNotes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = _notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList('notes', notesJson);
  }

  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<bool> _authenticate() async {
    bool canAuthenticate = await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();

    if (canAuthenticate) {
      try {
        return await _localAuth.authenticate(
          localizedReason: 'Please authenticate to view this note',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _verifyPassword(String noteId) async {
    final storedPassword = await _secureStorage.read(key: 'note_password_$noteId');
    if (storedPassword == null) {
      return false;
    }
    
    final passwordController = TextEditingController();
    bool? isAuthenticated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Verify'),
            onPressed: () {
              if (passwordController.text == storedPassword) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid password')),
                );
              }
            },
          ),
        ],
      ),
    );
    
    return isAuthenticated ?? false;
  }

  Future<void> _addNote() async {
    final newNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          isNewNote: true,
          secureStorage: _secureStorage,
          noteType: _selectedTab == 0 ? NoteType.text : NoteType.todo,
        ),
      ),
    );

    if (newNote != null) {
      setState(() {
        _notes.add(newNote);
        _sortNotes();
      });
      _saveNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    // Check if note is protected
    if (note.isProtected) {
      bool isAuthenticated = await _authenticate();
      if (!isAuthenticated) {
        bool passwordVerified = await _verifyPassword(note.id);
        if (!passwordVerified) {
          return;
        }
      }
    }
    
    final updatedNote = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          isNewNote: false,
          note: note,
          secureStorage: _secureStorage,
        ),
      ),
    );

    if (updatedNote != null) {
      setState(() {
        final index = _notes.indexWhere((n) => n.id == updatedNote.id);
        if (index != -1) {
          _notes[index] = updatedNote;
          _sortNotes();
        }
      });
      _saveNotes();
    }
  }

  void _deleteNote(String id) {
    setState(() {
      _notes.removeWhere((note) => note.id == id);
    });
    _saveNotes();
    // Clean up stored password if it exists
    _secureStorage.delete(key: 'note_password_$id');
  }

  void _togglePinNote(String id) {
    setState(() {
      final index = _notes.indexWhere((note) => note.id == id);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(
          isPinned: !_notes[index].isPinned,
          updatedAt: DateTime.now(),
        );
        _sortNotes();
      }
    });
    _saveNotes();
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return _notes.where((note) => note.type.index == _selectedTab).toList();
    }
    
    final query = _searchQuery.toLowerCase();
    return _notes.where((note) {
      return note.type.index == _selectedTab && 
             (note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query) ||
              (note.type == NoteType.todo && 
               note.todoItems.any((item) => item.text.toLowerCase().contains(query))));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes', 
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.note),
              text: 'Notes',
            ),
            Tab(
              icon: Icon(Icons.check_box),
              text: 'Todo Lists',
            ),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(
                  _notes, 
                  _editNote, 
                  _deleteNote, 
                  _togglePinNote,
                  _authenticate,
                  _verifyPassword,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.toggleTheme(!widget.isDarkMode);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedTab == 0 ? Icons.note_alt_outlined : Icons.check_box_outlined,
                        size: 72,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedTab == 0 ? 'No notes yet' : 'No todo lists yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(
                          _selectedTab == 0 ? 'Create a note' : 'Create a todo list',
                        ),
                        onPressed: _addNote,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: NoteCard(
                          note: note,
                          onTap: () => _editNote(note),
                          onDelete: () => _deleteNote(note.id),
                          onTogglePin: () => _togglePinNote(note.id),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        tooltip: 'Add Note',
        icon: const Icon(Icons.add),
        label: Text(
          _selectedTab == 0 ? 'New Note' : 'New Todo List',
        ),
      ),
    );
  }
}

class NoteSearchDelegate extends SearchDelegate<Note?> {
  final List<Note> notes;
  final Function(Note) onEdit;
  final Function(String) onDelete;
  final Function(String) onTogglePin;
  final Future<bool> Function() authenticate;
  final Future<bool> Function(String) verifyPassword;

  NoteSearchDelegate(
    this.notes, 
    this.onEdit, 
    this.onDelete, 
    this.onTogglePin,
    this.authenticate,
    this.verifyPassword,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? notes
        : notes.where((note) {
            final searchText = query.toLowerCase();
            return note.title.toLowerCase().contains(searchText) ||
                note.content.toLowerCase().contains(searchText) ||
                (note.type == NoteType.todo && 
                 note.todoItems.any((item) => item.text.toLowerCase().contains(searchText)));
          }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final note = suggestions[index];
        return NoteCard(
          note: note,
          onTap: () async {
            if (note.isProtected) {
              bool isAuthenticated = await authenticate();
              if (!isAuthenticated) {
                bool passwordVerified = await verifyPassword(note.id);
                if (!passwordVerified) {
                  return;
                }
              }
            }
            onEdit(note);
            close(context, note);
          },
          onDelete: () {
            onDelete(note.id);
            if (suggestions.length <= 1) {
              close(context, null);
            }
          },
          onTogglePin: () {
            onTogglePin(note.id);
          },
        );
      },
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });

  String _getTodoProgressText() {
    if (note.todoItems.isEmpty) {
      return 'No tasks';
    }
    
    final completedCount = note.todoItems.where((item) => item.isDone).length;
    return '$completedCount/${note.todoItems.length} completed';
  }

  double _getTodoProgress() {
    if (note.todoItems.isEmpty) {
      return 0.0;
    }
    
    return note.todoItems.where((item) => item.isDone).length / note.todoItems.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColor = note.isPinned 
        ? theme.colorScheme.primaryContainer 
        : theme.cardTheme.color;
    
    return Card(
      color: noteColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (note.isProtected)
                        const Icon(Icons.lock, size: 20),
                      if (note.isPinned)
                        Icon(Icons.push_pin, size: 20, color: theme.colorScheme.primary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (note.type == NoteType.text)
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                )
              else // Todo list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.todoItems.isNotEmpty)
                      ...note.todoItems.take(3).map((item) => Row(
                        children: [
                          Icon(
                            item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 18,
                            color: item.isDone 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                                color: item.isDone
                                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      )).toList(),
                    if (note.todoItems.length > 3)
                      Text(
                        '+ ${note.todoItems.length - 3} more items',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (note.todoItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _getTodoProgress(),
                                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                color: theme.colorScheme.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTodoProgressText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                        ),
                        onPressed: onTogglePin,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Note'),
                              content: const Text('Are you sure you want to delete this note?'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    onDelete();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditPage extends StatefulWidget {
  final bool isNewNote;
  final Note? note;
  final FlutterSecureStorage secureStorage;
  final NoteType? noteType;

  const NoteEditPage({
    super.key,
    required this.isNewNote,
    this.note,
    required this.secureStorage,
    this.noteType,
  });

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<TodoItem> _todoItems;
  bool _isPinned = false;
  bool _isProtected = false;
  late final NoteType _noteType;
  late TextEditingController _newTodoController;
  TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isPinned = widget.note?.isPinned ?? false;
    _isProtected = widget.note?.isProtected ?? false;
    _noteType = widget.note?.type ?? widget.noteType ?? NoteType.text;
    _todoItems = widget.note?.todoItems.map((item) => TodoItem(
      id: item.id,
      text: item.text,
      isDone: item.isDone,
    )).toList() ?? [];
    _newTodoController = TextEditingController();
    
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    if (widget.note != null && widget.note!.isProtected) {
      final password = await widget.secureStorage.read(key: 'note_password_${widget.note!.id}');
      if (password != null) {
        _passwordController.text = password;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newTodoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addTodoItem() {
    final text = _newTodoController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _todoItems.add(TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
        ));
        _newTodoController.clear();
      });
    }
  }

  void _toggleTodoItem(String id) {
    setState(() {
      final index = _todoItems.indexWhere((item) => item.id == id);
      if (index != -1) {
          _todoItems[index] = _todoItems[index].copyWith(
            isDone: !_todoItems[index].isDone,
          );
        }
      });
    }

  void _editTodoItem(String id, String newText) {
    setState(() {
      final index = _todoItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _todoItems[index] = _todoItems[index].copyWith(
          text: newText,
        );
      }
    });
  }

  void _removeTodoItem(String id) {
    setState(() {
      _todoItems.removeWhere((item) => item.id == id);
    });
  }

  void _reorderTodoItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _todoItems.removeAt(oldIndex);
      _todoItems.insert(newIndex, item);
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // For text notes, validate content or title
    if (_noteType == NoteType.text && content.isEmpty && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty')),
      );
      return;
    }

    // For todo lists, validate title or having todo items
    if (_noteType == NoteType.todo && title.isEmpty && _todoItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todo list needs a title or tasks')),
      );
      return;
    }

    // If protection is enabled, ensure there's a password
    if (_isProtected && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a password for protection')),
      );
      return;
    }

    final now = DateTime.now();
    
    if (widget.isNewNote) {
      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Save password if protected
      if (_isProtected) {
        await widget.secureStorage.write(
          key: 'note_password_$noteId',
          value: _passwordController.text,
        );
      }
      
      final newNote = Note(
        id: noteId,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        isPinned: _isPinned,
        isProtected: _isProtected,
        type: _noteType,
        todoItems: _todoItems,
      );
      Navigator.pop(context, newNote);
    } else if (widget.note != null) {
      // Update password if protected status changed or password changed
      if (_isProtected) {
        await widget.secureStorage.write(
          key: 'note_password_${widget.note!.id}',
          value: _passwordController.text,
        );
      } else if (widget.note!.isProtected && !_isProtected) {
        // Remove password if protection was disabled
        await widget.secureStorage.delete(key: 'note_password_${widget.note!.id}');
      }
      
      final updatedNote = widget.note!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
        isPinned: _isPinned,
        isProtected: _isProtected,
        type: _noteType,
        todoItems: _todoItems,
      );
      Navigator.pop(context, updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewNote 
              ? _noteType == NoteType.text ? 'New Note' : 'New Todo List'
              : _noteType == NoteType.text ? 'Edit Note' : 'Edit Todo List',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? theme.colorScheme.primary : null,
            ),
            tooltip: _isPinned ? 'Unpin' : 'Pin',
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isProtected ? Icons.lock : Icons.lock_open_outlined,
              color: _isProtected ? theme.colorScheme.primary : null,
            ),
            tooltip: _isProtected ? 'Remove protection' : 'Protect with password',
            onPressed: () {
              setState(() {
                _isProtected = !_isProtected;
              });
              
              if (_isProtected && _passwordController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Set Password'),
                    content: TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isProtected = false;
                          });
                        },
                      ),
                      TextButton(
                        child: const Text('Save'),
                        onPressed: () {
                          if (_passwordController.text.isNotEmpty) {
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password cannot be empty')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: _noteType == NoteType.text ? _buildTextNoteEditor() : _buildTodoListEditor(),
    );
  }

  Widget _buildTextNoteEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Note content...',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoListEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Todo List Title',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
              border: InputBorder.none,
            ),
            maxLines: 3,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTodoController,
                  decoration: const InputDecoration(
                    hintText: 'Add a task...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addTodoItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addTodoItem,
                color: Theme.of(context).colorScheme.primary,
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _todoItems.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _todoItems.length,
                    onReorder: _reorderTodoItems,
                    itemBuilder: (context, index) {
                      final item = _todoItems[index];
                      return TodoItemTile(
                        key: Key(item.id),
                        item: item,
                        onToggle: () => _toggleTodoItem(item.id),
                        onEdit: (newText) => _editTodoItem(item.id, newText),
                        onDelete: () => _removeTodoItem(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class TodoItemTile extends StatefulWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final Function(String) onEdit;
  final VoidCallback onDelete;

  const TodoItemTile({
    required Key key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<TodoItemTile> createState() => _TodoItemTileState();
}

class _TodoItemTileState extends State<TodoItemTile> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodoItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text) {
      _controller.text = widget.item.text;
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onEdit(_controller.text.trim());
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ListTile(
          leading: IconButton(
            icon: Icon(
              widget.item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: widget.item.isDone 
                  ? theme.colorScheme.primary 
                  : null,
            ),
            onPressed: widget.onToggle,
          ),
          title: _isEditing
              ? TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveEdit(),
                )
              : Text(
                  widget.item.text,
                  style: TextStyle(
                    decoration: widget.item.isDone ? TextDecoration.lineThrough : null,
                    color: widget.item.isDone
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveEdit,
                  color: theme.colorScheme.primary,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _startEditing,
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onDelete,
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
        ),
      ),
    );
  }
}