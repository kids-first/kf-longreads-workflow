cwlVersion: v1.2
class: ExpressionTool
id: expression_preparerg
requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu)
    ramMin: $(inputs.ram * 1000)
inputs:
  rg:
    type: File?
    inputBinding: {loadContents: true}
  sample: { type: 'string?' }
  cpu: { type: 'int?', default: 8, doc: "CPUs to allocate to this task." }
  ram: { type: 'int?', default: 16, doc: "RAM (in GB) to allocate to this task." }
outputs:
  rg_str: { type: string }

expression: |
  ${
      if (inputs.rg == null) {return {rg_str: null}};
      var arr = inputs.rg.contents.split('\n')[0].split('\t');
      if (arr.some(function(e) { return e.search(/^SM/) != -1 } ) ) {
        for (var i=1; i<arr.length; i++) {
          if (arr[i].search(/^SM/) != -1) {
            arr[i] = 'SM:' + inputs.sample;
            break;
          }
        }
      } else {
        arr.push("SM:" + inputs.sample);
      }
      return {rg_str: arr.join('\\t')};
  }
