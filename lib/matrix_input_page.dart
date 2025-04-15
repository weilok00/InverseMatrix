import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'matrix_input.dart';
import 'matrix_output.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatrixInputPage extends StatefulWidget {
  @override
  _MatrixInputPageState createState() => _MatrixInputPageState();
}

class _MatrixInputPageState extends State<MatrixInputPage> {
  int matrixSize = 2;
  List<List<TextEditingController>> matrixControllers = [];
  String inverseMatrix = "";
  String determinantText = "";
  String errorMessage = "";
  bool showSteps = false;
  List<String> steps = [];
  List<String> eigenvalueSteps = [];
  List<String> eigenvectorSteps = [];
  bool showEigen = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _generateMatrix();
  }

  void _generateMatrix() {
    setState(() {
      matrixControllers = List.generate(
        matrixSize,
        (i) => List.generate(matrixSize, (j) => TextEditingController()),
      );
      inverseMatrix = "";
      errorMessage = "";
    });
  }

  void _computeInverse() async {
    List<List<String>> matrix = matrixControllers.map((row) {
      return row.map((controller) => controller.text).toList();
    }).toList();

    setState(() {
      eigenvalueSteps.clear();     // 👈 clear eigenvalue steps
      eigenvectorSteps.clear();    // 👈 clear eigenvector steps
      showEigen = false;           // 👈 hide eigen section
    });

    try {
      var response = await http.post(
        Uri.parse('http://localhost:5000/matrix_inverse'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'matrix': matrix}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        String determinantLatex = data['determinant']; //store denominator
        List<List<String>> inverseMatrixData = (data['inverse'] as List<dynamic>) //store numerator
            .map((row) => (row as List<dynamic>).map((e) => e.toString()).toList())
            .toList();
        List<String> stepsData = List<String>.from(data['steps']);

        setState(() {
          determinantText = determinantLatex;
          inverseMatrix = _formatInverseMatrixAsLatex(inverseMatrixData);
          errorMessage = "";
          steps = stepsData;
          showSteps = true;
        });

      } else {
        var data = jsonDecode(response.body);
        setState(() {
          errorMessage = data['error'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
      });
    }
  }

  void _clearMatrixInputs() {
    setState(() {
      for (var row in matrixControllers) {
        for (var controller in row) {
          controller.clear();
        }
      }
      inverseMatrix = "";
      determinantText = "";
      errorMessage = "";
      showSteps = false;
      steps.clear();
      
      showEigen = false;
      eigenvalueSteps.clear();
      eigenvectorSteps.clear();
  });
}

  void _computeEigen() async {
  List<List<String>> matrix = matrixControllers.map((row) {
    return row.map((controller) => controller.text).toList();
  }).toList();

  try {
    var response = await http.post(
      Uri.parse('http://localhost:5000/eigen'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'matrix': matrix}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        inverseMatrix = "";
        determinantText = "";
        steps.clear();
        showSteps = false;

        // set eigen
        eigenvalueSteps = List<String>.from(data['eigenvalues']);
        eigenvectorSteps = List<String>.from(data['eigenvectors']);
        showEigen = true;
      });

    } else {
      var data = jsonDecode(response.body);
      setState(() {
        errorMessage = data['error'];
        showEigen = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = "An error occurred: $e";
      showEigen = false;
    });
  }
}

  String _formatInputMatrixAsLatex() {
    String matrixString = r'\begin{bmatrix}';
    for (int i = 0; i < matrixSize; i++) {
      List<String> row = [];
      for (int j = 0; j < matrixSize; j++) {
        String value = matrixControllers[i][j].text;
        row.add(value.isEmpty ? "0" : value);
      }
      matrixString += row.join(' & ');
      if (i < matrixSize - 1) {
        matrixString += r'\\';
      }
    }
    matrixString += r'\end{bmatrix}';
    return matrixString;
  }

  String _formatInverseMatrixAsLatex(List<List<String>> matrix) {
    String matrixString = r'\left[\begin{array}{' + 'c' * matrix[0].length + '}';
    for (var row in matrix) {
      matrixString += row.join(' & ') + r'\\';
    }
    matrixString += r'\end{array}\right]';

    // Wrap the entire matrix with 1/determinant
    return r'\frac{1}{' + determinantText + r'} ' + matrixString;
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Math.tex(
              r'\text{Inverse \& Eigen Calculator}',
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Image.asset(
              'images/NTU.webp',
              height: 50,
              width: 50,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Math.tex(
                r'\text{Menu}',
                textStyle: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.tableCellsLarge), 
              title: Math.tex(r'\text{Inverse \& Eigen}'),
              onTap: () {   
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MatrixInput(
              matrixSize: matrixSize,
              matrixControllers: matrixControllers,
              onMatrixSizeChanged: (size) {
                setState(() {
                  matrixSize = size;
                  _generateMatrix();
                });
              },
              onComputeInverse: _computeInverse,
              onClear: _clearMatrixInputs,
              onComputeEigen: _computeEigen,
              computeButtonLabel: r'\text{Compute Inverse}',
            ),
            MatrixOutput(
              inputMatrix: _formatInputMatrixAsLatex(),
              determinantText: determinantText,
              inverseMatrix: inverseMatrix,
              errorMessage: errorMessage,
              showSteps: showSteps,
              steps: steps,
              eigenvalueSteps: eigenvalueSteps,
              eigenvectorSteps: eigenvectorSteps,
              showEigen: showEigen,
            ),
          ],
        ),
      ),
    );
  }
}
