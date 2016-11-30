grammar MMML;

@header { 
using System;
using System.Linq;
using System.Collections;
}

@parser::members {
   public int qtdErro = 0 ;
   public Stack<object> PilhaSimbolo = new Stack<object>();
   public NestedSymbolTable<EntradaSimbolo> TabelaSimbolo = new NestedSymbolTable<EntradaSimbolo>();

	private void ImprimirTabelaSimbolo()
	{
		if (TabelaSimbolo != null && TabelaSimbolo.Count > 0)
		{	
			foreach (var entry in TabelaSimbolo.OrderBy(n => n.Offset))
			{
				Console.WriteLine("{0}", entry);
			}
		}
	}

	private void CalcularValor(string operador)
	{
		if (PilhaSimbolo.Count >= 2)
		{
			int valor1 = Convert.ToInt32((PilhaSimbolo.Pop()));
			int valor2 = Convert.ToInt32((PilhaSimbolo.Pop()));
			
			switch(operador)
			{
				case "+":
						PilhaSimbolo.Push(valor2 + valor1);
						break;
				case "-":
						PilhaSimbolo.Push(valor2 - valor1);
						break;
				case "*":
						PilhaSimbolo.Push(valor2 * valor1);
						break;
				case "/":
						if (valor1 > 0)
							PilhaSimbolo.Push(valor2 / valor1);
						else
							qtdErro++;
						break;
				case "^":
						PilhaSimbolo.Push((int)Math.Pow(Convert.ToDouble(valor2), Convert.ToDouble(valor1)));
						break;
			}
		}
		else
		{
			qtdErro++;
		}
	}

	private void ConcatenarValor()
	{
		if (PilhaSimbolo.Count >= 2)
		{
			string valor1 = PilhaSimbolo.Pop().ToString().Replace("\"", "");
			string valor2 = PilhaSimbolo.Pop().ToString().Replace("\"", "");
			PilhaSimbolo.Push(string.Concat(valor2, valor1));
		}
		else
		{
			qtdErro++;
		}		
	}

	private object BuscarValorTopo()
	{
		object valorTopo = null;

		if (PilhaSimbolo.Count >= 1)
			valorTopo = PilhaSimbolo.Pop();

		return valorTopo;
	}
}

options {
   language=CSharp_v4_5;
}
/*
Programa: Declarações de funções e uma função main SEMPRE

def fun x = x + 1

def main =
  let x = read_int
  in
     print concat "Resultado" (string (fun x))
*/

WS : [ \r\t\u000C\n]+ -> channel(HIDDEN)
    ;

COMMENT : '//' ~('\n'|'\r')* '\r'? '\n' -> channel(HIDDEN);

program
    : fdecls maindecl { Console.WriteLine("Parseou um programa!"); }
    ;

fdecls
    : fdecl fdecls                                   #fdecls_one_decl_rule
    |                                                #fdecls_end_rule
    ;

maindecl: 'def' 'main' '=' funcbody                  #programmain_rule
    ;

fdecl: 'def' functionname fdeclparams '=' funcbody   #funcdef_rule
        /*{
             Console.WriteLine("Achou declaração: {0} com {1}", $functionname.text, $fdeclparams.plist.ToString());
        }*/
    ;

fdeclparams
returns [List<string> plist]
@init {
    $plist = new List<string>();
}
@after {
    foreach (string s in $plist) {
         Console.WriteLine("Parametro: " + s);
    }
}
    :   fdeclparam
        {
            $plist.Add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]

                                                     #fdeclparams_one_param_rule
    |                                                #fdeclparams_no_params
    ;

fdeclparams_cont[List<string> plist]
    : ',' fdeclparam
        {
            $plist.Add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]
                                                     #fdeclparams_cont_rule
    |                                                #fdeclparams_end_rule
    ;

fdeclparam
    returns [string pname, string ptype]
    : symbol ':' type
        {
            $pname = $symbol.text;
            $ptype = $type.text;
        }
        #fdecl_param_rule
    ;

functionname: TOK_ID                                 #fdecl_funcname_rule
    ;

type
returns [Type oType]
	:
    b = basic_type { $oType = $b.oType; } #basictype_rule
	|
	sequence_type
    {
		Console.WriteLine("Variavel do tipo " + $sequence_type.base + " dimensao "+ $sequence_type.dimension);
    } #sequencetype_rule
    ;

basic_type
returns [Type oType]
    : 'int' { $oType = typeof(int); }
    | 'bool' { $oType = typeof(bool); }
    | 'str' { $oType = typeof(string); }
    | 'float' { $oType = typeof(float); }
    ;

sequence_type
returns [int dimension=0, string base]
    :   basic_type '[]'
        {
            $dimension = 1;
            $base = $basic_type.text;
        }

                                                     #sequencetype_basetype_rule
    |   s=sequence_type '[]'
        {
            $dimension = $s.dimension + 1;
            $base = $s.base;
        }
                                                     #sequencetype_sequence_rule
    ;

funcbody
returns [Type oType]
	:
        ifexpr                                       #fbody_if_rule
    |   letexpr       { $oType = $letexpr.oType; }   #fbody_let_rule
    |   metaexpr      { $oType = $metaexpr.oType; ImprimirTabelaSimbolo(); Console.WriteLine("-------------------------------"); }   #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
returns [NestedSymbolTable<EntradaSimbolo> oTabelaSimboloLocal, Type oType]
    : 'let' letlist 'in' { TabelaSimbolo = $letlist.oTabelaSimboloLocal; } funcbody { TabelaSimbolo = TabelaSimbolo.Parent; 
																					  $oType = $funcbody.oType; } #letexpression_rule
    ;

letlist
returns [NestedSymbolTable<EntradaSimbolo> oTabelaSimboloLocal]
	@init 
	{
		$oTabelaSimboloLocal = new NestedSymbolTable<EntradaSimbolo>(TabelaSimbolo);
		TabelaSimbolo = $oTabelaSimboloLocal;
	}
    : letvarexpr[$oTabelaSimboloLocal] { $oTabelaSimboloLocal.Store($letvarexpr.oTexto, 
																	new EntradaSimbolo() { Tipo = $letvarexpr.oType, 
																						   Valor = BuscarValorTopo() }); } 
	  letlist_cont[$oTabelaSimboloLocal] #letlist_rule
    ;

	letlist_cont [NestedSymbolTable<EntradaSimbolo> oTabelaSimboloLocal]
    : ',' letvarexpr[$oTabelaSimboloLocal] { $oTabelaSimboloLocal.Store($letvarexpr.oTexto, 
																		new EntradaSimbolo() { Tipo = $letvarexpr.oType, 
																							   Valor = BuscarValorTopo() }); } 
	      letlist_cont[$oTabelaSimboloLocal]
                                                  #letlist_cont_rule
    |											  #letlist_cont_end                                           
    ;

letvarexpr[NestedSymbolTable<EntradaSimbolo> oTabelaSimboloLocal]
returns [string oTexto, Type oType]
    :    symbol { $oTexto = $symbol.text; } '=' funcbody { $oType = $funcbody.oType; }              #letvarattr_rule
    |    '_'    '='  funcbody #letvarresult_ignore_rule
	|    l=symbol '::' r=symbol '=' funcbody #letunpack_rule
    ;

metaexpr
returns [Type oType]
    : '(' funcbody ')'                               { $oType = $funcbody.oType; } #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG symbol                                 { $oType = typeof(bool); }
                                                                 #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'                       { $oType = typeof(bool); } #me_boolnegparens_rule  //        or anything in between ( )
    | l=metaexpr TOK_POWER r=metaexpr
	{
		if ($l.oType == typeof(int) && $r.oType == typeof(int))
		{
		   $oType = typeof(int);
		   CalcularValor("^");
		}
		else if ($l.oType == typeof(float) && $r.oType == typeof(float))
		{
		   $oType = typeof(float);
		   CalcularValor("^");
		}
		else if (($l.oType == typeof(int) && $r.oType == typeof(float)) || ($r.oType == typeof(int) && $l.oType == typeof(float)))
		{
			$oType = typeof(float);
			CalcularValor("^");
		}
		else
		{
			qtdErro++;
		}
	} #me_exprpower_rule      // Exponentiation
    | l=metaexpr TOK_CONCAT r=metaexpr  
	{                  
		if($l.oType == typeof(string) && $r.oType == typeof(string))
		{
 			$oType = typeof(string);
			ConcatenarValor();
 		}
		else
		{
			qtdErro++;
 		}
	} #me_listconcat_rule     // Sequence concatenation
    | l=metaexpr TOK_DIV_OR_MUL r=metaexpr
    {
		if ($l.oType == typeof(int) && $r.oType == typeof(int))
		{
		   $oType = typeof(int);
		   CalcularValor($TOK_DIV_OR_MUL.text);
		}
		else if ($l.oType == typeof(float) && $r.oType == typeof(float))
		{
		   $oType = typeof(float);
		   CalcularValor($TOK_DIV_OR_MUL.text);
		}
		else if (($l.oType == typeof(int) && $r.oType == typeof(float)) || ($r.oType == typeof(int) && $l.oType == typeof(float)))
		{
			$oType = typeof(float);
			CalcularValor($TOK_DIV_OR_MUL.text);
		}
		else
		{
			qtdErro++;
		}
	} #me_exprmuldiv_rule     // Div and Mult are equal
    | l=metaexpr TOK_PLUS_OR_MINUS r=metaexpr
	{
		if ($l.oType == typeof(int) && $r.oType == typeof(int))
		{
		   $oType = typeof(int);
		   CalcularValor($TOK_PLUS_OR_MINUS.text);
		}
		else if ($l.oType == typeof(float) && $r.oType == typeof(float))
		{
		   $oType = typeof(float);
		   CalcularValor($TOK_PLUS_OR_MINUS.text);
		}
		else if (($l.oType == typeof(int) && $r.oType == typeof(float)) || ($r.oType == typeof(int) && $l.oType == typeof(float)))
		{
			$oType = typeof(float);
			CalcularValor($TOK_PLUS_OR_MINUS.text);
		}
		else
		{
			qtdErro++;
		}
	} #me_exprplusminus_rule  // Sum and Sub are equal
    | l=metaexpr TOK_CMP_GT_LT r=metaexpr                
	{
		if (($l.oType == typeof(int) || $l.oType == typeof(float)) && ($r.oType == typeof(int) || $r.oType == typeof(float)))
		{
			$oType = typeof(bool); 
		}
		else
		{
			qtdErro++;
		}
	} #me_boolgtlt_rule       // < <= >= > are equal
    | metaexpr TOK_CMP_EQ_DIFF metaexpr              { $oType = typeof(bool); }   #me_booleqdiff_rule  // == and != are egual
    | metaexpr TOK_BOOL_AND_OR metaexpr              { $oType = typeof(bool); }   #me_boolandor_rule   // &&   and  ||  are equal
    | symbol
	{
		SymbolEntry<EntradaSimbolo> symbolEntry = TabelaSimbolo.Lookup($symbol.text);
		if (symbolEntry != null)
		{
			if (symbolEntry.Symbol.Valor != null)
				PilhaSimbolo.Push(symbolEntry.Symbol.Valor);
			$oType = symbolEntry.Symbol.Tipo;
		}
		else
		{
			qtdErro++;
		}
	} #me_exprsymbol_rule  // a single symbol
    | literal 										 { PilhaSimbolo.Push($literal.oValor); $oType = $literal.oType; } #me_exprliteral_rule // literal value
    | funcall                                                                     #me_exprfuncall_rule // a funcion call
    | cast											 { $oType = $cast.oType; }    #me_exprcast_rule    // cast a type to other
    ;

sequence_expr
    : '[' funcbody ']'                               #se_create_seq
    ;

funcall: symbol funcall_params                       #funcall_rule
        /*{
             Console.WriteLine("Uma chamada de funcao! {0}", $symbol.text);
        }*/
    ;

cast
returns [Type oType]
	: type funcbody { $oType = $type.oType; } #cast_rule
    ;

funcall_params
    :   metaexpr funcall_params_cont                    #funcallparams_rule
    |   '_'                                             #funcallnoparam_rule
    ;

funcall_params_cont
    : metaexpr funcall_params_cont                      #funcall_params_cont_rule
    |                                                   #funcall_params_end_rule
    ;

literal
returns [object oValor, Type oType]
:
        'nil'                               #literalnil_rule
    |   'true' { $oType = typeof(bool); }   #literaltrue_rule
    |   number { $oValor = $number.text; $oType = $number.oType; }  #literalnumber_rule
    |   strlit { $oValor = $strlit.text; $oType = typeof(string); } #literalstring_rule
    |   charlit { $oValor = $charlit.text; $oType = typeof(char); } #literal_char_rule
    ;

strlit: TOK_STR_LIT
    ;

charlit
    : TOK_CHAR_LIT
    ;
	
 number
 returns [Type oType]
 :
        FLOAT { $oType = typeof(float); }     #numberfloat_rule
    |   DECIMAL { $oType = typeof(int); }     #numberdecimal_rule
    |   HEXADECIMAL { $oType = typeof(int); } #numberhexadecimal_rule
    |   BINARY { $oType = typeof(int); }      #numberbinary_rule
    ;

symbol
: TOK_ID
{

} #symbol_rule
;


// id: begins with a letter, follows letters, numbers or underscore
TOK_ID: [a-zA-Z]([a-zA-Z0-9_]*);

TOK_CONCAT: '::' ;
TOK_NEG: '!';
TOK_POWER: '^' ;
TOK_DIV_OR_MUL: ('/'|'*');
TOK_PLUS_OR_MINUS: ('+'|'-');
TOK_CMP_GT_LT: ('<='|'>='|'<'|'>');
TOK_CMP_EQ_DIFF: ('=='|'!=');
TOK_BOOL_AND_OR: ('&&'|'||');

TOK_REL_OP : ('>'|'<'|'=='|'>='|'<=') ;

TOK_STR_LIT
  : '"' (~[\"\\\r\n] | '\\' (. | EOF))* '"'
  ;


TOK_CHAR_LIT
    : '\'' (~[\'\n\r\\] | '\\' (. | EOF)) '\''
    ;

FLOAT : '-'? DEC_DIGIT+ '.' DEC_DIGIT+([eE][\+-]? DEC_DIGIT+)? ;

DECIMAL : '-'? DEC_DIGIT+ ;

HEXADECIMAL : '0' 'x' HEX_DIGIT+ ;

BINARY : BIN_DIGIT+ 'b' ; // Sequencia de digitos seguida de b  10100b

fragment
BIN_DIGIT : [01];

fragment
HEX_DIGIT : [0-9A-Fa-f];

fragment
DEC_DIGIT : [0-9] ;
