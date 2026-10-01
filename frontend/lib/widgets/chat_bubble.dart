// Widget bubble chat (Mentor AI) — beda warna untuk user vs assistant.
// Balasan assistant dirender pakai Markdown (supaya **tebal**, heading,
// dan list dari Gemini tampil rapi, bukan tanda bintang mentah).
// Kartu sitasi jurnal (FR-07c) bisa DITAP untuk buka sumber aslinya.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/mentor_message_model.dart';
import '../models/journal_model.dart';

class ChatBubble extends StatelessWidget {
  final MentorMessageModel message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accent,
                child: Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 14 : 2),
                    bottomRight: Radius.circular(isUser ? 2 : 14),
                  ),
                  border: isUser ? null : Border.all(color: AppColors.border),
                ),
                child: isUser
                    ? Text(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.primaryForeground,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      )
                    : MarkdownBody(
                        data: message.content,
                        onTapLink: (text, href, title) async {
                          if (href == null) return;
                          final uri = Uri.parse(href);
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.4),
                          strong: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                          ),
                          em: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                          listBullet: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          h1: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          h2: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          h3: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          code: const TextStyle(
                            color: AppColors.primary,
                            backgroundColor: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),

        // Kartu sitasi jurnal, kalau ada (FR-07c)
        if (message.journals.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: message.journals
                  .map((j) => _JournalCard(journal: j))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalModel journal;
  const _JournalCard({required this.journal});

  Future<void> _openLink(BuildContext context) async {
    if (journal.url == null || journal.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Link sumber tidak tersedia untuk jurnal ini')),
      );
      return;
    }

    final uri = Uri.parse(journal.url!);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openLink(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              journal.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.accentForeground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (journal.authors != null) journal.authors,
                if (journal.year != null) journal.year.toString(),
              ].join(' · '),
              style: TextStyle(
                color: AppColors.accentForeground.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  journal.sourceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.open_in_new,
                    size: 11, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
