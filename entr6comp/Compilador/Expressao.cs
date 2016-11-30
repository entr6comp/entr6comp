using Antlr4.Runtime;
using System;
using System.Collections.Generic;
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
                else
                {
                    Stack<object> pilhaSimbolo = parser.PilhaSimbolo;
                    if (pilhaSimbolo != null && pilhaSimbolo.Count >= 1)
                    {
                        object resultado = pilhaSimbolo.Pop();
                        msgRetorno = string.Format("Resultado final: {0} (type {1})", resultado, res.oType.Name);
                    }
                }

                if (!string.IsNullOrEmpty(msgRetorno))
                {
                    Console.WriteLine(msgRetorno);
                    Console.WriteLine("-------------------------------");
                }

                file.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Erro: " + ex);
                return;
            }
        }
    }
}