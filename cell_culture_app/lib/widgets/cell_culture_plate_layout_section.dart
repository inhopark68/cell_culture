import 'package:flutter/material.dart';

import '../models/plate_drag_data.dart';
import '../services/cell_culture_layout_service.dart';

class CellCulturePlateLayoutSection extends StatelessWidget {
  final List<List<String>> layout;
  final bool autoGenerateLayout;
  final VoidCallback onRegenerate;
  final VoidCallback onClear;
  final void Function(int row, int col) onEditWell;
  final void Function(int fromRow, int fromCol, int toRow, int toCol) onSwap;

  const CellCulturePlateLayoutSection({
    super.key,
    required this.layout,
    required this.autoGenerateLayout,
    required this.onRegenerate,
    required this.onClear,
    required this.onEditWell,
    required this.onSwap,
  });

  Widget _legend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Colors.blue.shade50, 'Sample'),
        item(Colors.grey.shade300, 'Blank'),
        item(Colors.red.shade100, 'Negative control'),
        item(Colors.yellow.shade100, 'Vehicle'),
        item(Colors.green.shade100, 'Positive control'),
        item(Colors.grey.shade100, 'Empty'),
      ],
    );
  }

  Widget _buildWell({
    required int row,
    required int col,
    required String value,
  }) {
    return DragTarget<PlateDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final from = details.data;
        if (from.row == row && from.col == col) return;
        onSwap(from.row, from.col, row, col);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return LongPressDraggable<PlateDragData>(
          data: PlateDragData(row: row, col: col),
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 78,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CellCultureLayoutService.getWellColor(value),
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          childWhenDragging: Container(
            height: 56,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(6),
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          child: GestureDetector(
            onTap: () => onEditWell(row, col),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.indigo.shade100
                    : CellCultureLayoutService.getWellColor(value),
                border: Border.all(
                  color: isHovering ? Colors.indigo : Colors.grey.shade300,
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable() {
    if (layout.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '현재 선택한 culture ware는 plate layout 표시 대상이 아닙니다.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    final rowCount = layout.length;
    final colCount = layout.first.length;
    final rowLabels =
        List.generate(rowCount, (index) => String.fromCharCode(65 + index));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        defaultColumnWidth: const FixedColumnWidth(78),
        children: [
          TableRow(
            children: [
              const SizedBox(),
              ...List.generate(
                colCount,
                (c) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      '${c + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...List.generate(rowCount, (r) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      rowLabels[r],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ...List.generate(colCount, (c) {
                  return _buildWell(
                    row: r,
                    col: c,
                    value: layout[r][c],
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            autoGenerateLayout ? 'Mode: Auto-generated' : 'Mode: Manually edited',
            style: TextStyle(
              color: autoGenerateLayout ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tap: edit well  •  Long press & drag: swap wells',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legend(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh),
                label: const Text('Auto Regenerate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Layout'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTable(),
      ],
    );
  }
}