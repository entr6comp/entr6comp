using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Compilador
{
    public class SymbolEntry<T>
    {
        #region Propriedades

        public T Symbol;
        public int Offset;
        public int Size;
        public string Name;

        #endregion Propriedades

        #region Construtor

        public SymbolEntry(string name, T symbol, int offset, int size)
        {
            Name = name;
            Symbol = symbol;
            Offset = offset;
            Size = size;
        }

        #endregion Construtor

        #region Métodos Públicos

        override public string ToString()
        {
            return string.Format("{0} pos {1} type {2}", Name, Offset, Symbol != null ? Symbol.ToString().Replace("System.", "") : "");
        }

        #endregion Métodos Públicos
    }

    public class NestedSymbolTable<T> : IEnumerable<SymbolEntry<T>>
    {
        #region Atributos

        private int _baseOffset = 0,
                    _nextOffset = 0,
                    _size = 0,
                    _entriesCount = 0;

        private Dictionary<string, SymbolEntry<T>> _storage;

        #endregion Atributos

        #region Propriedades

        public NestedSymbolTable<T> Parent { get; set; }

        public List<NestedSymbolTable<T>> Nested { get; set; }

        public int BaseOffset
        {
            get { return _baseOffset; }
        }

        public int Size
        {
            get { return _size; }
        }

        public int Count
        {
            get { return _entriesCount; }
        }

        public int NestedCount
        {
            // Function: NestedCount (property), get 
            // Description: How many entries are there (total) in the whole symbol-table tree
            // beginning at this one?
            get
            {
                if (Nested.Count == 0) return Count;
                else
                {
                    return Nested.Select(t => t.NestedCount).Max();
                }
            }
        }

        public int NestedSize
        {
            // Function: NestedSize (property), get
            // Description: What is the size needed to store the symbols in the symbol-table
            // tree beginning at this one?
            get
            {
                if (Nested.Count == 0) return Size;
                else
                {
                    return Nested.Select(t => t.NestedSize).Max();
                }
            }
        }

        #endregion Propriedades

        #region Métodos Privados

        /// <summary>
        /// Stores in values all the entries in the current table and its parents as well
        /// </summary>
        /// <param name="current"></param>
        /// <param name="values"></param>
        /// <returns></returns>
        private int RecursiveFillEntries(NestedSymbolTable<T> current,
                                         SymbolEntry<T>[] values)
        {
            if (current == null)
                return 0;
            else
            {
                int offset = RecursiveFillEntries(current.Parent, values);
                current._storage.Values.CopyTo(values, offset);
                return offset + current._storage.Count;
            }
        }

        #endregion Métodos Privados

        #region Métodos Públicos

        /// <summary>
        /// Creates a new symbol table, child of parent, starting in the specified offset
        /// </summary>
        /// <param name="parent"></param>
        /// <param name="offset"></param>
        public NestedSymbolTable(NestedSymbolTable<T> parent, int offset)
        {
            Parent = parent;
            _baseOffset = offset;
            _nextOffset = offset;
            _storage = new Dictionary<string, SymbolEntry<T>>();
            Nested = new List<NestedSymbolTable<T>>();
            if (parent != null)
            {
                _entriesCount = parent._entriesCount;
                parent.Nested.Add(this);
            }
            else
                _entriesCount = 0;
        }

        /// <summary>
        /// Created a new fist-level symbol table
        /// </summary>
        public NestedSymbolTable() : this(null, 0) { }

        /// <summary>
        /// Creates a new symbol table nested within parent
        /// </summary>
        /// <param name="parent"></param>
        public NestedSymbolTable(NestedSymbolTable<T> parent)
            : this(parent, (parent == null ? 0 : parent._nextOffset))
        { }

        /// <summary>
        /// This table won't be used, remove it from parent list along with all it's children
        /// </summary>
        public void Discard()
        {
            if (Parent != null)
                Parent.Nested.Remove(this);
        }

        /// <summary>
        /// Stores a symbol on the symbol table. Default size of the
        /// symbol on memory is 1. If there is a name clash, discards
        /// the old symbol.This may leave holes in the memory, could be optimized
        /// </summary>
        /// <param name="name"></param>
        /// <param name="symbol"></param>
        /// <param name="size"></param>
        /// <returns></returns>
        public int Store(string name, T symbol, int size = 1)
        {
            int symbolOffset = this._nextOffset;
            if (!_storage.ContainsKey(name))
                this._entriesCount++;
            this._size += size;
            this._nextOffset += size;

            _storage[name] = new SymbolEntry<T>(name, symbol, symbolOffset, size);

            return symbolOffset;
        }

        /// <summary>
        /// Looks up the simbol and gives the entry. Offset is absolute, from the root of the tree.
        /// For relative offsets, do var se = table.lookup(text); 
        /// int relOffset = se.offset - table.BaseOffset
        /// </summary>
        /// <param name="symbol"></param>
        /// <param name="maxLevel"></param>
        /// <returns></returns>
        public SymbolEntry<T> Lookup(string symbol, int maxLevel = int.MaxValue)
        {
            var cur_table = this;

            while (cur_table != null && maxLevel > 0)
            {
                if (cur_table._storage.ContainsKey(symbol))
                {
                    return cur_table._storage[symbol];
                }

                cur_table = cur_table.Parent;

                maxLevel--;
            }

            return default(SymbolEntry<T>); // null
        }

        /// <summary>
        ///  Returns an enumerator over the sorted array of entries
        ///  We fill entries with recursiveFillEntries, which will store
        ///  in the array the entries of the parents and the current
        /// </summary>
        /// <returns></returns>
        public IEnumerator<SymbolEntry<T>> GetEnumerator()
        {
            SymbolEntry<T>[] values = new SymbolEntry<T>[this._entriesCount];
            RecursiveFillEntries(this, values);
            Array.Sort(values, (a, b) => b.Offset.CompareTo(a.Offset));

            foreach (var i in values)
            {
                yield return i;
            }
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return this.GetEnumerator();
        }

        #endregion Métodos Públicos
    }

    public class NestedTest
    {
        public NestedTest()
        {
            var mt = new NestedSymbolTable<int>();
            mt.Store("lala", 0);
            mt.Store("lele", 1);
            var nt1 = new NestedSymbolTable<int>(mt);
            nt1.Store("lala", 10);
            var nt2 = new NestedSymbolTable<int>(mt);
            nt2.Store("lala", 11);

            foreach (var entry in nt2)
            {
                Console.WriteLine("nt2 Entry: {0}", entry);
            }

            foreach (var entry in nt1)
            {
                Console.WriteLine("nt1 Entry: {0}", entry);
            }

            foreach (var entry in mt)
            {
                Console.WriteLine("mt Entry: {0}", entry);
            }
        }
    }
}
