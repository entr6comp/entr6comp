using Antlr4.Runtime;
using System;
using System.IO;

namespace Compilador
{
    class Expressao
    {
        MMMLLexer lexer;
        MMMLParser parser;

        public Expressao()
        {
            try
            {
                string caminhoApp = AppDomain.CurrentDomain.BaseDirectory;
                caminhoApp = caminhoApp.Substring(0, caminhoApp.IndexOf("bin") - 1);
                string arquivo = Path.Combine(caminhoApp, "entrada.txt");

                StreamReader file = new StreamReader(arquivo);
                lexer = new MMMLLexer(new AntlrInputStream(file));
                CommonTokenStream tokens = new CommonTokenStream(lexer);
                parser = new MMMLParser(tokens);

                var res = parser.funcbody();
                string msgRetorno = string.Empty;

                if (parser.qtdErro > 0)
                    msgRetorno = "Expressão inválida";
                //else
                //msgRetorno = string.Format("Tipo: {0}", res.oType != null ? res.oType.Name : "Não encontrado");

                if (!string.IsNullOrEmpty(msgRetorno))
                    Console.WriteLine(msgRetorno);

                file.Close();
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