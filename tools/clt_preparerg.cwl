cwlVersion: v1.2
class: CommandLineTool 
id: clt_preparerg
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
baseCommand: [echo, done]
inputs:
  rg:
    type: File
    loadContents: true
  sample: { type: 'string?' }
  cpu: { type: 'int?', default: 8, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  rg_str:
    type: string
    outputBinding:
      outputEval: |
        ${
            var rgs = inputs.rg.contents.trim().split('\n');
            var out = rgs.map(function(e) {
              rg_line = e.split("\t");
              old_sm = rg_line.filter(function(el) { return el.search(/^SM/) != -1 })[0];
              new_sm = (inputs.sample != null ? "SM:" + inputs.sample : old_sm != null ? old_sm : "SM:UNKNOWN");
              if (old_sm == null) {
                rg_line.push(new_sm);
              } else {
                rg_line[rg_line.indexOf(old_sm)] = new_sm;
              }
              return rg_line.join('\\t');
            });
            return out.join('\n');
        }
  sample_name:
    type: string
    outputBinding:
      outputEval: |
        ${
            var arr = inputs.rg.contents.trim().split('\t');
            var old_sms = arr.filter(function(e) { return e.search(/^SM/) != -1 });
            var new_sm = (inputs.sample != null ? inputs.sample : old_sms.length == 0 ? "UNKNOWN" : old_sms[0].split(":")[1]);
            if (old_sms.length == 0) {
              arr.push("SM:" + new_sm);
            } else {
              arr[arr.indexOf(old_sms[0])] = "SM:" + new_sm;
            }
            return new_sm;
        }
