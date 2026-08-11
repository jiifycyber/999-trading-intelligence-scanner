import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AgentDukePanel extends StatefulWidget {
  final Map<String, dynamic> marketContext;

  const AgentDukePanel({
    super.key,
    this.marketContext = const {},
  });

  @override
  State<AgentDukePanel> createState() => _AgentDukePanelState();
}

class _AgentDukePanelState extends State<AgentDukePanel> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String _reply =
      'Agent Duke Da Boss X online. Ask me about the scanner, radar, or current market setup.';

  Future<void> _send(String message) async {
    if (message.trim().isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _reply = 'Analyzing...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8787/duke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message.trim(),
          'market': widget.marketContext,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _reply = data['reply']?.toString() ?? 'No response returned.';
        });
      } else {
        setState(() {
          _reply = 'Duke server error ${response.statusCode}: $data';
        });
      }
    } catch (e) {
      setState(() {
        _reply =
            'Cannot reach Agent Duke backend. Make sure Uvicorn is running on port 8787.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _textChat() {
    _controller.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF17111F),
        title: const Text('Agent Duke Da Boss X'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ask Duke...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(dialogContext);
            _send(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final text = _controller.text;
              Navigator.pop(dialogContext);
              _send(text);
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  Widget _button(
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return FilledButton.tonalIcon(
      onPressed: _loading ? null : action,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17111F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF724AA3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF7445B5),
                child: Icon(Icons.psychology_alt),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Duke Da Boss X',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '999 Trading Intelligence AI Analyst',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 5,
                backgroundColor: Color(0xFF62E6AC),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _button(
                Icons.chat_bubble_outline,
                'TEXT',
                _textChat,
              ),
              _button(
                Icons.analytics_outlined,
                'ANALYZE MARKET',
                () => _send(
                  'Analyze the current scanner and radar data. Tell me what is happening and what setup is strongest.',
                ),
              ),
              _button(
                Icons.gps_fixed,
                'TOP TRADE',
                () => _send(
                  'What is the strongest current setup? Give me the asset, signal, confidence, reasoning, and risk.',
                ),
              ),
              _button(
                Icons.mic_none,
                'TALK',
                () {
                  setState(() {
                    _reply =
                        'Microphone input will be connected in the next voice step.';
                  });
                },
              ),
              _button(
                Icons.volume_up_outlined,
                'VOICE',
                () {
                  setState(() {
                    _reply =
                        'Voice output will be connected in the next voice step.';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF241E2B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loading
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Duke is thinking...'),
                    ],
                  )
                : Text(
                    _reply,
                    style: const TextStyle(height: 1.45),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
