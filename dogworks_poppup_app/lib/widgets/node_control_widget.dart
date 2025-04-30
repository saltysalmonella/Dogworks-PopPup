import 'package:flutter/material.dart';
import '../models/device_model.dart';

class NodeControlWidget extends StatefulWidget {
  final GameDevice node;
  final bool isAutoPlayMode;
  final bool isPlayModeActive;
  final bool canOpen;
  final bool canClose;
  final bool isCollarClose;
  final Function(bool) onToggle;

  const NodeControlWidget({
    Key? key,
    required this.node,
    required this.onToggle,
    this.isAutoPlayMode = false,
    this.isPlayModeActive = false,
    this.canOpen = true,
    this.canClose = true,
    this.isCollarClose = false,
  }) : super(key: key);

  @override
  State<NodeControlWidget> createState() => _NodeControlWidgetState();
}

class _NodeControlWidgetState extends State<NodeControlWidget> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: widget.isCollarClose ? Colors.yellow[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Node icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: 
                      Image.asset(
                        'lib/assets/images/node_icon.png',
                        height: 50,
                        width: 50,
                      ),
                      // color: widget.node.isOpen ? Colors.green : const Color(0xFF2B3674),
                    ),
                  ),
                
                const SizedBox(width: 12),
                // Node info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.node.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${widget.node.isOpen ? 'Open' : 'Closed'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.node.isOpen ? Colors.green : Colors.grey,
                      ),
                    ),
                    if (widget.isCollarClose)
                      const Text(
                        'Collar Nearby!',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_getModeDescription().isNotEmpty)
                      Text(
                        _getModeDescription(),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
            
            // Control buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle button
                ElevatedButton(
                  onPressed: _isButtonDisabled()
                      ? null 
                      : () async {
                          setState(() {
                            _isToggling = true;
                          });
                          
                          try {
                            // Toggle to opposite of current state
                            await widget.onToggle(!widget.node.isOpen);
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isToggling = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.node.isOpen ? Colors.red : Colors.green,
                    disabledBackgroundColor: Colors.grey[300],
                    minimumSize: const Size(90, 40),
                  ),
                  child: _isToggling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          widget.node.isOpen ? 'CLOSE' : 'OPEN',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to determine if button should be disabled
  bool _isButtonDisabled() {
    if (_isToggling) return true;
    
    // In auto mode, all controls are disabled
    if (widget.isAutoPlayMode) return true;
    
    // In manual mode, closing is automatic (disable if open)
    if (!widget.canClose && widget.node.isOpen) return true;
    
    // In manual mode, opening is manual (enable if closed)
    if (!widget.canOpen && !widget.node.isOpen) return true;
    
    // Otherwise, button is enabled
    return false;
  }
  
  String _getModeDescription() {
    if (!widget.isPlayModeActive) {
      return 'Select a play mode to control';
    } else if (widget.isAutoPlayMode) {
      return 'Auto mode - buttons disabled';
    } else if (!widget.canClose && widget.canOpen) {
      return 'Manual mode - auto close';
    }
    return '';
  }
}