using Antlr4.Runtime;
using System;
using System.Globalization;
using System.Threading;

namespace Compilador
{
    class Program
    {
        static void Main(string[] args)
        {
            Thread.CurrentThread.CurrentCulture = CultureInfo.InvariantCulture;

            Expressao ex = new Expressao();
            //NestedTest teste = new NestedTest();
        }
    }
}
