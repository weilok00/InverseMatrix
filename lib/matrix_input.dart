import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MatrixInput extends StatelessWidget {
  final int matrixSize;
  final List<List<TextEditingController>> matrixControllers;
  final Function(int) onMatrixSizeChanged;
  final VoidCallback onComputeInverse;
  final VoidCallback onClear;
  final String computeButtonLabel;

  const MatrixInput({
    required this.matrixSize,
    required this.matrixControllers,
    required this.onMatrixSizeChanged,
    required this.onComputeInverse,
    required this.onClear,
    required this.computeButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [2, 3, 4].map((size) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: ElevatedButton(
                onPressed: () => onMatrixSizeChanged(size),
                style: ElevatedButton.styleFrom(
                  backgroundColor: matrixSize == size ? Colors.black : Colors.grey[300],
                  foregroundColor: matrixSize == size ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: matrixSize == size ? 2 : 0,
                ),
                child: Text(
                  "$size x $size",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        Column(
          children: List.generate(matrixSize, (i) {
            return Row(
              children: List.generate(matrixSize, (j) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: matrixControllers[i][j],
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),

        const SizedBox(height: 20),

        Column(
          children: [
            ElevatedButton(
              onPressed: onComputeInverse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Math.tex(
                computeButtonLabel,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Math.tex(
                r'\text{Clear}',
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
