import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../data/match.dart';
import '../providers/matches_provider.dart';

/// Opens the add / edit sheet. Returns the saved match, or null if cancelled.
Future<MatchProfile?> showMatchEditor(BuildContext context, {MatchProfile? existing}) {
  return showModalBottomSheet<MatchProfile>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _MatchEditor(existing: existing),
  );
}

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MatchProfile match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('DELETE ${match.name.toUpperCase()}?'),
        content: const Text('Their notes are removed from this phone. Saved replies stay in History.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(matchesProvider.notifier).delete(match.id);
    if (context.mounted) showBroSnack(context, '${match.name} removed.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MATCHES')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMatchEditor(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add match'),
      ),
      body: SafeArea(
        child: matches.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final match = matches[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface2,
                        child: Text(
                          match.name.isEmpty ? '?' : match.name.characters.first.toUpperCase(),
                          style: AppTextStyles.title,
                        ),
                      ),
                      title: Text(match.name, style: AppTextStyles.label),
                      subtitle: Text(
                        match.notes.isEmpty ? 'No notes yet' : match.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      onTap: () => showMatchEditor(context, existing: match),
                      trailing: IconButton(
                        tooltip: 'Delete ${match.name}',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _confirmDelete(context, ref, match),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('NO MATCHES YET', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Save what you know about her: interests, plans, inside jokes. '
              'Pick her in the composer and replies can use it. Notes stay on this phone.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchEditor extends ConsumerStatefulWidget {
  const _MatchEditor({this.existing});

  final MatchProfile? existing;

  @override
  ConsumerState<_MatchEditor> createState() => _MatchEditorState();
}

class _MatchEditorState extends ConsumerState<_MatchEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.existing?.notes ?? '');

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final match = await ref
        .read(matchesProvider.notifier)
        .save(id: widget.existing?.id, name: _name.text, notes: _notes.text);
    if (mounted) Navigator.pop(context, match);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? 'ADD MATCH' : 'EDIT MATCH', style: AppTextStyles.headline),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            style: AppTextStyles.body,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            maxLength: AppConstants.maxNotesLength - 60, // leaves room for "Name: …"
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Loves ramen and bouldering. Has a dog named Mochi. Free most Sundays.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _save,
            style: FilledButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius)),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Save')),
          ),
        ],
      ),
    );
  }
}
