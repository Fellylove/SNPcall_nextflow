#!/usr/bin/env nextflow
// This file for loading custom functions into the main.nf script (separated for portability)

// print --help information
def printHelp() {
    println """\

         =============================================
          E C S E Q - S N P c a l l   P I P E L I N E
         =============================================
         ~ version ${workflow.manifest.version}

         Usage: 
              nextflow run ecseq/dnaseq [OPTIONS]...

         Options: GENERAL
              --input [path/to/input/dir]     [REQUIRED] Provide the directory containing BAM file(s) in "*.bam" format

              --reference [path/to/ref.fa]    [REQUIRED] Provide the path to the reference genome in fasta format

              --output [STR]                  A string that can be given to name the output directory. [default: "."]


         Options: MODIFIERS
              --markDups                      Mark PCR duplicates with Picard MarkDuplicates. [default: off]

              --bamQC                         Generate bamQC report of alignments. [default: off]


         Options: FILTERING
              --minQual                       Minimum variant quality threshold. [default: 0]


         Options: ADDITIONAL
              --help                          Display this help information and exit
              --version                       Display the current pipeline version and exit
              --debug                         Run the pipeline in debug mode    


         Example: 
              nextflow run ecseq/SNPcall \
              --input /path/to/input/dir \
              --reference /path/to/genome.fa \
              --markDups --bamQC --minQual 20

    """
    ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute()
    exit 0
}

// print --version information
def printVersion() {
    println """\
         =============================================
          E C S E Q - S N P c a l l   P I P E L I N E
         =============================================
         ~ version ${workflow.manifest.version}
    """
    ["bash", "${baseDir}/bin/clean.sh", "${workflow.sessionId}"].execute()
    exit 0
}

// print pipeline initiation logging
def printLogging() {
    log.info """
         =============================================
          E C S E Q - S N P c a l l   P I P E L I N E """
    if(params.debug){ log.info "         (debug mode enabled)" }
    log.info """         ===========================================
         ~ version ${workflow.manifest.version}

         input dir    : ${workflow.profile.tokenize(',').contains('test') ? '-' : bam_path}
         reference    : ${params.reference}
         output dir   : ${params.output}
         mode         : ${params.minQual > 0 ? 'Filtered' : 'RAW'}
         QC options   : ${params.markDups ? 'markDups ' : ''}${params.bamQC ? 'bamQC' : ''}

         ===========================================
         RUN NAME: ${workflow.runName}

    """
}

// print pipeline execution summary
def printSummary() {

    log.info """
         Pipeline execution summary
         ---------------------------
         Name         : ${workflow.runName}${workflow.resume ? ' (resumed)' : ''}
         Profile      : ${workflow.profile}
         Launch dir   : ${workflow.launchDir}
         Work dir     : ${workflow.workDir} ${params.debug || !workflow.success ? '' : '(cleared)' }
         Status       : ${workflow.success ? 'success' : 'failed'}
         Error report : ${workflow.errorReport ?: '-'}
    """
}

// FUNCTION TO LOAD DATASETS IN TEST PROFILE
def check_test_data(bamPaths) {

    // Set BAMS testdata
    BAMS = Channel.from(bamPaths)
                  .ifEmpty { exit 1, "test profile bamPaths was empty - no input files supplied" }

    // Return BAMS channel
    return BAMS
}
