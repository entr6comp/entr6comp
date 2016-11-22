using System;
using System.Collections;
using Antlr4.Runtime;

namespace Compilador
{
    class Pilha : Stack
    {
        private NumbersLexer lexer;
        private IToken tk;
        private Stack stack = new Stack();

        public Pilha()
        {
            try
            {
                Console.Write("Entrada: ");
                lexer = new NumbersLexer(new AntlrInputStream(Console.In));

                do
                {
                    tk = lexer.NextToken();

                    switch (tk.Type)
                    {
                        //case NumbersLexer.OPERADOR:
                          //  CalcularExpressao();
                            //break;
                        case NumbersLexer.STATUS:
                            int index = 1;
                            foreach (double d in stack)
                            {
                                Console.WriteLine(string.Format("${0} = {1}", index, d));
                                index++;
                            }
                            break;
                        case NumbersLexer.RESET:
                            stack.Clear();
                            Console.WriteLine("empty");
                            break;
                        case NumbersLexer.BINARY:
                            AdicionarElemento(Convert.ToInt32(tk.Text.Remove(tk.Text.Trim().Length - 1), 2).ToString());
                            break;
                        case NumbersLexer.DECIMAL:
                        case NumbersLexer.REAL_DECIMAL:
                            AdicionarElemento(tk.Text);
                            break;
                        case NumbersLexer.HEXA_DECIMAL:
                            AdicionarElemento(Convert.ToInt32(tk.Text, 16).ToString());
                            break;
                    }
                }
                while (tk != null && tk.Type != NumbersLexer.Eof); //CTRL-Z (Windows)
            }
            catch (Exception ex)
            {
                Console.WriteLine("Erro: " + ex);
                //Environment.Exit(1);
                return;
            }
        }

        private void AdicionarElemento(object input)
        {
            stack.Push(Convert.ToDouble(input));
            Console.WriteLine("$1 = " + stack.Peek());
        }

        private void CalcularExpressao(bool operador = true)
        {
            if (stack.Count < 2)
            {
                Console.WriteLine("Erro: Pilha vazia.");
                return;
            }

            double numero1 = Convert.ToDouble(stack.Pop());
            double numero2 = Convert.ToDouble(stack.Pop());
            double? resultado = null;

            switch (tk.Text)
            {
                case "+":
                    resultado = numero2 + numero1;
                    break;
                case "-":
                    resultado = numero2 - numero1;
                    break;
                case "*":
                    resultado = numero2 * numero1;
                    break;
                case "/":
                    if (numero1 == 0)
                    {
                        Console.WriteLine("Erro: Divisão por zero.");
                        stack.Push(numero2);
                        stack.Push(numero1);
                    }
                    else
                        resultado = numero2 / numero1;
                    break;
                case "^":
                    resultado = Math.Pow(Convert.ToDouble(numero2), Convert.ToDouble(numero1));
                    break;
            }

            if (resultado.HasValue)
                AdicionarElemento(resultado);
        }
    }
}