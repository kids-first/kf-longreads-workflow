cwlVersion: v1.2
class: CommandLineTool
id: clt_rg_samplename 
doc: |
  Given an file with RG lines, return the sample name in the SM tag. 
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
  cpu: { type: 'int?', default: 8, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  sample_name:
    type: string?
    outputBinding:
      outputEval: |
        ${
          var rgs = inputs.rg.contents.trim().split('\n');
          var old_sms = rgs.map(function(e) { return e.split('\t').filter(function(e) { return e.search(/^SM/) != -1 })[0] });
          var uniq_sms = old_sms.filter(function(v, i, a) { return v != null && a.indexOf(v) === i });
          if (uniq_sms.length == 0) {
            return null;
          } else {
            return uniq_sms[0].split(":")[1];
          }
        }
