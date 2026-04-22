import 'package:flutter/material.dart';
import '../../data/models/room_model.dart';

class ChatOverlay extends StatefulWidget {
  final List<ChatMessage> messages;
  final void Function(String) onSend;
  final VoidCallback onClose;

  const ChatOverlay({
    super.key,
    required this.messages,
    required this.onSend,
    required this.onClose,
  });

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(ChatOverlay old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white60, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Chat',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.messages.isEmpty
                ? const Center(
                    child: Text('Hali xabar yo\'q',
                        style: TextStyle(
                            color: Colors.white30, fontSize: 13)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: widget.messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(msg: widget.messages[i]),
                  ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      hintStyle: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(msg.username,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11)),
              const SizedBox(width: 6),
              Text(msg.time,
                  style: const TextStyle(
                      color: Colors.white30, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 2),
          Text(msg.text,
              style:
                  const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
