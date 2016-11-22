using System;
using Antlr4.Runtime;

namespace Compilador
{
    public class Numbers
    {
        private NumbersLexer lexer;
        private IToken tk;

        public Numbers()
        {
            try
            {
                Console.Write("Entrada: ");
                lexer = new NumbersLexer(new AntlrInputStream(Console.In));

                do
                {
                    tk = lexer.NextToken();
                    string sType = string.Empty;

                    switch (tk.Type)
                    {
                        case NumbersLexer.BINARY:
                            sType = "INTEIRO BINÁRIO";
                            break;
                        case NumbersLexer.DECIMAL:
                            sType = "INTEIRO DECIMAL";
                            break;
                        case NumbersLexer.REAL_DECIMAL:
                            sType = "REAL DECIMAL";
                            break;
                        case NumbersLexer.HEXA_DECIMAL:
                            sType = "INTEIRO HEXADECIMAL";
                            break;
                        default:
                            sType = string.Empty;
                            break;
                    }
                    if (!string.IsNullOrEmpty(sType))
                        Console.WriteLine(string.Format("{0}: {1}", sType, tk.Text));
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
    }
}