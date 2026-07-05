import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import '../../services/ai_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

/// In-app "AI Coach" chat, powered by Gemini (free tier). Personalizes
/// replies using the user's saved profile (goal, stats) when available.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _aiService = AiService();
  final _profileService = ProfileService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  UserProfile? _profile;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        role: MessageRole.assistant,
        content: "Hey! I'm your AI Coach 💪 Ask me anything about workouts, "
            "nutrition, recovery, or how to hit your goals.",
      ),
    );
    _profileService.getProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(role: MessageRole.user, content: text));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply =
          await _aiService.sendMessage(history: _messages, profile: _profile);
      setState(() {
        _messages.add(ChatMessage(role: MessageRole.assistant, content: reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          content: 'Sorry, something went wrong: $e',
        ));
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AI Coach',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _ChatInputBar(
                controller: _controller, onSend: _send, isSending: _isSending),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const SizedBox(
          width: 32,
          height: 12,
          child: _TypingDots(),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.2) % 1.0;
            final scale = t < 0.5 ? (0.6 + t) : (1.6 - t);
            return Opacity(
              opacity: scale.clamp(0.3, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const _ChatInputBar(
      {required this.controller,
      required this.onSend,
      required this.isSending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask your coach anything...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSending
                    ? Icons.hourglass_top_rounded
                    : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
