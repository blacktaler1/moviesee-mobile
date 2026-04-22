import 'package:flutter/material.dart';
import '../../data/models/room_model.dart';

class RoomUsersBar extends StatelessWidget {
  final List<RoomUser> users;
  const RoomUsersBar({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 52,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.people_rounded, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _UserChip(user: users[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final RoomUser user;
  const _UserChip({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          child: Text(
            user.username.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(user.username,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 4),
        Icon(
          user.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: user.muted ? Colors.redAccent : Colors.greenAccent,
          size: 12,
        ),
      ],
    );
  }
}
