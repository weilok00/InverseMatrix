import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'expansiontile.dart';

class MatrixOutput extends StatelessWidget {
  final String inputMatrix;
  final String determinantText;
  final String inverseMatrix;
  final String errorMessage;
  final bool showSteps;
  final List<String> steps;
  final List<String> eigenvalueSteps;
  final List<String> eigenvectorSteps;
  final bool showEigen;

  const MatrixOutput({
    required this.inputMatrix,
    required this.determinantText,
    required this.inverseMatrix,
    required this.errorMessage,
    required this.showSteps,
    required this.steps,
    required this.eigenvalueSteps,      // ✅ Add this
    required this.eigenvectorSteps,     // ✅ Add this
    required this.showEigen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (inputMatrix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                r'A = ' + inputMatrix, 
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 10),

        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Math.tex(
              errorMessage,
              textStyle: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        const SizedBox(height: 10),

        if (determinantText.isNotEmpty || inverseMatrix.isNotEmpty)
          MatrixExpansionTile(
            titleContent: [
              Math.tex(
                r'\text{Answer}',
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            childrenContent: [
              if (determinantText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      r'\text{Determinant: } ' + determinantText,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              if (inverseMatrix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    r'A^{-1} = ' + inverseMatrix,
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),

        if (showSteps)
          MatrixExpansionTile(
            titleContent: [
              Math.tex(
                r'\text{Step-by-Step Calculation}',
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
            childrenContent: steps.map((step) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    step,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),
        
          if (showEigen)
            MatrixExpansionTile(
              titleContent: [
                Math.tex(
                  r'\text{Eigenvalues}',
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
              childrenContent: eigenvalueSteps.map((step) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(step, textStyle: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ),

          if (showEigen)
            MatrixExpansionTile(
              titleContent: [
                Math.tex(
                  r'\text{Eigenvectors}',
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
              childrenContent: eigenvectorSteps.map((step) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(step, textStyle: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ),
      ],
    );
  }
}
