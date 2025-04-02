import sympy as sp
from sympy.parsing.sympy_parser import (parse_expr, standard_transformations, implicit_multiplication_application)
from flask import Flask, request, jsonify
import re

app = Flask(__name__)

transformations = standard_transformations + (implicit_multiplication_application,)

def extract_symbols(matrix_data):
    symbol_pattern = r'[a-zA-Z]'
    symbols = set()
    for row in matrix_data:
        for value in row:
            if isinstance(value, str):
                symbols.update(re.findall(symbol_pattern, value))
    return {symbol: sp.Symbol(symbol) for symbol in symbols}

def parse_matrix(matrix_data):
    local_dict = extract_symbols(matrix_data)
    try:
        for row in matrix_data:
            for value in row:
                if isinstance(value, str) and ' ' in value.strip():
                    raise ValueError(f"Invalid matrix entry '{value}'. Please enter one number or expression per cell without spaces.")
        
        matrix = sp.Matrix([
            [
                parse_expr(str(value).replace('^', '**'), transformations=transformations, local_dict=local_dict)
                for value in row
            ]
            for row in matrix_data
        ])
        return matrix
    except Exception as e:
        raise ValueError(f"Invalid input detected: {e}")

def format_augmented_matrix(matrix, formatter):
    left = matrix[:, :matrix.shape[0]]
    right = matrix[:, matrix.shape[0]:]
    rows = []
    for i in range(matrix.shape[0]):
        left_row = ' & '.join([sp.latex(formatter(left[i, j])) for j in range(left.shape[1])])
        right_row = ' & '.join([sp.latex(formatter(right[i, j])) for j in range(right.shape[1])])
        rows.append(f"{left_row} & {right_row}")
    latex_matrix = r'\left[ \begin{array}{' + 'c' * left.shape[1] + '|' + 'c' * right.shape[1] + '}'
    latex_matrix += r'\\'.join(rows)
    latex_matrix += r'\end{array} \right]'
    return latex_matrix

def full_factor(expr):
    if isinstance(expr, sp.Expr) and expr.is_RationalFunction():
        num, den = sp.fraction(expr)
        return sp.Mul(sp.factor(num), 1 / sp.factor(den), evaluate=False)
    return sp.factor(sp.together(sp.simplify(expr)))
    
def matrix_inversion_steps(matrix, formatter):
    steps = []
    n = matrix.shape[0]
    identity = sp.eye(n)
    augmented = matrix.row_join(identity)

    steps.append(r"\quad \text{Apply ERO}")
    steps.append(format_augmented_matrix(augmented, formatter))

    for i in range(n):
        pivot = augmented[i, i]
        if pivot != 1:
            detailed_matrix = []
            for idx in range(n):
                row = []
                for j in range(augmented.shape[1]):
                    if idx == i:
                        row.append(f"\\frac{{1}}{{{sp.latex(formatter(pivot))}}}({sp.latex(formatter(augmented[idx, j]))})")
                    else:
                        row.append(sp.latex(formatter(augmented[idx, j])))
                detailed_matrix.append(' & '.join(row))
            simplified_matrix = augmented.copy()
            simplified_matrix.row_op(i, lambda v, _: sp.simplify(v / pivot))
            steps.append(rf"R_{{{i + 1}}} \to \frac{{1}}{{{sp.latex(formatter(pivot))}}} R_{{{i + 1}}}")
            steps.append(
                r'\left[ \begin{array}{' + 'c' * n + '|' + 'c' * n + '}' +
                r'\\'.join(detailed_matrix) +
                r'\end{array} \right] = ' +
                format_augmented_matrix(simplified_matrix, formatter)
            )
            augmented = simplified_matrix

        for j in range(n):
            if i != j:
                factor = augmented[j, i]
                if factor != 0:
                    detailed_matrix = []
                    for idx in range(n):
                        row = []
                        for k in range(augmented.shape[1]):
                            if idx == j:
                                row.append(f"({sp.latex(formatter(augmented[j, k]))}) - ({sp.latex(formatter(factor))} * {sp.latex(formatter(augmented[i, k]))})")
                            else:
                                row.append(sp.latex(formatter(augmented[idx, k])))
                        detailed_matrix.append(' & '.join(row))
                    simplified_matrix = augmented.copy()
                    simplified_matrix.row_op(j, lambda v, k: sp.simplify(v - factor * augmented[i, k]))
                    steps.append(rf"R_{{{j + 1}}} \to R_{{{j + 1}}} - ({sp.latex(formatter(factor))}) R_{{{i + 1}}}")
                    steps.append(
                        r'\left[ \begin{array}{' + 'c' * n + '|' + 'c' * n + '}' +
                        r'\\'.join(detailed_matrix) +
                        r'\end{array} \right] = ' +
                        format_augmented_matrix(simplified_matrix, formatter)
                    )
                    augmented = simplified_matrix

    inverse = augmented[:, n:]
    return inverse, steps

@app.route('/matrix_inverse', methods=['POST'])
def matrix_inverse():
    try:
        data = request.get_json()
        matrix_data = data.get('matrix')
        format_type = data.get("format", "factored")

        if not matrix_data:
            return jsonify({"error": "No matrix provided"}), 400

        matrix = parse_matrix(matrix_data)
        determinant = matrix.det()

        if determinant == 0:
            return jsonify({"error": "Matrix is singular and cannot be inverted"}), 400

        # Choose formatter
        if format_type == "factored":
            formatter = lambda expr: sp.cancel(sp.together(sp.simplify(expr)))
        elif format_type == "expanded":
            formatter = lambda expr: sp.expand(sp.cancel(sp.together(sp.simplify(expr))))
        else:
            formatter = sp.simplify

        # Get inverse and steps
        inverse_matrix, steps = matrix_inversion_steps(matrix, formatter)

        # After computing inverse_matrix
        simplified_inverse = inverse_matrix.applyfunc(formatter)

        # Extract numerators only
        numerators_only = [
            [sp.latex(sp.fraction(expr)[0]) for expr in row]
            for row in simplified_inverse.tolist()
        ]

        # Extract the full simplified determinant (used as denominator outside the matrix)
        determinant_latex = sp.latex(sp.simplify(determinant))

        return jsonify({
            "inverse": numerators_only,
            "determinant": determinant_latex,
            "steps": steps
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/eigen', methods=['POST'])
def eigen():
    try:
        data = request.get_json()
        matrix_data = data.get('matrix')

        if not matrix_data:
            return jsonify({"error": "No matrix provided"}), 400

        matrix = parse_matrix(matrix_data)
        n = matrix.shape[0]
        λ = sp.Symbol('λ')
        identity = sp.eye(n)

        lambda_I_minus_A = λ * identity - matrix
        characteristic_poly = sp.simplify(lambda_I_minus_A.det())
        eigenvals = sp.solve(characteristic_poly, λ)

        eigenval_steps = [
            r"\text{Step 1: Form } \lambda I - A",
            r"\lambda I - A = " + sp.latex(lambda_I_minus_A),
            r"\text{Step 2: Calculate } \det(\lambda I - A) = 0",
            r"\det(\lambda I - A) = " + sp.latex(characteristic_poly)
        ]

        for i, val in enumerate(eigenvals, start=1):
            eigenval_steps.append(rf"\lambda_{{{i}}} = {sp.latex(val)}")

        eigenvec_steps = [r"\text{Step 3: } (\lambda I - A)\vec{v} = 0"]

        for val in eigenvals:
            lambdaI_minus_A_val = val * identity - matrix
            eigenvec_steps.append(rf"\lambda = {sp.latex(val)}:")
            eigenvec_steps.append(
                r"\left(" + sp.latex(lambdaI_minus_A_val) + r"\right)\vec{v} = 0"
            )

            # Solve Ax = 0 manually
            A_eq = lambdaI_minus_A_val
            x, y = sp.symbols('x y')
            vec = sp.Matrix([x, y])
            eqs = A_eq * vec

            # Show equation system
            eigenvec_steps.append(
                r"\Rightarrow " + sp.latex(A_eq[0, 0]) + "x + " + sp.latex(A_eq[0, 1]) + "y = 0"
            )
            if n > 1:
                eigenvec_steps.append(
                    r"\Rightarrow " + sp.latex(A_eq[1, 0]) + "x + " + sp.latex(A_eq[1, 1]) + "y = 0"
                )

            # Try solving the symbolic system
            sols = sp.solve([eqs[0], eqs[1]], (x, y), dict=True)
            if sols:
                for s in sols:
                    simplified = sp.Matrix([s[x] if x in s else x, s[y] if y in s else y])
                    eigenvec_steps.append(
                        r"\Rightarrow \vec{v} = " + sp.latex(simplified)
                    )

            # Also show nullspace vector for generality
            nullspace = A_eq.nullspace()
            if nullspace:
                for idx, v in enumerate(nullspace, 1):
                    eigenvec_steps.append(
                        rf"\vec{{v}}_{{\lambda={sp.latex(val)}}}^{idx} = " + sp.latex(v)
                    )
            else:
                eigenvec_steps.append(
                    rf"\text{{No non-trivial eigenvector found for }} \lambda = {sp.latex(val)}"
                )

        return jsonify({
            "eigenvalues": eigenval_steps,
            "eigenvectors": eigenvec_steps
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)