// Layar chat dengan Mentor AI, terhubung ke riset aktif.
// Padanan Mentor.tsx desain VETA — bedanya belum streaming (backend
// masih non-streaming), jadi dipakai indikator loading yang jelas.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/mentor_message_model.dart';
import '../../providers/active_research_provider.dart';
import '../../services/mentor_service.dart';
import '../../widgets/chat_bubble.dart';

class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({super.key});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final MentorService _mentorService = MentorService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MentorMessageModel> _messages = [];
  String? _conversationId;
  String?
      _loadedForResearchId; // supaya tidak reload percakapan berulang untuk riset yang sama
  bool _isSending = false;

  static const _suggestedQuestions = [
    'Bantu saya membuat outline',
    'Review metodologi saya',
    'Cari research gap',
  ];

  Future<void> _ensureConversation(String researchId) async {
    if (_loadedForResearchId == researchId) return;

    setState(() {
      _messages.clear();
      _conversationId = null;
      _loadedForResearchId = researchId;
    });

    // Coba pakai percakapan terakhir yang ada untuk riset ini
    final conversations = await _mentorService.getConversations(researchId);
    if (conversations.isNotEmpty) {
      final latest = conversations.first;
      final messages = await _mentorService.getMessages(latest.id);
      if (!mounted) return;
      setState(() {
        _conversationId = latest.id;
        _messages.addAll(messages);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String researchId, String text) async {
    if (text.trim().isEmpty || _isSending) return;

    setState(() {
      _messages.add(MentorMessageModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        role: 'user',
        content: text.trim(),
        createdAt: DateTime.now(),
      ));
      _isSending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      // Buat percakapan dulu kalau belum ada
      _conversationId ??=
          (await _mentorService.createConversation(researchId)).id;

      final reply =
          await _mentorService.sendMessage(_conversationId!, text.trim());
      if (!mounted) return;
      setState(() => _messages.add(reply));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(MentorMessageModel(
            id: 'error-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: 'Maaf, terjadi kesalahan: $e',
            createdAt: DateTime.now(),
          )));
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeResearch =
        context.watch<ActiveResearchProvider>().activeResearch;

    if (activeResearch == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Buat penelitian terlebih dahulu untuk memulai percakapan dengan VETA AI Mentor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Panggil setelah build supaya tidak setState() saat build berjalan
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ensureConversation(activeResearch.id));

    return Column(
      children: [
        // Header konteks riset aktif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent,
                child: Icon(Icons.auto_awesome,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VETA AI Mentor',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(activeResearch.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Daftar pesan
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChatState(
                  researchTitle: activeResearch.title,
                  suggestions: _suggestedQuestions,
                  onPickSuggestion: (q) => _sendMessage(activeResearch.id, q),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      ChatBubble(message: _messages[index]),
                ),
        ),

        // Indikator loading saat menunggu balasan (bisa lama — lihat catatan di service)
        if (_isSending)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
                SizedBox(width: 8),
                Text('VETA sedang berpikir, mungkin sedang mencari literatur…',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),

        // Input pesan
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan sesuatu…',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                    onSubmitted: (text) =>
                        _sendMessage(activeResearch.id, text),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending
                      ? null
                      : () => _sendMessage(
                          activeResearch.id, _inputController.text),
                  icon: const Icon(Icons.send, size: 18),
                  style:
                      IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String researchTitle;
  final List<String> suggestions;
  final ValueChanged<String> onPickSuggestion;

  const _EmptyChatState({
    required this.researchTitle,
    required this.suggestions,
    required this.onPickSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),
            const SizedBox(height: 14),
            const Text('Halo! Saya VETA AI Mentor Anda',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('"$researchTitle"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Saya sudah memahami konteks penelitian ini. Tanyakan apa saja — dari literature review hingga metodologi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((q) {
                return OutlinedButton(
                  onPressed: () => onPickSuggestion(q),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: Text(q, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
