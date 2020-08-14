﻿using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Abstractions;
using vsteam_lib.Provider;

namespace vsteam_lib
{
   public class Agent : Directory
   {
      public string OS { get; }
      public long PoolId { get; }
      public bool Enabled { get; }
      public long AgentId { get; }
      public string Status { get; }
      public string Version { get; }
      public PSObject SystemCapabilities { get; }

      public Agent(PSObject obj, long poolId, IPowerShell powerShell) :
         base(obj, obj.GetValue<string>("name"), "JobRequest", powerShell, null)
      {
         this.PoolId = poolId;
         this.AgentId = obj.GetValue<long>("Id");
         this.Status = obj.GetValue<string>("status");
         this.Enabled = obj.GetValue<bool>("enabled");
         this.Version = obj.GetValue<string>("version");
         this.OS = obj.GetValue<string>("osDescription");
         this.SystemCapabilities = obj.GetValue<PSObject>("systemCapabilities");
      }

      public Agent(PSObject obj, long poolId) :
         this(obj, poolId, new PowerShellWrapper(RunspaceMode.CurrentRunspace))
      {
      }

      protected override object[] GetChildren()
      {
         this.PowerShell.Commands.Clear();

         var children = this.PowerShell.AddCommand(this.Command)
                                       .AddParameter("PoolId", this.PoolId)
                                       .AddParameter("AgentId", this.AgentId)
                                       .Invoke();

         PowerShellWrapper.LogPowerShellError(this.PowerShell, children);

         foreach (var child in children)
         {
            child.AddTypeName(this.TypeName);
         }

         return children.ToArray();
      }
   }
}