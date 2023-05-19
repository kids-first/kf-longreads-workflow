cwlVersion: v1.2
class: ExpressionTool
id: expression_preparerg
doc: |
  Given an file with a single RG line, update the read group sample.
  Read group sample will be named in the following priority:
  1. input sample value
  2. old SM value
  3. UNKNOWN
  Return a read group string that can be fed to minimap2 command line and the chosen sample name.
requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
inputs:
  rg:
    type: File
    inputBinding: {loadContents: true}
  sample: { type: 'string?' }
  cpu: { type: 'int?', default: 8, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  rg_str: { type: string }
  sample_name: { type: 'string?' }

expression: |
  ${
      var arr = inputs.rg.contents.trim().split('\t');
      var old_sms = arr.filter(function(e) { return e.search(/^SM/) != -1 });
      var new_sm = (inputs.sample != null ? inputs.sample : old_sms.length == 0 ? "UNKNOWN" : old_sms[0].split(":")[1]);
      if (old_sms.length == 0) {
        arr.push("SM:" + new_sm);
      } else {
        arr[arr.indexOf(old_sms[0])] = "SM:" + new_sm;
      }
      return {rg_str: arr.join('\\t'), sample_name: new_sm};
  }
