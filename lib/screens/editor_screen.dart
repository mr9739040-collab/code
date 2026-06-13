import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorScreen extends StatefulWidget {
  final String roomId;

  const EditorScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _controller = TextEditingController();

  final ScrollController _editorScrollController =
  ScrollController();

  final ScrollController _lineScrollController =
  ScrollController();

  Timer? _debounce;

  bool _isLocalEdit = false;

  final Duration debounceTime =
  const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    _editorScrollController.addListener(() {
      if (_lineScrollController.hasClients) {
        _lineScrollController.jumpTo(
          _editorScrollController.offset,
        );
      }
    });
  }

  /// UPDATE CODE
  void _updateCode(String code) {
    _firestore.collection('rooms').doc(widget.roomId).update({
      'code': code,
    });
  }

  /// HANDLE CHANGE
  void _onChanged(String value) {
    _isLocalEdit = true;

    _setTyping(true);

    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(debounceTime, () {
      _updateCode(value);
      _setTyping(false);
    });

    setState(() {});
  }

  /// TYPING STATUS
  Future<void> _setTyping(bool typing) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    if (typing) {
      await _firestore.collection('rooms').doc(widget.roomId).update({
        'typingUsers': FieldValue.arrayUnion([uid]),
      });
    } else {
      await _firestore.collection('rooms').doc(widget.roomId).update({
        'typingUsers': FieldValue.arrayRemove([uid]),
      });
    }
  }

  /// COPY CODE
  void _copyCode() {
    Clipboard.setData(
      ClipboardData(text: _controller.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        content: Text("Code copied 📋"),
      ),
    );
  }

  /// CLEAR CODE
  void _clearCode() {
    _controller.clear();
    _updateCode("");

    setState(() {});
  }

  /// RUN CODE
  void _runCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: Text("Running code..."),
      ),
    );
  }

  /// AI
  void _aiAssistant() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        content: Text("AI Assistant Opened ✨"),
      ),
    );
  }

  /// LINE NUMBERS
  Widget _buildLineNumbers() {
    final lines = _controller.text.split('\n').length;

    return Container(
      width: 55,
      color: const Color(0xFF0B1220),
      child: ListView.builder(
        controller: _lineScrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lines,
        itemBuilder: (context, index) {
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(
              right: 12,
              top: 8,
              bottom: 8,
            ),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  /// SIDEBAR BUTTON
  Widget sideButton(
      IconData icon, {
        VoidCallback? onTap,
        bool active = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: active
                ? Colors.deepPurple.withOpacity(.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: active
                ? Colors.deepPurpleAccent
                : Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _setTyping(false);

    _controller.dispose();

    _editorScrollController.dispose();

    _lineScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),

      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('rooms')
              .doc(widget.roomId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data =
                snapshot.data!.data() as Map<String, dynamic>? ??
                    {};

            final remoteCode = data['code'] ?? '';

            final typingUsers =
            List<String>.from(data['typingUsers'] ?? []);

            if (!_isLocalEdit &&
                _controller.text != remoteCode) {
              final oldSelection = _controller.selection;

              _controller.value = TextEditingValue(
                text: remoteCode,
                selection: oldSelection,
              );
            }

            _isLocalEdit = false;

            return Column(
              children: [

                /// TOP BAR
                Container(
                  height: 82,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [

                      /// BACK
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      /// LOGO
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade700,
                              Colors.purpleAccent,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.code,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// TITLE
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "CodeCollab Editor",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [

                                Flexible(
                                  child: Text(
                                    "4 collaborators",
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                      Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green
                                        .withOpacity(.12),
                                    borderRadius:
                                    BorderRadius.circular(
                                        20),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [

                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration:
                                        const BoxDecoration(
                                          color: Colors.green,
                                          shape:
                                          BoxShape.circle,
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      const Text(
                                        "LIVE",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// USERS FIXED
                      SizedBox(
                        width: 88,
                        height: 34,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [

                            Positioned(
                              left: 0,
                              child: userAvatar(
                                "A",
                                Colors.deepPurple,
                              ),
                            ),

                            Positioned(
                              left: 20,
                              child: userAvatar(
                                "B",
                                Colors.orange,
                              ),
                            ),

                            Positioned(
                              left: 40,
                              child: userAvatar(
                                "C",
                                Colors.green,
                              ),
                            ),

                            Positioned(
                              left: 60,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration:
                                const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.deepPurple,
                                ),
                                child: const Center(
                                  child: Text(
                                    "+1",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),

                      const SizedBox(width: 4),
                    ],
                  ),
                ),

                /// MAIN
                Expanded(
                  child: Row(
                    children: [

                      /// LEFT SIDEBAR
                      Container(
                        width: 68,
                        color: const Color(0xFF050B1A),
                        child: Column(
                          children: [

                            const SizedBox(height: 14),

                            sideButton(
                              Icons.description_outlined,
                              active: true,
                            ),

                            sideButton(Icons.search),

                            sideButton(
                                Icons.account_tree_outlined),

                            sideButton(
                              Icons.play_arrow_rounded,
                              onTap: _runCode,
                            ),

                            sideButton(
                                Icons.bug_report_outlined),

                            sideButton(
                                Icons.inventory_2_outlined),

                            const Spacer(),

                            sideButton(
                                Icons.settings_outlined),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      /// RIGHT SIDE
                      Expanded(
                        child: Column(
                          children: [

                            /// FILE TABS
                            Container(
                              height: 55,
                              color: const Color(0xFF0B1220),
                              child: SingleChildScrollView(
                                scrollDirection:
                                Axis.horizontal,
                                child: Row(
                                  children: [

                                    activeTab("main.dart"),

                                    tab("pubspec.yaml"),

                                    tab("README.md"),

                                    const SizedBox(width: 10),

                                    const Icon(
                                      Icons.add,
                                      color: Colors.white70,
                                    ),

                                    const SizedBox(width: 20),
                                  ],
                                ),
                              ),
                            ),

                            /// EDITOR
                            Expanded(
                              child: Container(
                                color:
                                const Color(0xFF020617),
                                child: Row(
                                  children: [

                                    _buildLineNumbers(),

                                    Expanded(
                                      child: Stack(
                                        children: [

                                          TextField(
                                            controller:
                                            _controller,
                                            onChanged:
                                            _onChanged,
                                            expands: true,
                                            maxLines: null,
                                            minLines: null,
                                            keyboardType:
                                            TextInputType
                                                .multiline,
                                            scrollController:
                                            _editorScrollController,
                                            textAlignVertical:
                                            TextAlignVertical
                                                .top,
                                            style:
                                            const TextStyle(
                                              color:
                                              Colors.white,
                                              fontSize: 16,
                                              height: 1.7,
                                              fontFamily:
                                              'monospace',
                                            ),
                                            cursorColor: Colors
                                                .deepPurpleAccent,
                                            decoration:
                                            InputDecoration(
                                              border:
                                              InputBorder
                                                  .none,
                                              contentPadding:
                                              const EdgeInsets
                                                  .all(20),
                                              hintText:
                                              "// Start coding in flutter room...",
                                              hintStyle:
                                              TextStyle(
                                                color: Colors
                                                    .grey
                                                    .shade700,
                                                fontSize: 16,
                                                fontFamily:
                                                'monospace',
                                              ),
                                            ),
                                          ),

                                          if (typingUsers
                                              .isNotEmpty)
                                            Positioned(
                                              top: 16,
                                              right: 16,
                                              child: Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal:
                                                  14,
                                                  vertical: 7,
                                                ),
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors
                                                      .deepPurple,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      20),
                                                ),
                                                child:
                                                const Text(
                                                  "Someone typing...",
                                                  style:
                                                  TextStyle(
                                                    color: Colors
                                                        .white,
                                                    fontSize:
                                                    12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// STATUS BAR
                            Container(
                              height: 46,
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              color:
                              const Color(0xFF0B1220),
                              child: Row(
                                children: [

                                  Text(
                                    "Lines ${_controller.text.split('\n').length}",
                                    style: TextStyle(
                                      color:
                                      Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(width: 18),

                                  Text(
                                    "UTF-8",
                                    style: TextStyle(
                                      color:
                                      Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(width: 18),

                                  Text(
                                    "Dart",
                                    style: TextStyle(
                                      color:
                                      Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const Spacer(),

                                  IconButton(
                                    onPressed: _copyCode,
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      _clearCode();
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color:
                                      Colors.redAccent,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// BOTTOM BAR
                Container(
                  height: 86,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF020617),
                  ),
                  child: Row(
                    children: [

                      GestureDetector(
                        onTap: _runCode,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration:
                          const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple,
                                Colors.purpleAccent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Container(
                          height: 54,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFF111827),
                            borderRadius:
                            BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [

                              Icon(
                                Icons.search,
                                color:
                                Colors.grey.shade500,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration:
                                  InputDecoration(
                                    border:
                                    InputBorder.none,
                                    hintText:
                                    "Search or run command...",
                                    hintStyle: TextStyle(
                                      color: Colors
                                          .grey.shade500,
                                    ),
                                  ),
                                ),
                              ),

                              const Icon(
                                Icons.keyboard,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      GestureDetector(
                        onTap: _aiAssistant,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration:
                          const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple,
                                Colors.purpleAccent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ACTIVE TAB
  Widget activeTab(String title) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.deepPurple,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [

          const Icon(
            Icons.code,
            color: Colors.lightBlue,
            size: 18,
          ),

          const SizedBox(width: 8),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            Icons.close,
            size: 18,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  /// NORMAL TAB
  Widget tab(String title) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// USER AVATAR
  Widget userAvatar(String text, Color color) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: color,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}