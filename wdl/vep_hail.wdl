version 1.0

import "Structs.wdl"

workflow HailVep {
  input {
    String prefix
    File vcf
    File eval_region_1
    File eval_region_2
    File loftee_json
    String sv_pipeline_hail_docker
    RuntimeAttr? runtime_override_hail_vep
  }

  call HailVepTask {
    input:
      vcf = vcf,
      prefix = prefix,
      eval_region_2 = eval_region_2,
      eval_region_1 = eval_region_1,
      loftee_json = loftee_json,
      sv_pipeline_hail_docker=sv_pipeline_hail_docker,
      runtime_attr_override=runtime_override_hail_vep
  }

  output {
  }
}

task HailVepTask {
  input {
    File vcf
    File eval_region_1
    File eval_region_2
    File loftee_json
    String prefix
    String sv_pipeline_hail_docker
    RuntimeAttr? runtime_attr_override
  }

  parameter_meta {
    vcf: {
      localization_optional: true
    }
  }

  String cluster_name_prefix="gatk-sv-cluster-"

  RuntimeAttr runtime_default = object {
                                  mem_gb: 15,
                                  disk_gb: 200,
                                  cpu_cores: 1,
                                  preemptible_tries: 0,
                                  max_retries: 1,
                                  boot_disk_gb: 10
                                }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: select_first([runtime_override.mem_gb, runtime_default.mem_gb]) + " GB"
    disks: "local-disk " + select_first([runtime_override.disk_gb, runtime_default.disk_gb]) + " SSD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_hail_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -euxo pipefail

    python <<CODE
import hail as hl
from pprint import pprint

hl.init()

from hail.genetics.pedigree import Pedigree
from hail.matrixtable import MatrixTable
from hail.expr import expr_float64
from hail.table import Table
from hail.typecheck import typecheck, numeric
from hail.methods.misc import require_biallelic

filepath = "~{vcf}"

mt = hl.import_vcf(filepath, array_elements_required = False, reference_genome = 'GRCh38', force_bgz=True)
meta = hl.methods.get_vcf_metadata(filepath)

mt = mt.annotate_globals(metadata = hl.Struct(**meta))

mt = mt.annotate_rows(num_alleles = mt.alleles.size())

#split_multi_hts() will create two biallelic variants (one for each alternate allele) at the same position
mt = hl.split_multi_hts(mt)

evaluation_regions = hl.import_locus_intervals('~{eval_region_1}', reference_genome = 'GRCh38')

evaluation_regions_pm2 = hl.import_locus_intervals('~{eval_region_2}', reference_genome = 'GRCh38')
evaluation_regions.show()

mt = hl.vep(mt, '~{loftee_json}')
mt = mt.annotate_rows(eval_reg = hl.is_defined(evaluation_regions[mt.locus]), eval_reg_pm2 = hl.is_defined(evaluation_regions_pm2[mt.locus]))

mt.write("fd_dataset_split_vep_docker.mt")
CODE
  >>>

  output {
  }
}
