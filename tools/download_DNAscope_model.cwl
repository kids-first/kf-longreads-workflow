cwlVersion: v1.2
class: CommandLineTool
label: Download DNAscope model bundle
hints:
  - class: ResourceRequirement
    coresMin: 1
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: python:3.7-slim
  - class: InitialWorkDirRequirement
    listing:
      - entryname: get_dnascope_model.py
        entry: |
          #!/usr/bin/env python3
          
          import argparse
          import yaml
          import requests
          import sys
          
          def main():
              parser = argparse.ArgumentParser(description="Download DNAscope model bundle")
              parser.add_argument("model_name", help="the name of the model bundle, e.g. Illumina_WGS")
              args = parser.parse_args()
              model_name = args.model_name.split("-")
              sentieon_models_yaml = "https://github.com/Sentieon/sentieon-models/raw/refs/heads/main/sentieon_models.yaml"
              response = requests.get(sentieon_models_yaml, allow_redirects=True)
              content = response.content.decode("utf-8")
              content = yaml.safe_load(content)
              try:
                  url = content["DNAscope_bundles"][model_name[0]][model_name[1]]
                  r = requests.get(url, allow_redirects=True)
                  open(url.split("/")[-1], 'wb').write(r.content)
              except:
                  open('empty.bundle', 'wb')
              print('Models updated on: ' + content["Updated on"], file=sys.stderr)
          
          if __name__ == '__main__':
              main()


arguments:
  - position: 0
    valueFrom: 'pip install pyyaml requests;'
    shellQuote: false
  - position: 1
    valueFrom: 'python get_dnascope_model.py'
    shellQuote: false
inputs:
  - id: model_name
    label: Model name
    doc: Model platform and data type. For example, Illumina_WGS
    type: 
    - type: enum
      symbols:
        - Illumina-WGS
        - Illumina-WES
        - MGI-WGS
        - MGI-WES
        - Element_Biosciences-WGS
        - PacBio_HiFi-WGS
        - Oxford_Nanopore-WGS
    inputBinding:
      position: 2
outputs:
  - id: model_bundle
    label: DNAscope Model bundle
    type: File
    outputBinding:
      glob: '*.bundle'

