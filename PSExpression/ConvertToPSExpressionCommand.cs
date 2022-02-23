using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace PSExpression
{
    [Cmdlet(VerbsData.ConvertTo,"PSExpression")]
    [OutputType(typeof(String))]
    public class ConvertToPSExpressionCommand : PSCmdlet
    {
        #region Parameters
        /// <summary>
        /// The object to serialize.
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true
        )]
        [AllowNull]
        public object InputObject { get; set; }

        /// <summary>
        /// Gets or sets the Depth property.
        /// </summary>
        [Parameter()]
        [ValidateRange(0, 100)]
        public int Depth { get; set; }
        #endregion Parameters

        private string InexpressibleArgument() => throw new ArgumentException(
            $"Cannot express value '{InputObject.ToString()}' of type {InputObject.GetType().FullName} as a PowerShell expression.",
            nameof(InputObject)
        );

        private string ConvertObject(object inputObject) => inputObject switch
        {
            null => "$null",

            bool i => i ? "$true" : "$false",

            float i when float.IsNaN(i) || float.IsInfinity(i) => InexpressibleArgument(),

            double i when double.IsNaN(i) || double.IsInfinity(i) => InexpressibleArgument(),

            var i when i.GetType().IsPrimitive => i.ToString(),

            string i => $"'{i}'",

            DateTime i => $"[datetime]'{i.ToString("u")}'",

            Version i => $"[version]'{i}'",

            Enum i => $"'{i}'",

            ScriptBlock i => $"{{{i.ToString()}}}",

            IList i => $"@({ConvertList(i)})",

            IOrderedDictionary i => $"[ordered]@{{{ConvertDictionary(i)}}}",

            IDictionary i => $"@{{{ConvertDictionary(i)}}}",

            _ => InexpressibleArgument()
        };

        private string ConvertList(IList inputObject)
        {
            var elementStrings = new List<string>();
            foreach (var e in inputObject)
            {
                var elementString = ConvertObject(e);
                elementStrings.Add(elementString);
            }
            return string.Join(", ", elementStrings);
        }

        private string ConvertDictionary(IDictionary inputObject)
        {
            var safeKeyRegex = new Regex("^[a-z][a-z0-9]*$", RegexOptions.IgnoreCase);

            var elementStrings = new List<string>();
            foreach (DictionaryEntry kvp in inputObject)
            {
                var key = ConvertObject(kvp.Key);
                var value = ConvertObject(kvp.Value);

                var unquotedKey = key.Length > 1 && key[0] == '\'' && key[key.Length - 1] == '\'' ?
                    key.Substring(1, key.Length - 2) :
                    key;
                key = safeKeyRegex.IsMatch(unquotedKey) ? unquotedKey : $"'{unquotedKey}'";

                var elementString = $"{key} = {value}";
                elementStrings.Add(elementString);
            }
            return string.Join("; ", elementStrings);
        }

        protected override void ProcessRecord()
        {
            string output = ConvertObject(InputObject);

            WriteObject(output);
        }
    }
}
