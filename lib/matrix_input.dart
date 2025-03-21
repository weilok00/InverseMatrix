import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatrixInput extends StatelessWidget {
  final int matrixSize;
  final List<List<TextEditingController>> matrixControllers;
  final Function(int) onMatrixSizeChanged;
  final VoidCallback onComputeInverse;
  final VoidCallback onClear;

  const MatrixInput({
    required this.matrixSize,
    required this.matrixControllers,
    required this.onMatrixSizeChanged,
    required this.onComputeInverse,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Matrix Size Selection Buttons (Black & White Theme)
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
                  elevation: matrixSize == size ? 2 : 0, // Light shadow for selected button
                ),
                child: Text(
                  "$size x $size",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Matrix Input Fields
        Column(
          children: List.generate(matrixSize, (i) {
            return Row(
              children: List.generate(matrixSize, (j) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: matrixControllers[i][j],
                      keyboardType: TextInputType.text, // Allow text input instead of number only
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                    )
                  ),
                );
              }),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Buttons Section
        Column(
          children: [
            // "Compute Inverse" Button
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
              child: const Text(
                "Compute Inverse",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            // "Clear" Button
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
              child: const Text(
                "Clear",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

