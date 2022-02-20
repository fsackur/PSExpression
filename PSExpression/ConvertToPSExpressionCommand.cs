using System;
using System.Management.Automation;

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

        protected override void ProcessRecord()
        {
        }
    }
}
